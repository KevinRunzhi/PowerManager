# PowerManager MVP-B 阶段 B3-1：Schema v5 与活动影响学习器 Spec v1

## 0. 文档状态

- 版本：1.0
- 日期：2026-08-15
- 状态：阻塞于 B3-0 完整生产配置
- 数据库版本：schema v4 升级到 schema v5
- 下一阶段：B3-2 活动影响安全激活与监测

## 1. 阶段目标

实现按子类与影响方向隔离、使用无结果选择偏差抽样反馈、版本化且可重现的活动影响 learner。
本阶段完成采样、快照、资格、候选和 schema 能力；正式自动应用仍等待 B3-2 生命周期验收。

## 2. Schema v5

### 2.1 personalization_activity_factors

- 主键为 personalizationVersionId、subcategory、impactSign；
- factor 大于 0 且在发布配置范围内；
- baseActivityRuleVersion 必须受支持；
- sourceLearningRunId 可追溯；
- factorRegimeStartedLifeDay 非空；
- 不存在行表示 1.0，不批量写 24 子类伪个性化。

迁移只增加隐含 1.0 表达能力时，不创建新个人模型、不改变 fingerprint、不切 epoch。

### 2.2 activity_feedback_samples

- selected、prompted、responded、skipped、expired、invalidated 使用合法状态转换；
- responded 必须引用唯一 feedback；
- skipped、expired 不允许 feedbackId；
- 同一活动与策略最多一个非 invalidated sample；
- 活动实质编辑或删除时 sample 与 feedback 同事务失效。

### 2.3 activity_feedback 重建

增加 default、factor、personalized theoretical、personalization version、factor regime、
collectionSource、sampling policy、sampledAt 和 sampleId。

v2 旧行：

- default 与 personalized theoretical 复制旧理论值；
- factor 为 1.0；
- collectionSource 为 userInitiated；
- sampleId 为空；
- 永远不因此获得生产学习资格。

### 2.4 activity_records 快照

新记录冻结实际使用的 personalizationVersionId、factor regime、default theoretical、factor、
personalized theoretical 和 applied delta。旧活动不回算。

## 3. ActivityFeedbackSampler

输入只包含当前配置、模式、生活日内合格活动和已有 sample 状态。输出为确定性选择或 noPrompt。

必须：

- 只在 activityImpact 模式为 review 或 automatic 时运行；
- 遵守每日上限和跳过冷却；
- 不读取反馈结果；
- 不只选误差大、被主动查看或曾投诉活动；
- 固定随机或哈希选择必须由 policy version 和稳定种子重现；
- App 重启不重新抽一条；
- prompt 展示与状态更新幂等；
- 用户跳过后不创建 feedback。

## 4. 活动计算

对匹配 ruleVersion 的新活动：

    固定规则默认理论值
    × 当前正 factor
    → 配置规定的确定取整
    → 个性化理论值
    → 既有恢复上限
    → applied delta

活动、反馈和总结均保存所用快照。规则版本不匹配时使用固定规则安全路径并阻止该 factor 学习，
不能静默沿用。

## 5. ActivityImpactLearner

### 5.1 输入资格

只读取：

- collectionSource 为 sampledPrompt；
- samplingPolicyVersion 受支持；
- 已结算生活日；
- activity、sample、feedback 和快照完整；
- 默认理论值非 0；
- applied 等于 personalized theoretical，没有恢复截断；
- direction 不是 directionMismatch；
- 当前 ActivityImpactKey 与 factor regime；
- factorRegimeStartedLifeDay 当日及以后。

### 5.2 聚合

- consumption 与 recovery 分开；
- 每个 key 独立计算；
- 时长档位异质达到门时返回 unstable；
- aboutRight 支持不变；
- stronger 只能增大绝对影响；
- weaker 只能减小绝对影响；
- factor 不跨 0；
- directionMismatch 单独进入 veto 审计；
- 可在一个 activityImpact 版本中修改 B3-0 允许的多个互不冲突键；
- baseline 完整复制且不变。

### 5.3 输出与门

输出 insufficientEvidence、unstable、noChange、configurationBlocked 或 candidate。生成可执行
candidate 要求总门、activityImpactProductionLearningEnabled 和模式非 off。自动安排还不在
本阶段正式开启。

## 6. Migration 与 backup

- v4 到 v5 分步迁移；
- v1 至 v4 备份导入执行各自桥接；
- v5 导出 models、factors、samples、feedback 新快照和 activity 新快照；
- v5 往返保持所有终态；
- 旧 userInitiated 不变成 sampledPrompt；
- 恢复后验证 factor 与 fingerprint、父模型、rule version 和 regime；
- 迁移、恢复失败完整回滚。

## 7. 自动化测试

### 7.1 Migration

- 无 feedback、v2 主动 feedback、invalidated feedback；
- implicit 1.0 不切 fingerprint 或 epoch；
- 新列快照准确；
- 旧活动不回算；
- v4 到 v5 中途失败回滚；
- v1 至 v5 备份导入和 v5 往返。

### 7.2 Sampler

- 模式 off 零提示；
- 每日上限；
- 跳过冷却；
- 重启稳定；
- 不读取结果字段；
- selected、prompted、responded、skipped、expired、invalidated；
- 活动编辑和删除；
- 不同 policy version 独立；
- 200% 字号下提示可跳过。

### 7.3 Calculation

- factor 1.0；
- consumption 与 recovery；
- 配置取整所有半值边界；
- 恢复上限；
- rule version 不匹配；
- 快照与 summary 稳定重放；
- baseline 改变不重置 factor regime。

### 7.4 Learner

- userInitiated 全部排除；
- 不受支持 policy 排除；
- 未结算、零值、截断、directionMismatch、invalidated 排除；
- key 与 sign 隔离；
- 时长异质；
- 最小样本和日数边界；
- factor 步长与范围；
- 旧 factor regime 不复用；
- 相同输入确定且幂等；
- 一次只改变 activityImpact；
- 全局已有 baseline candidate 时 blocked。

### 7.5 回归

format、analyze、全量 test、coverage、debug APK 和 git diff --check；固定规则表、旧活动、summary
和 baseline 行为必须保持。

## 8. 模拟器与真机验收

工程生命周期先用明确 fixture：

1. 抽中、展示、跳过和响应；
2. 编辑后失效；
3. 多天合格 sampled feedback；
4. candidate、noChange、unstable 和 insufficient；
5. 重启和恢复不重复 sample 或 run；
6. 新 factor 候选不影响当前活动计算。

真机只验证已发布抽样策略的负担和快照，不用 fixture 写入用户数据库。activityImpactAutoApplyEnabled
保持 false。

## 9. 停止条件

- schema 迁移使旧 feedback 获得生产资格；
- 隐含 1.0 导致 regime 切换；
- 抽样读取反馈结果；
- 跳过创建伪反馈；
- sign 或 rule version 串用；
- baseline 被活动 learner 修改；
- 旧 regime 反馈重复推动新 factor；
- 自动应用路径提前开启；
- 历史活动或 summary 重算。

## 10. 退出证据

- schema v5、backup、sampler、calculation 和 learner 全绿；
- fixture 生命周期记录；
- 真机抽样负担记录；
- 正式 activityImpactAutoApplyEnabled 仍为 false；
- B3-2 可以复用统一 activation service 完成安全闭环。
