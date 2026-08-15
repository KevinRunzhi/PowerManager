# PowerManager MVP-B 阶段 B1-1：真实影子观察与生产决策 Spec v1

## 0. 文档状态

- 版本：1.3
- 日期：2026-08-15
- 状态：工程决策包已通过；产品轨保持 inconclusive，最终安装后执行真实实验
- 类型：真实使用实验与生产参数决策门
- 数据库版本：保持 schema v3
- 下一阶段：B2-0；生产门仍由真实实验决定

### 0.1 两轨执行说明

本 Spec 保留真实产品实验的严格性，但不再让尚未安装的物理手机阻塞工程实现：

- **工程轨**：使用冻结 fixture 与 Pixel_7 模拟器验证证据审计、候选回放、边界、失败分支和 UI，
  形成带水印的预生产配置；全部生产门保持 false，通过后可进入 B2-0；
- **产品轨**：MVP-B 全部工程阶段完成并安装真机后，只用自然数据执行本 Spec，给出
  `validated / rejected / inconclusive`；
- 工程轨参数不得被描述为生产阈值，不得进入最终交付配置。真实数据不足时产品状态就是
  `inconclusive`，不能补造证据。

## 1. 实验目标

用项目作者自然使用产生的新合同数据回答：

1. 每日观测是否足够低负担且理解一致；
2. 哪一种 referenceType 可以进入基准线生产学习；
3. 偏差是否在连续窗口中呈稳定方向；
4. 小幅候选基准线是否在反事实中有改善且不过度反应；
5. 生产步长、边界、冷却、通知时间和恶化保护能否被明确、安全地冻结；
6. 若不能，应该继续观察、修正采集还是停止基准线假设。

工程测试不能代替本实验，fixture、ADB、直接改库和为了达标补填状态均不计为产品证据。

## 2. 实验前置

- B1-0 全部自动化和模拟器退出条件通过；
- 工程轨运行 schema v3 模拟器且备份可恢复；产品轨最终在真机复验；
- 当前 base、rule、comparison band、fingerprint 和 epoch 在观察期内稳定；
- 日常使用模式不为实验刻意改变；
- 生产学习和自动应用门保持关闭；
- 记录开始时间、App 版本、配置版本、算法版本和当前 modelRegimeKey。

若观察期间手动修改 base、规则生效、恢复不兼容备份或真实激活模型，则旧窗口结束，新 regime
从零积累；不得拼接。

## 3. 采集方案

### 3.1 每日观测

- 只在自然需要时填写 currentMoment；
- 若当天未填，可在次日自然补填 previousLifeDayEnd；
- 每次如实选择 coverage confirmed 或 uncertain；
- 不为了增加样本选择 confirmed；
- 系统按 referenceType 分开计数；
- 至少在单一 regime、单一 referenceType 内满足 14 条和 21 日跨度，才进入候选审计。

### 3.2 负担记录

本机只记录聚合：

- Sheet 展示次数、完成、取消和错误；
- coverage confirmed / uncertain；
- yesterday 入口可用、完成和跳过；
- 每种 referenceType 的 eligible / excluded；
- 用户对问题理解是否需要反复阅读；
- 是否因新增问题减少日常记录意愿。

不上传明细，不记录活动标题或备注。

### 3.3 活动反馈旁路观察

B0-3 的 userInitiated feedback 继续自然积累，只用于：

- 检查四档语义是否可理解；
- 观察 directionMismatch、截断和失效率；
- 为 B3-0 列出待回答问题。

这些反馈不能用于 B2 基准线候选，也不能提前决定生产倍率。

## 4. 两次分析门

### 4.1 第一次：证据审计

使用 evidence-shadow-v1，只输出：

- 是否达到数量和跨度；
- 两窗口方向原始分布；
- 排除原因和排除率；
- referenceType 的完成负担；
- regime 是否稳定；
- readyForAudit 或 insufficientEvidence。

第一次不得输出候选 base。

### 4.2 第二次：shadow-only 候选回放

只有第一次审计形成书面决策后，才发布新的 shadow-only 配置，明确：

- 方向一致性规则；
- 影子单步候选；
- 影子累计边界；
- 反事实比较方法；
- 极端输入保护；
- 该配置绝不可被激活服务读取。

新算法版本在冻结证据上生成 candidateValuesJson 和反事实报告，但模型仍不生效。

schema v3 的已发布 CHECK 要求 `candidateValuesJson IS NULL`，因此工程轨的 candidateValuesJson
只能作为纯函数返回值和离线报告，不写 `learning_runs`、备份或普通 UI。离线结构必须包含
`PREPRODUCTION_ONLY_DO_NOT_ACTIVATE_OR_SHIP` 水印和 `activationAllowed = false`；schema v4
重建 learning run 合同后，才允许持久化不带预生产水印、且仍受正式 gate 约束的候选。

## 5. 反事实审计

至少回答：

- 候选是否让同一冻结窗口的方向分布更接近相符；
- 是否把原本相符的天数推向相反方向；
- 两个连续窗口是否都支持同一方向；
- 采用更大或更小步长时是否出现过度反应；
- 相对 baseline anchor 的累计变化如何受限；
- 临近 04:00 生成时最早哪一天才能满足完整通知时间；
- 证据过旧或候选长时间未处理如何失效；
- 拒绝、取消或撤回后多久再提示才不会震荡；
- 新 regime 的恶化如何识别而不自动来回改值。

报告使用方向性描述，不宣称统计显著。

## 6. 必须形成的生产决策

通过时发布一个新的规则配置与基准线算法版本，完整定义：

- 允许的 referenceType 与多来源优先级；
- 生产样本数、跨度和双窗口规则；
- 方向一致性阈值；
- 单次步长；
- 相对 baseline anchor 的累计边界；
- hard range 60 至 140 内的进一步约束；
- minimumAutomaticChangeNoticeDuration；
- maximumProductionEvidenceAge；
- maximumCandidateLifetime；
- 拒绝、取消、撤回和激活后的冷却；
- review 与 automatic 的安全门差异；
- 反事实不恶化边界；
- 激活后恶化暂停阈值；
- 最小有用改善和最大撤回、暂停比例；
- 两个参数族同时就绪时的优先级。

任一生产安全参数未定义时，baselineProductionLearningEnabled 必须保持 false。

工程轨允许为覆盖 B2 生命周期定义独立、显式标记且不可发布的预生产参数；它们不满足本节
“生产决策”，不能开启 baselineProductionLearningEnabled 或 baselineAutoApplyEnabled。

## 7. 决策分支

### 7.1 通过

- 数据完整且负担可接受；
- 至少一个 referenceType 的方向规则可定义；
- shadow-only 回放不过度反应；
- 全部生产安全参数可冻结。

结果：发布 B2 输入文档，允许实施 B2-0。baselineAutoApplyEnabled 仍保持 false。

### 7.2 继续观察

- 采集正确但数量不足或方向不稳定。

结果：保持 schema v3 和影子模式，写清下一次审计日期或新增自然证据条件，不降低门槛。

### 7.3 修正采集

- 排除率高、referenceType 被误解、coverage 选择失真或 UI 明显增加负担。

结果：回 B0-3，先修 Spec 和采集实现，修复测试后重新开始新证据窗口。

### 7.4 停止基准线假设

- 即使数据完整，候选仍不能改善参考价值或用户认为变化无帮助。

结果：baseline 生产门保持 false，产品状态记为 rejected；不得用复杂模型或降低门槛掩盖。

### 7.5 工程先行、产品待定

真实实验尚未开始，但工程轨的输入、算法边界、极端失败和安全状态机合同完整。

结果：产品状态记为 inconclusive，生产门保持 false；预生产配置仅供模拟器完成 B2-0 至 B2-2，
不阻塞工程阶段继续。

## 8. 验收产物

- 真实观察执行记录；
- 按 referenceType 和 regime 分开的匿名聚合；
- 填写负担与理解记录；
- 第一次证据审计报告；
- shadow-only 配置版本；
- 候选与极端输入反事实报告；
- 生产参数决策记录或继续观察理由；
- 模式与通知 UI Spec；
- schema v4 迁移 Spec 的最终修订；
- 追踪矩阵更新；
- 产品验证状态：validated、rejected 或 inconclusive。

## 9. 数据与隐私

- 原始数据库和备份不进入 Git；
- 报告只保存聚合、版本和去标识化证据编号；
- 不复制活动标题、备注和自由文本；
- evidenceHash 不在普通 UI 展示；
- 人工阅读原始明细时只在本机进行。

## 10. 停止条件

- 为达到 14 条而补造或重复提交；
- 混合 referenceType 或 regime；
- 观察期间参数变化却继续使用旧窗口；
- shadow-only 候选能被生产路径激活；
- 生产参数仍有空缺却准备开启门；
- 负担明显变差仍继续要求更多输入；
- 把工程测试结论写成真实产品有效。

## 11. 阶段退出

工程阶段只有形成完整、可审计的工程决策包并证明生产门关闭才可进入 B2-0。真实产品轨只有
形成自然数据决策记录才算结束；真实数据不足时正确状态是 inconclusive 并继续观察，不得把
“没有发现问题”视为通过，也不得为了推进时间线自行填写生产阈值。

## 12. 本轮工程裁决

- 工程输入、反事实算法、极端边界、模式与通知 UI、schema v4 最终迁移合同均已冻结；
- 工程预生产配置为 `preprod-baseline-lifecycle-v1-do-not-ship`，只存在于文档和测试输入；
- 正常模拟器自然聚合不足，生产 referenceType 和生产参数均未选择；
- `baselineProductionLearningEnabled` 与 `baselineAutoApplyEnabled` 继续为 false；
- 工程轨按 7.5 分支退出并放行 B2-0，产品轨继续为 inconclusive。

详细证据见《阶段 B1-1 工程决策与反事实审计记录》；模式交互见《阶段 B1-1 学习模式与变更
通知 UI Spec》；schema v4 以《阶段 B2-0 Schema v4 最终迁移决策》为实现真源。
