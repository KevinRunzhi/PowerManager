# PowerManager MVP-B 阶段 B3-0：活动影响生产参数门 Spec v1

## 0. 文档状态

- 版本：1.2
- 日期：2026-08-15
- 状态：B2 稳定后先完成工程参数合同；真实参数实验延期到最终安装后
- 类型：真实数据可行性实验与生产参数决策门
- 数据库版本：schema v4
- 下一阶段：工程参数合同通过可进入 B3-1；生产门仍由真实实验决定

### 0.2 B3-0 工程合同冻结（预生产）

本阶段只冻结可复现、可审计的参数合同，不改变 schema v4，不写入个人 factor，也不打开生产学习：

- `activityImpactSamplingAlgorithmVersion = activity-impact-sampler-v1`；
- `activityFeedbackSamplingPolicyVersion = activity-impact-sampling-preprod-v1`；
- 预生产水印为 `PREPRODUCTION_ONLY_ACTIVITY_IMPACT_V1`，`activityImpactProductionLearningEnabled = false`，
  `activityImpactAutoApplyEnabled = false`；
- 每生活日最多 1 条 selected sample；跳过冷却 1 个生活日，未响应冷却 3 个生活日；
- 只抽当前生活日 active、非零理论值、无恢复截断、规则版本为
  `energy-rules-v2-mvp-a` 的活动；同一活动与同一 policy 的非 invalidated sample 排除；
- 抽样只使用 policy 版本、生活日和稳定活动 ID 的 SHA-256 排序，不读取预测误差、详情打开、投诉或任何
  feedback direction；off 模式恒为 `noPrompt`；
- 研究审计允许纳入 `userInitiated` 但绝不把它转换为生产资格；零理论值、恢复截断、规则混用、
  invalidated、directionMismatch 和时长异质只进入审计/否决；
- 预生产倍率范围 `[0.50, 1.50]`、步长 `0.05`，不跨 0；同一键 directionMismatch 至少 2 条且占合格证据
  `>= 25%` 时 veto；合格证据的时长最大跨度超过 60 分钟时返回 unstable；
- 最小工程观察门为每键 8 条合格 sampledPrompt、覆盖至少 4 个生活日。任一完整配置字段缺失或
  watermark 不匹配，统一返回 `configurationBlocked`。

这些值是工程 fixture 的合同，不是产品结论；真实安装前不得将其解释为已验证的用户参数。

### 0.1 两轨执行说明

- **工程轨**：用明确标记的 fixture 与 Pixel_7 模拟器证明 sampler、按键隔离、倍率边界、
  directionMismatch veto、noChange 和失败路径，发布不可进入最终构建的预生产参数；
- **产品轨**：最终安装后自然积累 userInitiated 与 sampledPrompt 数据，再决定真实抽样负担和
  生产参数；
- 工程轨通过可以进入 B3-1，但 activityImpactProductionLearningEnabled 与
  activityImpactAutoApplyEnabled 必须保持 false，产品状态为 `inconclusive`。

## 1. 实验目标

确定哪些“活动子类 × 影响方向”适合用一个保持符号的个人倍率学习，并发布无选择偏差、低负担
的抽样策略及完整生产参数。用户主动反馈只用于研究，不能直接通过本阶段升级为生产证据。

## 2. 前置条件

- B0-3 已稳定采集 userInitiated feedback；
- 活动编辑、删除和恢复后的失效语义可靠；
- B2 的模型版本、未来生效、通知、取消和撤回基础设施通过；
- 固定活动规则仍为 energy-rules-v2-mvp-a；
- 当前活动反馈生产门与自动应用门均为 false；
- 原始反馈只在本机分析。

## 3. 第一次可行性审计

按 ActivityImpactKey = subcategory + impactSign 分组，分别统计：

- userInitiated feedback 数和跨日数；
- stronger、aboutRight、weaker、directionMismatch；
- 编辑或删除后的 invalidated；
- 默认理论值为 0；
- 恢复上限截断；
- 各固定时长档位；
- 规则版本；
- 同一键内方向是否明显异质。

该统计只回答键的可研究性与采样候选范围。由于 userInitiated 天然偏向异常体验，不得由它
计算生产倍率或生产样本阈值。

## 4. 抽样策略实验

### 4.1 必须满足

- 选择发生在用户反馈之前；
- 不读取预测误差、用户是否打开详情、历史抱怨或之后的反馈结果；
- 只从当前生活日符合基础资格的 active 活动中抽样；
- 低频、有每日上限、可跳过；
- 跳过后同日不反复追问；
- selected、prompted、responded、skipped、expired、invalidated 分开记录；
- 跳过不创建伪方向；
- samplingPolicyVersion 固定选择算法；
- 用户关闭 activityImpact 学习时不展示新抽样提示。

### 4.2 需要比较

用一个或多个明确版本的预生产抽样策略评估：

- 每生活日提示次数；
- 展示到完成、跳过、过期比例；
- 是否干扰活动记录；
- 被选活动是否覆盖不同日期、子类、方向和时长；
- 是否因资格过滤过严只剩特殊活动；
- 用户是否理解反馈评价的是该条活动影响。

策略变更必须切换版本，不在同一版本内偷偷改概率或选择规则。

### 4.3 可复现选择合同

工程实现的 `ActivityImpactSampler` 必须是纯函数：输入为模式、当前生活日、当前合格活动和已有
sample 状态，输出为一个确定的 activity ID 或 `noPrompt` reason。daily cap 统计当前日所有非
invalidated sample；invalidated 不占 cap，但同一 activity/policy 可再次 selected。跨重启重复调用必须
得到同一 ID，直到 sample 状态改变；抽样器的输入类型不得携带 feedback direction、预测误差或投诉字段。

## 5. 倍率模型可行性

对受支持 sampledPrompt 数据逐键回答：

- 最小样本数和最小覆盖日；
- stronger、aboutRight、weaker 如何聚合；
- 单次 factor 步长；
- factor 最小和最大范围；
- 取整顺序；
- 时长档位差异多大时返回 unstable；
- directionMismatch 达到什么比例直接否决；
- 零理论值和恢复截断如何排除；
- 证据最大年龄和候选寿命；
- 激活、拒绝、取消、撤回后的冷却；
- 后续恶化和暂停条件；
- 一个活动版本中能否同时修改多个互不冲突键；
- review 和 automatic 是否需要不同门；
- 最小有用改善、不恶化边界、最大提示负担和最大撤回、暂停比例。

倍率始终大于 0，不能跨过 0 翻转固定规则方向。

## 6. Factor regime 决策

每个键使用：

    ActivityImpactKey
    + ruleVersion
    + factor
    + factorRegimeStartedLifeDay

只使用当前 factor regime 开始生活日及之后的 sampled feedback。活动倍率真实改变时开启新 regime；
仅基准线改变且倍率相同，不得重置 factor regime。恢复到旧 factor 数值仍使用新开始日，防止
旧证据再次推动相同变化。

## 7. 产出配置

通过时发布：

- activityFeedbackSamplingPolicyVersion；
- 每生活日提示上限；
- 跳过与未响应冷却；
- 可抽样资格和稳定选择算法；
- 支持的 collectionSource；
- 样本数、覆盖日、方向一致性；
- 时长异质性门；
- factor 范围、步长和取整；
- directionMismatch 否决；
- 证据年龄、候选寿命、通知时间和冷却；
- 反事实、不恶化、恶化暂停；
- 多键同批规则；
- 参数族优先级；
- 工程预生产门状态。

任一参数缺失时 activityImpactProductionLearningEnabled 保持 false。

工程轨可以冻结完整的预生产参数以实现和验证通用 learner，但必须带水印、与生产配置使用不同
版本，并在最终交付构建中不可达。

## 8. 决策分支

- 通过：至少一个键和抽样策略可安全定义，进入 B3-1；
- 继续积累：抽样样本不足，保持当前 factor 1.0；
- 调整抽样：负担、覆盖或选择机制不合格，发布新策略版本重新实验；
- 键级否决：特定键方向不符或异质，保持 1.0 并进入固定规则研究；
- 停止倍率假设：单一倍率不能提供参考价值，产品状态 rejected，但不得改用无 Spec 的复杂模型。
- 工程先行：真实样本尚未形成但预生产合同完整，产品状态 inconclusive、生产门关闭，可进入
  B3-1 实现通用工程生命周期。

## 9. 验收产物

- userInitiated 可行性聚合；
- 抽样策略 Spec 和版本；
- 提示负担报告；
- sampledPrompt 数据资格报告；
- 按键、方向和时长的匿名聚合；
- factor shadow-only 反事实和极端输入报告；
- 完整生产配置或继续观察记录；
- schema v5 迁移最终 Spec；
- 追踪矩阵更新；
- 产品状态。

工程合同代码落点为 `domain/learning/activity_impact_contract.dart`，其输出必须包含：

- `ActivityImpactKey` 与按键可行性审计（userInitiated 研究统计、invalidated、零值、截断、规则版本、
  时长和方向分布）；
- `ActivityImpactSamplingPolicyV1`、`ActivityImpactSampler` 和明确的 `noPrompt` reasons；
- factor 范围/步长/rounding 边界与 directionMismatch、时长异质安全门；
- 纯领域测试证明 off、daily cap、冷却、重启稳定、不同 policy 独立、反馈结果不可影响选择；
- 预生产配置始终不可激活，供 B3-1 learner 和 schema v5 使用。

## 10. 停止条件

- 用用户主动反馈训练生产 factor；
- 抽样依赖结果或只挑异常活动；
- 跳过被编码成 aboutRight；
- consumption 与 recovery 合并；
- 跨规则版本使用倍率；
- 时长明显异质仍强行平均；
- 未定义 directionMismatch 否决；
- 为推进 B3 补造真实反馈；
- 提示负担超标仍提高频率。

## 11. 退出

工程轨只有预生产参数合同完整、抽样选择无结果偏差且全部模拟器保护通过时才进入 B3-1。真实
产品轨仍要求生产参数完整且抽样负担可接受；真实样本不足时保持 inconclusive、生产门关闭和
factor 1.0 是正确结果，不降低资格门。
