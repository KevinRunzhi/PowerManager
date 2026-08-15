# PowerManager MVP-B 阶段 B2-1：基准线自动学习与安全激活 Spec v1

## 0. 文档状态

- 版本：1.3
- 日期：2026-08-15
- 状态：B2-0 已通过；B2-1 工程实现与自动化验收已完成，等待模拟器矩阵记录；生产门保持关闭
- 数据库版本：保持 schema v4
- 下一阶段：B2-2 调整后真实监测

## 1. 阶段目标

把 B1-1 已冻结的基准线规则合同接入完整生命周期，使 review 和 automatic 都能从新结算证据
生成候选；automatic 在全部安全门通过后自动安排到未来生活日，用户可在生效前取消、生效后
通过未来版本撤回。

阶段工程验收使用带水印的预生产配置和隔离数据库；最终交付配置的 production / autoApply 门
保持 false，直到真机自然证据通过。这里的“完整生产生命周期”指生产代码路径与安全语义已经
实现，不代表当前真实用户数据已授权执行变化。

## 2. 开关与授权

生成生产候选同时要求：

- automaticLearningEngineEnabled 为 true；
- baselineProductionLearningEnabled 为 true；
- baselineLearningMode 不是 off；
- 正式配置完整且受支持。

自动安排额外要求 baselineAutoApplyEnabled 为 true 和模式为 automatic。任一条件失败都保持
当前模型并保存 configurationBlocked 原因，不静默降级为越权变化。

工程验证使用明确版本化预生产配置走同一门禁。禁止 mock 掉 gate 或直接插入 scheduled 作为
唯一测试手段。

工程配置真源为 `preprod-baseline-lifecycle-v1-do-not-ship`：review 每窗 5 / 7、合计 10 / 14、
每窗最多 1 反向；automatic 每窗 6 / 7、合计 12 / 14、零反向；step 2、anchor ±8、通知 24 小时、
证据年龄 45 天、候选寿命 7 天。完整参数和水印边界见 B1-1 工程决策记录。正式 Provider 不得
构造该配置。

## 3. BaselineLearner 纯函数

输入：

- 单一 modelRegimeKey 的冻结 eligible observations；
- 当前 active model 和 baseline anchor；
- B1-1 生产算法与配置；
- 当前冷却、暂停和全局候选状态。

输出：

- insufficientEvidence；
- unstable；
- noChange；
- configurationBlocked；
- candidate。

方向固定：

- 持续 actual 低于 estimate，只能向下；
- 持续 actual 高于 estimate，只能向上；
- 相符或方向不稳定不变；
- ordinal 差绝不直接换算点数。

候选必须通过生产样本、跨度、方向、单步、anchor 累计边界、60 至 140 hard range、证据年龄、
反事实不恶化和源模型一致性。

## 4. 生成与幂等

1. 生活日结算后协调器按配置优先级选择 baseline；
2. 冻结证据并计算 hash；
3. 创建或复用 LearningRun；
4. 运行纯 learner；
5. 非 candidate 只保存结果；
6. candidate 在同事务创建完整复制的 PersonalizationVersion；
7. review 写 awaitingReview；
8. automatic 通过安全门后计算 future effectiveLifeDay，并与通知一起写 scheduled；
9. 全局已有待处理版本时本次返回 blocked；
10. 相同幂等键、父模型和证据不能创建第二版本。

活动影响参数原样复制。changedParameterFamily 只能为 baseline。

## 5. 用户控制

### 5.1 Review

候选页显示：

- 系统观察到的方向；
- 合格证据数、日期范围和 referenceType；
- 排除摘要；
- 当前 base 与候选 base；
- 单步与相对 anchor 累计变化；
- 接受后的最早生效日；
- 接受、稍后、拒绝。

接受前 current model 不变。稍后保留但受候选寿命限制。拒绝进入冷却。

### 5.2 Automatic

自动安排后立即产生持久 App 内通知：

- 变化原因；
- 当前值与新值；
- 生效生活日；
- 取消入口；
- 模型历史入口。

系统通知只是增强。权限关闭、发送失败或用户清除系统通知都不能丢失 App 内记录。

### 5.3 取消与撤回

- scheduled 生效前取消，当前模型不变并进入冷却；
- active 撤回创建 future revert version；
- 撤回到旧数值仍使用新 epoch；
- 已结算历史继续引用原版本；
- 自动撤回在 MVP-B 默认禁止。

## 6. 激活事务

OperationPreparationService 在新生活日开始时：

1. 结算旧生活日；
2. 找出到期 scheduled；
3. 重新验证全部门与证据；
4. 条件更新旧 active 为 superseded；
5. 条件更新 scheduled 为 active；
6. 写 activatedAt、epoch 和当前模型引用；
7. 由新模型计算尚未开始的生活日；
8. 提交后刷新 Provider；
9. 请求后续协调器，但冷却期内不会立刻再变。

当前已开始 lifeDay 和历史不重算。重复 prepare、重启和并发只成功一次。

## 7. 自动化测试

### 7.1 Learner

- 所有生产阈值等号边界；
- 向上、向下、相符、不稳定；
- 单步、anchor 累计、hard range；
- 证据年龄、冷却、暂停；
- 反事实恶化；
- referenceType 优先级；
- 相同输入字节级稳定；
- ordinal 差大小不改变已配置步长；
- 未定义任一参数返回 configurationBlocked。

### 7.2 Coordinator

- off 零新运行；
- review 创建 awaitingReview；
- automatic 门未开不安排；
- automatic 全门通过安排且通知原子；
- 两个并发触发只生成一个；
- 全局已有活动候选时 baseline blocked；
- retryable 与 terminal failure；
- 证据或父模型变化使候选失效；
- 过期和模式切换不复活。

### 7.3 Lifecycle

- 接受、稍后、重新打开、拒绝；
- 自动安排、通知失败、取消；
- 最短通知跨 04:00 边界；
- 到期激活、重复 prepare、重启；
- 手动修改冲突；
- 激活后撤回；
- restore 过期 automatic 不补应用；
- reviewAccepted 恢复保持用户意图；
- 新 epoch 与历史冻结。

### 7.4 UI 与回归

- 模式说明、候选详情、通知、取消、历史和撤回；
- 200% 字号、小屏、TalkBack 标签；
- format、analyze、全量 test、coverage、模拟器可运行构建；
- git diff --check。

## 8. 预生产模拟器与最终真机复验

先在隔离测试数据库使用版本化预生产配置完成：

1. review 全生命周期；
2. automatic 全生命周期；
3. 临近 04:00 的通知时间；
4. 重启、后台、恢复和重复 prepare；
5. 取消与撤回；
6. 数据不足、无需变化和不稳定。

本阶段不操作真机。MVP-B 总体验收安装完成后，真机真实数据库只执行已由真实证据授权的路径；
真实数据不足时应显示继续学习，不用 fixture 污染用户数据库。每次自动变化前必须另有外部
可恢复备份。

## 9. 停止条件

- review 未确认就改变 base；
- automatic 任一门关闭仍安排；
- 生效日不满足通知时间；
- 通知失败但 schedule 成功；
- 激活前证据变化仍应用；
- 重启或恢复重复激活；
- 当前日或历史重算；
- 超过 anchor 累计边界；
- baseline 运行改变活动倍率；
- 用户无法取消或撤回。

## 10. 退出证据

- 纯 learner、coordinator、state machine 和 Widget 全绿；
- 预生产全模式矩阵记录；
- 真机安全生命周期复验登记到 MVP-B 总体验收；
- 正式配置的 baselineAutoApplyEnabled 在最终真机门与真实证据齐全前保持 false；
- B2-2 观察窗口已经开始并记录 active model、epoch 和起始 lifeDay。
