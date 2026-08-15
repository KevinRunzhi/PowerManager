# PowerManager MVP-B 阶段 B3-0：活动影响生产参数门 Spec v1

## 0. 文档状态

- 版本：1.0
- 日期：2026-08-15
- 状态：待 B0-3 反馈自然积累且 B2 安全基础稳定后执行
- 类型：真实数据可行性实验与生产参数决策门
- 数据库版本：schema v4
- 下一阶段：通过则进入 B3-1；证据不足则继续积累

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

## 8. 决策分支

- 通过：至少一个键和抽样策略可安全定义，进入 B3-1；
- 继续积累：抽样样本不足，保持当前 factor 1.0；
- 调整抽样：负担、覆盖或选择机制不合格，发布新策略版本重新实验；
- 键级否决：特定键方向不符或异质，保持 1.0 并进入固定规则研究；
- 停止倍率假设：单一倍率不能提供参考价值，产品状态 rejected，但不得改用无 Spec 的复杂模型。

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

只有生产参数完整且抽样负担可接受时才进入 B3-1。真实样本不足时保持 inconclusive 和 factor
1.0 是正确结果，不降低资格门。
