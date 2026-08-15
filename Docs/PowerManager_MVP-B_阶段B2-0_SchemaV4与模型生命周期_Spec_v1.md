# PowerManager MVP-B 阶段 B2-0：Schema v4 与模型生命周期 Spec v1

## 0. 文档状态

- 版本：1.0
- 日期：2026-08-15
- 状态：阻塞于 B1-1 生产参数决策
- 数据库版本：schema v3 升级到 schema v4
- 本阶段生产激活：保持关闭
- 下一阶段：B2-1 基准线自动学习与安全激活

## 1. 阶段目标

建立不可变个人模型、分参数族模式和统一生命周期基础设施，并安全接管 Stage 19 的基准线真源。
阶段完成时可以用测试配置验证状态机，但正式构建仍不能自动生成或激活生产候选。

## 2. 开工输入

B1-1 必须已经发布：

- 基准线生产算法和完整参数；
- referenceType 来源与优先级；
- 通知时间、证据年龄、候选寿命和冷却；
- 反事实与恶化门；
- 模式及变更通知 UI Spec；
- 最终 schema v4 迁移决策；
- baselineProductionLearningEnabled 是否可以进入工程预生产验证的书面结论。

缺少任一项不得在代码中猜值。

## 3. Schema v4

### 3.1 personalization_versions

字段、来源、状态和时间以技术方案 2.4 节为准。数据库至少保证：

- 任意时刻恰好一个 active；
- 全局最多一个 candidate、awaitingReview、deferred 或 scheduled；
- parentVersionId 不形成环；
- sourceLearningRunId 只引用 completed candidate 运行；
- changedParameterFamily 与实际差异一致；
- baseEnergy 和 baselineAnchorEnergy 位于 60 至 140；
- scheduled 必须有 effectiveLifeDay、scheduleSource 和通知；
- active 必须有 activatedAt；
- terminal 状态不能再次进入 scheduled；
- automatic schedule 的 noticeCreatedAt 非空。

### 3.2 app_settings

增加两个独立模式、暂停和冷却字段，默认 off / false / null。新增活动影响能力时不能读取基准线
模式作为默认值。

迁移成功后重建 settings，删除 baseEstimatedEnergy、pendingBaseEstimatedEnergy 和
baseEnergyEffectiveLifeDay。投影、结算、设置和备份统一读取 active personalization version。

### 3.3 初始模型与指纹

- initial active 表示升级时当前固定参数，不声称学习；
- baselineAnchorEnergy 等于当前明确 base；
- 计算参数不变时 effectiveModelFingerprint 沿用 fixed-mvp-a；
- 初始 modelRegimeEpoch 沿用 B1 epoch；
- schema 迁移本身不切证据窗口；
- 创建 source sentinel 和 config sentinel，不能伪造 learningRun。

## 4. Legacy pending 桥接

迁移事务中：

1. base 当前值必须存在且合法；
2. pendingBaseEstimatedEnergy 与 effectiveLifeDay 必须同时为空或同时存在；
3. 创建 initial active；
4. 若有 pending 对，创建 legacyManualPending scheduled 子版本；
5. scheduled 的 base 和 anchor 都取用户待生效值；
6. 预分配新的 epoch，但只在实际激活时成为当前 regime；
7. 两版本约束通过后才重建 settings；
8. 任一失败完整回滚。

首次新 prepare 先结算旧生活日，再按原 effectiveLifeDay 幂等激活。到期值不得丢失或重复，未来
值不得提前生效。

pendingRuleVersion 与 pendingRuleEffectiveLifeDay 必须在 v3 预检时都为空。残缺或仍有未决规则
时迁移回滚并提示使用兼容版本结清，不猜测规则迁移。

## 5. 生命周期状态机

实现纯状态转换器和 ModelActivationService，但正式门保持关闭：

- review 候选进入 awaitingReview；
- accepted 进入 scheduled；
- automatic 候选通过安全门后直接 scheduled；
- deferred 可重新打开，但每次检查寿命；
- rejected、canceled、invalidated 为终态；
- active 之后可 superseded 或通过未来恢复版本撤回；
- automatic 降到 review 时，未激活自动安排退回 awaitingReview；
- review 升到 automatic 不偷跑旧候选；
- off 只取消该参数族未激活版本；
- 手动修改同参数族使旧候选失效并建立新 anchor。

所有转换在单事务内同时写 transitionReason、时间、设置冷却和持久通知。

## 6. 安排与恢复安全

- automatic 的 effectiveLifeDay 严格晚于当前 lifeDay；
- 从当前时刻到该生活日 04:00 必须满足最短通知时间；
- 通知记录与 scheduled 原子提交；
- 激活前重验 evidenceHash、源 regime、父模型、门、模式、暂停、配置支持、证据年龄和候选寿命；
- prepare 使用条件更新只激活一次；
- 恢复出的到期或错过 automatic schedule 直接 invalidated；
- reviewAccepted、manual、legacyManualPending 保留用户明确决定并幂等处理；
- 恢复完成完整性检查前不运行协调器。

## 7. 备份 v4

导出并恢复：

- personalization versions 的全部终态和时间；
- 分参数族模式、暂停和冷却；
- learning runs；
- effective fingerprint、epoch 和 anchor；
- 持久通知状态。

导入 v1 至 v3 时通过与 onUpgrade 相同的 legacy base 桥接。旧备份含 pending rule 时，在替换当前
数据库前拒绝。恢复后验证唯一 active、全局唯一待处理、父链、source run 和 schedule。

## 8. UI

设置页提供两个独立学习模式入口。首次启用前分别说明：

- 使用哪些本机数据；
- review 与 automatic 差异；
- 自动变化的步长和累计边界；
- 最短通知与取消；
- 撤回只对未来生效；
- 关闭学习不会删除观测。

本阶段正式构建只允许 off；可用版本化预生产配置验证 review / automatic UI 和状态机。预生产
标识必须醒目且不得打包到正式 APK。

## 9. 自动化测试

### 9.1 Migration

- 无 pending、未来 pending、到期 pending；
- pending 两字段残缺；
- pending rule 空、残缺、未决；
- initial 指纹和 epoch 沿用；
- 重启不重复桥接；
- settings 重建后无第二基准线真源；
- v3 到 v4 任一步失败回滚。

### 9.2 状态机

- 每个合法转换与每个非法转换；
- 全局待处理唯一；
- review、automatic、off 全矩阵；
- 模式升降级；
- 手动冲突、暂停、冷却、过期和证据变化；
- 通知失败不安排；
- 未来日期和最短通知边界；
- 撤回到相同数值仍创建新 epoch；
- 自动变化和撤回不重置 anchor；
- manual 明确设值更新 anchor。

### 9.3 Backup 与恢复

- v1 至 v4 导入；
- v4 往返；
- 零或多个 active 拒绝；
- 过期 automatic 失效；
- 明确用户 schedule 幂等；
- 恢复中断回滚；
- pending rule 旧备份在替换前拒绝。

### 9.4 回归

投影、结算、设置和历史全部从 active 模型读取；format、analyze、全量 test、coverage、debug APK
和 git diff --check 通过。

## 10. 停止条件

- 迁移后仍存在两份可写 base 真源；
- 初始模型使 B1 证据无理由失效；
- legacy pending 丢失、提前或重复生效；
- 自动 schedule 没有持久通知；
- 模式切换能复活旧候选；
- 恢复后出现零个或多个 active；
- 正式构建能绕过门激活测试候选；
- 任一迁移失败会清库。

## 11. 退出证据

- schema v4 migration、backup、state machine 全绿；
- 模拟器覆盖升级与模式矩阵记录；
- 真机 v3 到 v4 无损升级记录；
- 正式构建生产门关闭且激活路径不可达；
- B2-1 可以在明确预生产配置下接入基准线 learner。
