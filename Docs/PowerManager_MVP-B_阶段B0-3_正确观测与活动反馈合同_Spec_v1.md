# PowerManager MVP-B 阶段 B0-3：正确观测与活动反馈合同 Spec v1

## 0. 文档状态

- 版本：1.3
- 日期：2026-08-15
- 状态：已实现并通过自动化与 Pixel_7 模拟器工程验收
- 数据库版本：保持 schema v2
- 下一阶段：B1-0 自动影子学习器

## 1. 阶段目标

开始自然积累真正可比较、可冻结、可解释的新证据。阶段完成后，App 能正确保存同一参考时刻
的估计—实际配对和活动绑定直接反馈，但任何反馈或观测都不会改变模型参数。

## 2. 核心用户流程

### 2.1 同日 currentMoment

1. 用户打开“现在的整体状态”；
2. Sheet 不提前展示系统估计；
3. 用户选择五档实际状态；
4. 用户确认“截至现在，主要活动基本记录完整 / 不确定”；
5. 单个串行事务 prepare 并冻结当前投影、初始估计、比较档位、base、规则和模型哨兵；
6. 写入成功后才揭示“低于 / 相符 / 高于”；
7. 同一生活日再次填写时更新同一业务记录并整组替换快照。

调用方必须显式传入 `referenceType = currentMoment`。事务内若 targetLifeDay 已不再等于当前生活日，
即使它刚好变成“昨日”，也必须以稳定的 staleSheet 错误拒绝，不能静默改写语义。

### 2.2 previousLifeDayEnd

1. 只在昨日已结算且没有 dailyAbsolute 时提供；
2. 文案明确询问“昨天结束时”；
3. 系统值读取昨日不可变 summary.finalEstimatedEnergy 和 initial estimate；
4. capturedAt 保存当前提交时间，lifeDay 保存昨日；
5. 保存后只读，不允许普通编辑；
6. 没有 summary 或完整模型上下文时不造伪配对。

调用方必须显式传入 `referenceType = previousLifeDayEnd`。targetLifeDay 必须精确等于事务内当前
生活日的 previous；同一生活日已有任意 dailyAbsolute 时只读拒绝。coverage 问题使用“截至昨天
结束时”的文案，`observedAt` 只表示本次提交时间，不冒充参考时刻。

### 2.3 活动绑定主动反馈

1. 从当前未结算生活日的一条 active 活动进入；
2. 可选 strongerImpact、aboutRight、weakerImpact、directionMismatch；
3. 保存活动 ID、子类、时长、理论值、实际值、影响方向、规则版本和活动 updatedAt 快照；
4. 同一活动重复评价更新同一 active 反馈或显式替换，不能产生两个 active；
5. 编辑关键字段或删除活动时，同事务 invalidated；
6. 恢复活动不恢复旧反馈资格；
7. 保存反馈不触发参数变化。

反馈 Sheet 必须携带打开时的 activityUpdatedAt。保存事务重新读取活动；若 updatedAt 已变化则以
staleActivity 拒绝，要求用户重新查看。重复评价更新同一 active feedback ID 并替换完整快照。

## 3. Domain 合同

### 3.1 ObservationComparisonService

- actualState 映射到 0 至 4 的有序类别；
- estimatedOrdinal 严格使用规则配置的 0、25%、50%、80% 边界；
- initialEstimate 小于等于 0 返回完整性失败；
- 只返回 alignmentDelta 和方向，不返回建议点数；
- 所有整数运算避免浮点边界漂移。

结果方向精确为 `lower / aligned / higher`。非法 initialEstimate 返回
`invalidInitialEstimate`，保存用例不得捕获后降级为近似档位。

### 3.2 LearningEligibilityService

输出：

- eligible；
- 稳定、可组合的 reasonCodes；
- modelRegimeKey；
- referenceType；
- settled 状态。

至少覆盖 legacyContract、missingEstimateSnapshot、coverageUncertain、
missingMorningCheckIn、invalidInitialEstimate、unsettledLifeDay、
modelRegimeMismatch 和 integrityFailure。Data Health、B1 影子和后续生产学习必须注入同一实现。

reasonCodes 去重并严格按上述顺序输出，不能依赖 Set / Map 遍历顺序。合同字段缺失记
missingEstimateSnapshot；ordinal 与 estimate 重算不一致、dailyAbsolute 形状损坏或不支持的
comparison band 记 integrityFailure；已保存 key 与快照重算不一致，或与调用方要求的当前 regime
不同，记 modelRegimeMismatch。只有 reasonCodes 为空时 eligible 才为 true。

`activeActivityCountAtObservation = 0` 本身不排除：coverage confirmed 明确表示截至参考时刻没有
遗漏的主要活动；uncertain 仍以 coverageUncertain 排除。当前日没有 summary 时必须返回
unsettledLifeDay，结算后使用同一 observation 重新评估即可变为 eligible。

### 3.3 模型哨兵

B0 与 B1 在个人模型表出现前统一使用：

- personalizationVersionAtObservation = fixed-mvp-a；
- effectiveModelFingerprintAtObservation = fixed-mvp-a；
- modelRegimeEpochAtObservation = fixed-mvp-a-initial；
- modelRegimeKey 同时包含 referenceType、base、rule、comparison band、fingerprint 和 epoch。

modelRegimeKey 使用规则配置的 `model-regime-sha256-v1`：对算法文档规定的六字段 canonical JSON
做 SHA-256，格式为 `model-regime-sha256-v1:<lowercase hex>`。不得包含 observation ID、lifeDay、
capturedAt 或 personalization version ID。

不得因为记录 ID 或 capturedAt 不同切换 regime。

## 4. 事务与并发

SaveDailyObservationV2 的顺序固定为：

1. 进入现有串行 tail；
2. OperationPreparationService.prepare；
3. 重新计算目标 lifeDay，拒绝跨 04:00 的旧 Sheet；
4. currentMoment 读取事务内当前投影；yesterday 读取不可变 summary；
5. 读取活动计数、早间确认、base 和 active rule；
6. 构造完整快照并验证；
7. insert 或 update；
8. 提交后返回揭示 DTO。

Wellbeing、Activity 和 ActivityFeedback 用例必须注入同一个进程内 BusinessWriteCoordinator，
不能各自维护互不相干的 tail。数据库事务仍是最终原子边界；共享队列负责按调用顺序进入 prepare
与事务，并在单次失败后继续处理后续操作。

活动反馈保存、活动编辑、逻辑删除与恢复也进入该边界。以下任一快照字段变化都必须在同一事务
把 active feedback 置为 invalidated：lifeDay、subcategory、duration、theoreticalDelta、
appliedDelta、ruleVersion 或 activityUpdatedAt。逻辑删除使用 activityDeleted；编辑、完成时间变化、
晨间重放或其他活动导致的 appliedDelta 重算使用 activityEdited。字段完全相同的编辑是 no-op，
保留 updatedAt 和 active feedback；恢复活动不得恢复旧反馈。任何失败不得留下半条 observation、
孤儿 feedback 或 active feedback 指向已变化活动。

所有持久化记录 ID 不得把墙钟时间当作唯一性来源；冻结时钟、时钟回拨、同刻并发和进程重启均
不能产生重复 ID。工程时钟覆盖只允许非 release 构建显式启用，非法时间立即失败，release 必须
忽略覆盖值。

## 5. UI 与可访问性

- 五档行为锚点可展开查看，不把系统档位当作用户评分；
- coverage 问题可理解且“不确定”仍允许保存；
- 保存中阻止重复提交，失败保留选择并允许重试；
- 揭示不使用“真实能力、体力下降、系统更懂你”等判断；
- 活动反馈可跳过，不主动弹窗；
- directionMismatch 明确表示规则方向可能不适合，不把它解释为强弱；
- 200% 字号、小屏和屏幕阅读器可完成流程。

## 6. Data Health

只读展示：

- 按 referenceType 分开的新合同观测数；
- 当前 regime 已结算 eligible 数和日期跨度；
- unsettled 进度；
- legacy、coverage uncertain 和其他主要排除原因；
- 主动活动反馈数、active / invalidated 数；
- 明确文案“达到最低数量只表示可以进入影子审计”。

页面不得展示活动标题、备注、记录 ID 或证据哈希。

Data Health 的排除计数必须直接聚合 LearningEligibilityService 的 reasonCodes；不得复制另一套
资格判断。新合同数只统计 dailyAbsolute，currentMoment 与 previousLifeDayEnd 分开；日期跨度展示
最早 / 最晚 eligible lifeDay，没有证据时显示 0 和“暂无”。

## 7. 自动化测试

### 7.1 Domain

- 五种 actual ordinal；
- estimatedOrdinal 的负数、0、25%、50%、80% 和相邻整数边界；
- initialEstimate 非法；
- 每个 eligibility reason code；
- 多 reason 顺序稳定；
- currentMoment 与 previousLifeDayEnd regime 不同；
- 同参数同来源得到稳定 modelRegimeKey。

### 7.2 Application 与 Data

- 同日完整原子 insert 和 update；
- 写入任一字段失败整条回滚；
- 保存期间跨 04:00 被拒绝；
- yesterday 使用 summary，不使用当前投影；
- yesterday capturedAt 与 lifeDay 分离；
- 未结算 observation 不 eligible，结算后变为 eligible；
- 活动反馈保存和替换；
- 编辑子类、时长、完成时间与删除导致失效；
- 非实质展示字段变化不错误失效；
- 恢复活动不复活反馈；
- feedback 保存失败不修改 activity；
- v2 backup 往返保留全部快照。

### 7.3 Widget

- 选择前不揭示估计；
- coverage 两个选项和错误恢复；
- 成功后揭示来自已保存 DTO；
- yesterday 文案和只读状态；
- 活动反馈四个方向、取消和重试；
- 200% 字号和小屏无溢出。

### 7.4 回归

执行 format、analyze、全量 test、coverage、模拟器可运行构建和 git diff --check；真机流程延期到
MVP-B 总体验收。

## 8. 模拟器工程验收与最终真实使用

阶段内用冻结时钟和明确 fixture 在模拟器跨至少两个模拟生活日完成以下流程，证明合同和用户
路径正确。MVP-B 最终安装后再按自然生活日复验；后者不是进入 B1-0 的工程阻塞项。

至少连续两个生活日自然完成：

- 一次 currentMoment；
- 一次 previousLifeDayEnd；
- coverage confirmed 与 uncertain 各至少一次；
- 一条活动主动反馈；
- 一条反馈后编辑或删除的失效验证。

验收时检查后台恢复、App 重启和跨 04:00 后快照不漂移。不得把模拟器 fixture 写成真实产品
证据；最终手机复验不得修改系统数据库或用 ADB 补造记录。

## 9. 停止条件

- 用户选择前已经看到系统答案并可能被锚定；
- 估计与实际不是同一参考时刻；
- currentMoment 和 yesterday 被混合统计；
- 未结算数据被学习资格计数；
- legacy 数据获得资格；
- 活动反馈编辑或删除后仍 active；
- 保存反馈导致任何 base、pending 或规则变化；
- 额外问题明显阻断日常记录。

## 10. 退出证据

- schema 保持 v2；
- 新合同与反馈自动化测试全绿；
- 模拟器主流程记录；
- 模拟器跨生活日工程记录；
- 连续真实使用与负担复验登记到 MVP-B 总体验收，当前产品状态为 inconclusive；
- Data Health 口径与 LearningEligibilityService 一致；
- 没有 learning_runs 或模型激活路径；
- B1-0 可以只读取结算后的不可变证据开始实现。
