# 精力值管理产品 技术方案 v3（MVP-B）

## 0. 技术基线与范围

- 版本：3.2
- 日期：2026-08-15
- 状态：已确认，作为 MVP-B 技术实施基线

继续使用 Flutter、Riverpod、Drift / SQLite 和现有分层。MVP-B 的“自动学习”是本机上的
确定性规则学习与版本管理，不为了这个目标引入网络、账号、云数据库、机器学习框架或新的
状态管理框架。

文档版本 `v3` 是 MVP-B 规格版本，不等于 Drift 数据库版本；数据库会按风险拆成 schema
v2～v5 逐步迁移。

本方案优先解决五个 P0：

1. 同一参考时刻的观测快照；
2. 活动绑定直接反馈；
3. schema v1 → v2 无损迁移与备份兼容；
4. 自动学习运行和个人模型版本的幂等、审计与重现；
5. `off / review / automatic` 三种模式下的安全生效、取消和撤回。

## 1. 分层原则

```text
features     采集、学习进度、变更记录、模式设置和用户控制
application 串行用例、学习编排、模型安排 / 激活、迁移与恢复协调
domain      比较、资格、学习器、安全门和状态转换纯函数
data        Drift schema、不可变证据、模型版本、备份和审计记录
```

- UI 不计算资格、阈值、候选值或自动应用条件。
- 资格判定、基准线学习和活动影响学习使用纯输入、纯输出。
- 所有模型写入只经过 `ModelActivationService`，不允许多个功能各自更新参数。
- 当前生活日准备继续复用 Stage 19 的统一串行事务。
- B0 不注册学习器；B1 可注册影子学习器，但对应生产激活路径必须保持不可达。
- 学习器不得直接修改活动规则表或设置表。
- schema v4 后，投影与结算只从唯一 active `personalization_versions` 读取基准线；
  `app_settings` 不再保留可写的基准线镜像。

## 2. 分阶段 Schema

### 2.1 数据库 schema v2：观测合同

schema v2 只负责正确采集证据，不包含生产模型版本。

在 `energy_observations` 增加以下 nullable 列，以兼容 v1 历史行：

| 字段 | 说明 |
|---|---|
| contractVersion | `mvp-b-observation-v1`；v1 行为空 |
| referenceType | `currentMoment / previousLifeDayEnd` |
| initialEstimateAtObservation | 参考时刻初始估计 |
| estimatedOrdinalAtObservation | 按比较版本冻结的档位 |
| baseEnergyAtObservation | 当时基准线 |
| ruleVersionAtObservation | 当时固定规则版本 |
| comparisonBandVersion | 比较映射版本 |
| personalizationVersionAtObservation | B0 / B1 使用稳定哨兵 `fixed-mvp-a`；legacy 为空 |
| effectiveModelFingerprintAtObservation | 实际有效参数指纹；B0 / B1 为 `fixed-mvp-a` |
| modelRegimeEpochAtObservation | 真实模型激活窗口；B0 / B1 使用稳定初始 epoch |
| activeActivityCountAtObservation | 参考时刻 active 活动数 |
| coverageState | `confirmed / uncertain / legacyUnknown` |
| modelRegimeKey | 稳定模型分组键 |

现有 `estimateAtObservation` 对 observation contract v1 的每日状态必须非空。数据库约束应
允许 legacy v1 行为空，但要求所有标记为新合同的行字段组合完整。

推荐通过重建 `energy_observations` 表实现新的 CHECK 约束，不依赖只添加列后由应用层兜底。
每日状态的生活日唯一索引继续保留。

### 2.2 schema v2：activity_feedback

新增 `activity_feedback`：

| 字段 | 说明 |
|---|---|
| id | 主键 |
| activityRecordId | 被评价活动，外键 RESTRICT |
| lifeDay | 反馈所属生活日 |
| subcategorySnapshot | 反馈时子类 |
| durationMinutesSnapshot | 反馈时时长 |
| theoreticalDeltaSnapshot | 固定规则理论变化 |
| appliedDeltaSnapshot | 实际应用快照 |
| impactSignSnapshot | `consumption / recovery / zero` |
| ruleVersionSnapshot | 固定规则版本快照 |
| activityUpdatedAtSnapshot | 检测反馈后编辑 |
| direction | 四档活动反馈 |
| status | `active / invalidated` |
| invalidationReason | 删除、编辑、完整性失败等原因 |
| observedAt | UTC 提交时间 |

同一活动最多一条 active 反馈。活动逻辑删除或反馈后实质编辑时，在同一事务中将反馈置为
`invalidated`，保留历史而不参与学习。

schema v2 的全部反馈在语义上都是 `userInitiated`。抽样、倍率和 activity regime 字段不提前
加入第一次高风险迁移。

### 2.3 数据库 schema v3：影子学习运行

B1-0 在实现影子学习器时新增 `learning_runs`。该版本只保存可重现的影子运行，不包含个人
模型表，也不存在激活路径：

#### `learning_runs`

| 字段 | 说明 |
|---|---|
| id | 主键 |
| parameterFamily | `baseline / activityImpact` |
| sourceModelIdentity | 基准线为 `modelRegimeKey`；活动影响为 `activityImpactRegimeKey` |
| sourcePersonalizationVersionId | 完整父模型版本；B1 的固定规则影子运行可为空 |
| status / result | 运行状态与算法结果分开保存 |
| evidenceSnapshotJson | 冻结证据 ID、排除摘要和统计 |
| evidenceHash | 规范化证据哈希 |
| evidenceHashVersion | 规范编码与摘要算法版本 |
| algorithmVersion / configVersion | 可重现版本 |
| currentValuesJson / candidateValuesJson | 当前与候选参数；纯证据运行的候选为空 |
| reasonCodesJson | 结构化原因 |
| triggeredAt / completedAt | UTC 时间 |

唯一约束覆盖
`parameterFamily + sourceModelIdentity + algorithmVersion + configVersion + evidenceHash`。

B1 纯证据运行的 `candidateValuesJson` 必须为空。发布 shadow-only 候选配置后的非空值也只是
离线结果，数据库约束和 Application 依赖图都不得把它解释成可生效模型。

### 2.4 数据库 schema v4：基准线模型版本

B1 审计通过并确认 B2 算法后新增：

#### `personalization_versions`

| 字段 | 说明 |
|---|---|
| id / parentVersionId | 不可变版本和父版本 |
| effectiveModelFingerprint | 基于有效基准线、活动倍率及其计算语义的稳定指纹 |
| modelRegimeEpoch | 每次真实激活创建的新证据窗口 ID |
| creationSource | `learningRun / manual / legacyManualPending / revert` |
| scheduleSource | `automatic / reviewAccepted / manual / legacyManualPending`；未安排时为空 |
| sourceLearningRunId | 自动学习来源；其他来源为空 |
| algorithmVersion / configVersion | 学习版本；非学习来源保存明确 sentinel |
| changedParameterFamily | `baseline / activityImpact / none`；initial 版本为 none |
| baseEnergy | 本版本基准线 |
| baselineAnchorEnergy | 累计自动变化的用户确认锚点 |
| status | `candidate / awaitingReview / deferred / scheduled / active / superseded / rejected / reverted / canceled / invalidated` |
| effectiveLifeDay | 计划生效生活日 |
| noticeCreatedAt / noticeSeenAt | 持久化 App 内通知与查看状态 |
| createdAt / activatedAt / endedAt | 生命周期时间 |
| transitionReason | 状态转换原因 |

`baseEnergy` 和 `baselineAnchorEnergy` 必须保留 `60～140` 数据库 CHECK；生产配置的累计自动
变化边界只能进一步收紧，不能放宽硬约束。

迁移创建一个代表当前固定参数的初始 active 版本，以当时基准线作为 anchor，不重算历史。若
其有效参数与 B1 的固定模型
完全一致，`effectiveModelFingerprint` 必须沿用 `fixed-mvp-a`，不能只因新增数据库版本 ID
就让 B1 合格证据失效；初始 `modelRegimeEpoch` 也沿用 B1 epoch。`app_settings` 同时增加：

```text
baselineLearningMode = off | review | automatic
activityImpactLearningMode = off | review | automatic
baselineLearningSuspended = false
activityImpactLearningSuspended = false
baselineLearningCooldownUntil = null
activityImpactLearningCooldownUntil = null
```

两个参数族模式都默认 `off`，必须分别授权。设置只控制对应参数族的用户特定学习和未激活
版本，不删除原始证据，也不静默回退已激活模型。新增参数族不能继承另一参数族的模式。
数据库必须用部分唯一索引或等价事务约束保证全局最多一个
`candidate / awaitingReview / deferred / scheduled` 版本，防止基准线和活动影响在同一生活日
同时生效。

#### 现有 pending base 的桥接

Stage 19 的 `app_settings.pendingBaseEstimatedEnergy + baseEnergyEffectiveLifeDay` 可能在升级时
非空。schema v4 `onUpgrade` 在同一迁移事务内完成：

1. 两个字段必须同时为空或同时有值；部分缺失使整个迁移回滚，原数据库保持不变。
2. 用当前 base 创建 initial active 模型。
3. 有 pending 对时，按原 `baseEnergyEffectiveLifeDay` 创建 `legacyManualPending` scheduled 版本，
   不需要迁移层判断它相对当前时钟是未来还是到期。
4. scheduled 版本以 pending 值作为激活后的 `baselineAnchorEnergy`，并预分配新 regime epoch。
5. active / scheduled 写入和约束校验成功后，重建 `app_settings` 去除 legacy base / pending 字段；
   之后 `personalization_versions` 是基准线的唯一真源。

首次新 `OperationPreparationService` 先结算旧生活日，再按原生效日幂等激活 scheduled 手动版本，
语义与 Stage 19 一致。迁移回滚或备份恢复重复启动不得创建第二个版本。

Stage 19 还保留 `pendingRuleVersion + pendingRuleEffectiveLifeDay`，但 MVP-B 不实施规则迁移。
B2 发布 schema v4 前，v3 兼容版本必须运行 prepare 并验证两字段均为空；schema v4 迁移再次
强制校验。两字段残缺或仍有未决规则时整个迁移回滚，不丢弃、不提前应用，也不伪装成个人
模型变化。

### 2.5 数据库 schema v5：活动影响版本

B3 生产算法和迁移 Spec 通过后新增 `personalization_activity_factors`：

| 字段 | 说明 |
|---|---|
| personalizationVersionId | 所属不可变个人模型版本 |
| subcategory | 活动子类 |
| impactSign | `consumption / recovery` |
| baseActivityRuleVersion | 该倍率适用的固定活动规则版本 |
| factor | 当前配置允许范围内的倍率 |
| sourceLearningRunId | 该键最后一次变化来源 |
| factorRegimeStartedLifeDay | 该倍率开始积累新反馈的生活日 |

主键为 `personalizationVersionId + subcategory + impactSign`。不存在行等价于倍率 `1.0`，但不
为了填满 24 个子类写入伪个性化结果。

schema v5 迁移只增加“隐含倍率均为 `1.0`”的表达能力时，不创建参数变化版本，也不改变当前
`effectiveModelFingerprint`。只有活动倍率真正改变时才生成新模型指纹。

同时新增 `activity_feedback_samples`，不能用一条伪反馈表示跳过或未响应：

| 字段 | 说明 |
|---|---|
| id / activityRecordId / lifeDay | 抽样及其目标活动 |
| samplingPolicyVersion | 选择该活动的策略版本 |
| selectedAt / promptedAt | 被抽中与实际展示时间 |
| disposition | `pending / responded / skipped / expired / invalidated` |
| feedbackId | responded 时关联真实反馈 |
| invalidationReason | 活动编辑、删除或资格变化 |

同一活动、同一抽样策略最多一条非 invalidated sample。`activity_feedback` 的 sampledPrompt 行
必须引用 sample；用户跳过或 sample 过期时不创建反馈方向。

schema v5 同时重建 `activity_feedback`，新增：

- `defaultTheoreticalDeltaSnapshot`、`personalImpactFactorSnapshot`、
  `personalizedTheoreticalDeltaSnapshot`；
- `personalizationVersionSnapshot` 和 `activityImpactRegimeKeySnapshot`；
- `collectionSource`、`samplingPolicyVersion`、`sampledAt` 和 nullable `sampleId`。

v2 旧行在迁移时把原 `theoreticalDeltaSnapshot` 复制为 default / personalized 理论值，倍率记为
`1.0`，来源明确回填为 `userInitiated`，sample 为空。它们可继续做研究，但永远不会因此获得
生产倍率学习资格。

活动记录新增 `personalizationVersionId`、`activityImpactRegimeKey`、
`defaultTheoreticalDeltaSnapshot`、`personalImpactFactorSnapshot` 和
`personalizedTheoreticalDeltaSnapshot`，只对新活动写入；旧活动继续按其已冻结的
theoretical / applied delta 解释。Schema v5 不原地修改固定规则表。

## 3. 迁移策略

### 3.1 B0 两步发布

1. **B0-1 迁移准备版（仍为 schema v1）**
   - 启动后生成并验证最新本机 JSON 备份；
   - 明确显示备份时间和完整性；
   - 不修改数据库结构。
2. **B0-2 schema v2 版**
   - 只有在备份准备版真机通过后发布；
   - 使用 Drift `onUpgrade` 在单个数据库事务内迁移；
   - 完成后执行外键检查、表约束检查和导出再解析。

schema v3、v4 和 v5 各自使用独立迁移、fixture 和回滚测试，不与前一阶段业务代码捆成
一次不可回退的大升级。

### 3.2 历史数据处理

- v1 每日状态保留原枚举、生活日和提交时间；
- 新字段使用 `legacyUnknown` 或空值；
- v1 每日状态不得反推当时估计，不进入 B1；
- v1 相对校正继续保留已有估计快照，只用于描述性复盘；
- v1 活动、摘要、规则版本和应用结果不重算；
- 迁移不得创建伪造反馈或伪造学习证据；
- schema v4 的初始个人模型只描述升级后的当前值，不声称由历史学习得到。
- schema v4 初始模型参数未变时沿用 B1 有效参数指纹，已积累证据不因迁移被清零。
- 每次真实激活（包括撤回到旧数值）创建新 model regime epoch，旧窗口不得复用。
- 现有 pending base 与 app_settings 重建原子提交，任一步失败都保留完整旧数据库。

### 3.3 失败处理

- 迁移失败必须回滚整个 SQLite 事务；
- 不得在失败后清库、自动恢复默认数据或覆盖本机备份；
- App 显示可恢复错误，允许导出诊断信息但不展示私人活动正文；
- 只有用户主动确认后才允许从已验证备份恢复。

## 4. 备份版本

解码器必须向后兼容：

- schemaVersion 1：新增字段映射为 legacy，不生成学习资格；
- schemaVersion 2：完整恢复新观测和活动反馈；
- schemaVersion 3：额外恢复影子学习运行；
- schemaVersion 4：额外恢复个人模型、模式与暂停状态；
- schemaVersion 5：额外恢复活动影响倍率、活动所用模型快照和反馈抽样记录。

v4 / v5 App 导入 v1～v3 备份时，旧 `baseEstimatedEnergy`、`pendingBaseEstimatedEnergy` 和
`baseEnergyEffectiveLifeDay` 必须经过与 schema v4 相同的原子桥接，不能直接写入已废弃的
设置字段。

旧备份若包含未决 `pendingRuleVersion`，必须在替换当前数据库前拒绝，并给出“先在兼容版本
结清规则切换并重新导出”的可恢复说明；MVP-B 不猜测如何迁移该规则。

导出必须包含 invalidated、canceled、reverted 等审计记录。恢复顺序固定为：验证文件 → 创建
安全快照 → 事务替换 → 完整性检查 → 重建内存状态。任一步失败恢复原数据库。

恢复后不得立即运行学习器。先验证唯一 active 模型、scheduled 版本、证据引用和当前生活日
一致，再由串行协调器执行一次幂等准备。

若恢复出的自动 scheduled 版本已经到达或错过原生效生活日，恢复事务必须使其失效；禁止
首次 prepare 静默补应用。`reviewAccepted / manual / legacyManualPending` 按明确用户决定和原
生效日幂等处理。新的自动候选必须基于恢复后状态重新学习并满足全部安全门。

## 5. Domain 与 Application 服务

### 5.1 ObservationComparisonService（纯函数）

- 根据配置版本计算 `estimatedOrdinal`；
- 计算 `alignmentDelta` 和方向；
- 验证边界值和 `initialEstimate > 0` 不变量。

### 5.2 SaveDailyObservationV2

串行事务：prepare → 校验目标生活日 → 读取当前投影 / 不可变摘要和模型 → 构造完整快照 →
insert / update → 返回揭示结果。UI 不得先读取投影、后单独写观测。

### 5.3 LearningEligibilityService（纯函数）

输出 `eligible`、稳定 reason codes 和 `modelRegimeKey`。Data Health、影子学习和生产学习必须
复用同一实现。

### 5.4 ActivityFeedbackUseCases

- 保存时冻结活动和模型快照；
- 只允许当前未结算生活日；
- 编辑、删除和恢复活动时同步维护反馈资格；
- 保存失败不改变活动；
- B0 / B1 不触发活动参数更新。

B3 增加 `ActivityFeedbackSampler`：只从当前配置允许、尚未反馈且不会造成截断偏差的候选集中，
按版本化策略稳定抽样；选择过程不得读取未来反馈结果。提示、跳过和未响应都受每日上限、冷却
和活动影响学习模式控制。

### 5.5 BaselineLearner / ActivityImpactLearner（纯函数）

- 接受规范化证据、源模型和版本化配置；
- 只返回学习结果和候选参数，不访问数据库；
- 相同输入必须得到字节级稳定的结构化结果；
- 各自只能修改一个参数族。

### 5.6 AutomaticLearningCoordinator

- 在证据所属生活日结算并变成不可变状态、生活日准备和安全恢复完成后被请求运行；
- 使用串行 tail 合并重复请求；
- retryable failure 复用同一 run ID 恢复，terminal failure 等输入版本变化；
- 证据哈希未变化时零写入；
- B1 只持久化影子运行；B2 / B3 才能请求候选版本；
- 先检查构建门、对应参数族模式、暂停、冷却和是否已有未处理版本；
- 已有全局待审核或待生效版本时不生成另一个参数族候选；
- 两个参数族同时就绪时按配置优先级一次只运行一个。

### 5.7 ModelActivationService

- `review` 接受或 `automatic` 安全门通过后安排未来生活日；
- 自动模式的 `effectiveLifeDay` 必须严格晚于当前生活日并满足配置的最短通知时间；
- 安排、取消、激活和撤回均为显式事务；学习暂停保存在参数族设置中，不改变 active 模型状态；
- 自动安排与 App 内通知记录原子提交；系统级本地通知只做增强，不作为唯一审计记录；
- prepare 中以条件状态更新确保一个版本只激活一次；
- 激活前重新校验证据引用、内容哈希、源 regime、父模型、构建门、模式和配置支持状态；
  任一变化都使候选失效；
- 接受、重新打开 deferred 和激活前都检查证据年龄与候选有效期；
- 拒绝、取消和撤回原子写入参数族冷却状态，避免新 evidence hash 立即重复提示；
- 激活时把旧 active 版本置为 superseded，并让当日快照引用新版本；
- 手动基准线修改也创建版本，并使旧候选失效；
- 只有明确手动设值才更新 baseline anchor；自动变化和撤回不得重置累计边界；
- 撤回创建未来恢复版本，不重写历史；
- 参数族内 `review → automatic` 不自动安排旧候选；`automatic → review` 把未生效安排退回待审核；
- 参数族切换到 `off` 时原子取消该参数族所有未激活版本。

## 6. 并发与一致性

- 所有观测、反馈、学习运行和模型状态写入使用串行 tail + Drift transaction。
- 业务写入前调用统一 `OperationPreparationService`。
- 任意时刻恰好一个 active 个人模型；全局最多一个未处理个人模型版本。
- Data Health 和学习器使用同一资格实现，禁止复制条件。
- evidence hash 与数据库唯一约束双重防重。
- 规范编码器独立单测并使用 golden vectors；不得把活动标题或备注写入哈希输入。
- 后台任务只发出“请求运行”，不持有跨生命周期数据库事务。
- 导出在一致事务中读取全部模型和审计表。

## 7. 测试要求

### 7.1 迁移与备份

- 合成 schema v1 数据库升级到 v2，原七表逐字段一致；
- legacy observation 不获得资格；
- v1 → v2、v2 → v3、v3 → v4、v4 → v5 分步 fixture；
- 各版本 JSON 向后导入和当前版本往返；
- 迁移和恢复中途失败完整回滚；
- WAL、外键、索引、唯一 active 约束和保护触发器有效。

### 7.2 Domain

- 五档比较所有等号边界和五种 actual ordinal；
- 每个排除原因及 model regime 隔离；
- currentMoment 与 previousLifeDayEnd 分组，不互相补样本；
- v4 初始模型同参数不切 regime，真正参数变化必须切 regime；
- 撤回到相同参数值仍切换 epoch，避免旧证据立即重复触发；
- legacy pending base 的未来、到期、字段残缺和重复启动桥接；
- pending rule 为空的升级预检，以及残缺 / 未决状态安全拒绝；
- v5 仅增加默认倍率存储能力时也不切 regime；
- 双窗口排序和门槛；
- 基准线与活动影响学习的确定性；
- evidence hash golden vectors、字段顺序扰动和跨备份恢复稳定性；
- 子类相同但 `consumption / recovery` 证据绝不串用；
- 活动倍率变化后旧 regime 证据不被重复使用，单纯基准线变化不重置活动 regime；
- 固定规则版本不匹配时旧倍率不应用、不学习；
- 零值、截断和 `directionMismatch` 不进入倍率学习；
- userInitiated 与不受支持采样策略的反馈不进入生产倍率学习；
- 每个安全门、冷却、累计边界和恶化保护。
- 连续自动变化不能通过创建新版本绕过 baseline anchor 累计边界；
- 证据过旧、候选过期和模式切换均不会复活候选；

### 7.3 Application

- 同日 / 昨日观测快照原子写入；
- 跨 04:00 写入拒绝错误目标；
- 活动编辑 / 删除使反馈失效；
- 未结算的观测与反馈不进入学习，结算后才触发协调器；
- B0 无学习写路径，B1 无模型激活路径；
- 相同证据不重复运行、生成或激活；
- retryable / terminal failure 的重试边界和崩溃恢复；
- `off / review / automatic` 的完整模式矩阵；
- 测试 / 预生产配置通过真实 gate 路径启用，正式构建不包含该配置；
- 自动安排前取消、激活后撤回、手动修改冲突和暂停；
- 通知持久化失败时不安排，关闭系统通知权限仍可在 App 内查看和取消；
- 两个参数族同时就绪仍只变化一个；
- 恢复备份后 scheduled 版本不会重复应用。
- 恢复出的过期 automatic scheduled 不会补应用，明确用户安排仍按原语义幂等处理；

### 7.4 真机

- 使用真实 schema v1 数据先备份后升级；
- 升级前后聚合数量和历史页面一致；
- 连续两日完成 current / yesterday 两种状态配对；
- 后台、重启和跨 04:00 后快照不漂移；
- `off` 不变化，`review` 未接受不变化；
- `automatic` 只在生产门开启时安排，并显示通知、取消和撤回入口；
- 自动变化后的当前日、已结算历史和备份恢复结果一致。

## 8. 隐私与用户控制

- 所有学习默认仅在本机执行；
- 不上传活动、状态、反馈、证据或模型版本；
- 导出提示其包含敏感行为与主观状态数据；
- 每个参数族首次启用前分别解释三种模式、数据用途和变化边界；
- 用户可以关闭学习而不影响基础记录；
- 用户可以取消未生效版本、撤回已生效版本和重置未来个人模型；
- 清除或重置不篡改已结算历史和必要的审计记录。
