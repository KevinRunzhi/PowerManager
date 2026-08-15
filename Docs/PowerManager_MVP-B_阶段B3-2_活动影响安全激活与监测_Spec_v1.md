# PowerManager MVP-B 阶段 B3-2：活动影响安全激活与监测 Spec v1

## 0. 文档状态

- 版本：1.2
- 日期：2026-08-15
- 状态：工程实现完成，待 MVP-B 总体验收；真实 sampled feedback 产品验证仍延期
- 数据库版本：保持 schema v5
- 下一阶段：MVP-B 总体验收

## 1. 阶段目标

让活动影响参数族复用 B2 的 review、automatic、未来生效、持久通知、取消、撤回、冷却和恶化
暂停能力。工程轨用隔离 sampled feedback fixture 验证不会跨方向传播、重复使用旧证据或与
baseline 同时变化；真实 sampled feedback 的产品验证延期到最终安装后。

## 2. 生产门

生成候选要求：

- automaticLearningEngineEnabled；
- activityImpactProductionLearningEnabled；
- activityImpactLearningMode 不是 off；
- B3-0 配置与 policy 受支持；
- 当前 parameter family 未暂停或冷却；
- 全局没有待处理模型。

自动安排额外要求 activityImpactAutoApplyEnabled 和 automatic 模式。B3 上线时模式仍为 off，
不能继承 baseline 授权。

## 3. 候选展示

每个活动影响候选必须展示：

- 变更的子类与 consumption / recovery；
- 使用的 sampled feedback 数、覆盖日和策略版本；
- stronger、aboutRight、weaker 与排除摘要；
- 当前 factor 和候选 factor；
- 对典型固定理论值的方向性示例；
- 不影响相反方向和其他未列键；
- 生效生活日、取消和撤回；
- directionMismatch 若达到 veto，明确说明进入规则复核而非倍率变化。

不展示活动标题、证据 ID 或原始哈希。

## 4. 生命周期

### 4.1 Review

- awaitingReview 不改变当前 factor；
- 接受后完整复制 baseline 和其他 factor，仅修改批准键；
- 拒绝或稍后按统一寿命和冷却；
- 接受前重新检查 evidence、policy、rule version 和父模型。

### 4.2 Automatic

- 通过自动安全门后与持久通知原子 scheduled；
- effectiveLifeDay 满足最短通知时间；
- 生效前用户可取消；
- mode 降级、门关闭、暂停、配置撤回或父模型变化使 schedule 退回或失效；
- 到期 prepare 只激活一次。

### 4.3 激活与新 regime

- 新 active model 只改变 activityImpact；
- effective fingerprint 改变；
- modelRegimeEpoch 随真实激活更新；
- 发生变化的 key 设置新 factorRegimeStartedLifeDay；
- 未变化 key 保留原 factor regime；
- baseline 与 anchor 原样复制；
- 当前日和历史活动不重算；
- 新生活日活动冻结新 factor 快照。

### 4.4 撤回与暂停

- 撤回创建未来 activityImpact 版本；
- 回到旧 factor 数值仍使用新 factor regime；
- 后续 sampled feedback 达到恶化门时只暂停 activityImpact；
- 默认保持 active，不自动来回调整；
- 用户可保持、撤回或恢复学习。

## 5. 参数族串行

baseline 与 activityImpact 同时就绪时：

1. 协调器读取配置优先级；
2. 只为一个参数族创建 run 或 candidate；
3. 另一个记录 blockedByOtherParameterFamily；
4. 首个版本激活并完成配置冷却与观察；
5. 另一个基于新父模型重新冻结证据；
6. 禁止把一次前后变化归因到两个参数族。

全局唯一待处理约束是最后防线，协调器仍需主动避免冲突。

## 6. 自动化测试

### 6.1 模式矩阵

- activity 默认 off 且不继承 baseline；
- off 零运行并取消本族未激活；
- review 接受前零变化；
- automatic 各门组合；
- review 到 automatic 不偷跑旧候选；
- automatic 到 review 退回待审核；
- baseline 模式和暂停不被意外修改。

### 6.2 Activation

- 通知与 schedule 原子；
- 最短通知跨 04:00；
- evidence、sample、policy、rule、父模型和 factor regime 重验；
- 重启、重复 prepare、并发和恢复只激活一次；
- 过期 automatic 恢复后失效；
- reviewAccepted 保留意图；
- 当前日与历史冻结；
- changed key 新 regime，未 changed key 保留。

### 6.3 串行与恢复

- 两参数族同时就绪只处理优先者；
- baseline candidate 存在时 activity blocked；
- activity candidate 存在时 baseline blocked；
- 第一个激活后第二个必须重新学习；
- v5 backup 往返不重复 sample、run、candidate 或 activation。

### 6.4 监测

- noChange、改善、恶化边界；
- 恶化暂停 activity，不影响 baseline；
- 暂停不自动回滚；
- 撤回到旧 factor 不复用旧证据；
- 重复评估不重复通知。

### 6.5 UI 与回归

- 候选、通知、历史、取消、撤回和暂停；
- 多键候选仍可理解；
- 200% 字号、小屏和 TalkBack；
- format、analyze、全量 test、coverage、模拟器可运行构建；
- git diff --check。

## 7. 预生产验收

使用隔离 fixture 完成：

1. sampled feedback 到 candidate；
2. review 接受、未来激活和撤回；
3. automatic 安排、取消、再次学习和激活；
4. consumption / recovery 不串用；
5. baseline 同时就绪时串行；
6. restore、重启和跨 04:00；
7. 恶化暂停；
8. 数据不足与 noChange。

预生产配置必须有显式水印且不能进入最终交付构建。

## 8. 最终安装后的真实监测（本阶段不执行）

- 只使用受支持 sampledPrompt；
- 新 factor regime 单独积累；
- 观察 aboutRight、stronger、weaker、directionMismatch 和提示负担；
- 检查新活动实际快照；
- 达到 B3-0 观察窗后记录 validated、rejected 或 inconclusive；
- 真实数据不足允许长期保持 1.0 或当前 factor；
- 不要求每个子类都产生变化。

## 9. 停止条件

- 未授权继承 baseline 模式；
- automatic 门未开却安排；
- 修改 consumption 时 recovery 一起变化；
- baseline 同一版本同时变化；
- 旧 factor regime 证据再次使用；
- 当前日或历史重算；
- 通知失败仍 schedule；
- 恶化后继续震荡；
- 用户不能取消、撤回或关闭；
- fixture 被计入真实产品结论。

## 10. 退出证据

- 全模式、激活、串行、恢复和监测测试全绿；
- 预生产生命周期记录；
- 真机抽样和安全生效复验登记到 MVP-B 总体验收；
- 当前真实产品状态明确为 inconclusive，后续真机可更新为 validated 或 rejected；
- 没有未解决 P0 / P1 数据、静默变化、历史漂移或不可恢复升级问题；
- 可以进入 MVP-B 总体验收。
