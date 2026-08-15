# PowerManager MVP-B 总体验收 Spec v1

## 0. 文档状态

- 版本：1.0
- 日期：2026-08-15
- 状态：待 B0-0 至 B3-2 全部完成后执行
- 验收对象：MVP-B 自动学习工程能力与真实产品状态

## 1. 验收原则

MVP-B 完成必须由当前代码、数据库、测试、APK、真机行为和阶段记录共同证明。文档意图、单一
测试、没有发现明显错误或 fixture 中成功变化都不能单独证明完成。

工程完成与产品验证分别给结论：

- 工程：complete 或 incomplete；
- baseline 产品假设：validated、rejected 或 inconclusive；
- activityImpact 产品假设：validated、rejected 或 inconclusive。

产品假设可以 rejected 或 inconclusive，但工程退出仍要求系统能安全得到更新、无需变化或证据
不足，并完整实现两个参数族的生命周期。若产品假设 rejected，对应生产门必须保持关闭。

## 2. 需求追踪审计

逐行检查 MVP-B 规则与实现追踪矩阵。每行必须有：

- 当前权威代码位置；
- schema 或持久化证据；
- 自动化测试名称；
- 模拟器或真机证据；
- 当前状态；
- 未验证限制。

任何 P0 行只有间接证据、测试未覆盖正式路径或状态仍为阻塞，都视为未完成。

## 3. 数据与迁移验收

- schema v1 到 v2、v2 到 v3、v3 到 v4、v4 到 v5 分步 fixture；
- 每步失败回滚；
- 原七表历史字段和 summary 不变；
- legacy observation 永不获得资格；
- old userInitiated feedback 永不变成生产 sampled feedback；
- initial model 不切有效 regime；
- 每次真实 activation / revert 切 epoch；
- legacy pending base 和 pending rule 全场景；
- v1 至 v5 backup 导入；
- v5 完整往返；
- restore 过期 automatic 与明确用户 schedule 的差异；
- 唯一 active 和全局唯一待处理；
- foreign_key_check、integrity_check、索引和触发器。

## 4. 自动学习验收

### 4.1 Evidence 与重现

- 同一证据、源模型、算法和配置得到相同 hash 与结果；
- currentMoment、yesterday、model regime 和 factor regime 不混合；
- 当前日数据不入模；
- 标题、备注和展示文案不进入 hash；
- retryable 与 terminal failure 正确；
- 无新证据零写入。

### 4.2 Baseline

- insufficient、unstable、noChange、blocked 和 candidate；
- 方向、步长、anchor 累计、hard range、冷却和反事实；
- off、review、automatic；
- 通知、取消、未来激活、撤回和恶化暂停；
- 历史冻结；
- production gate 关闭时写路径不可达。

### 4.3 ActivityImpact

- 只用受支持 sampledPrompt；
- 抽样无结果选择偏差、可跳过且有负担上限；
- sign、key、rule version、time band 与 factor regime 隔离；
- zero、cap、directionMismatch 和 invalidated 排除；
- factor 正数、范围、步长和取整；
- off、review、automatic 与统一生命周期；
- baseline 不被同时修改。

### 4.4 参数族协调

- 全局最多一个待处理版本；
- 同时就绪按优先级只处理一个；
- 首个激活后另一个重新冻结证据；
- 模式、暂停、冷却和授权互不继承；
- 备份恢复不重复运行或激活。

## 5. 用户体验验收

- 用户先选择实际状态，再看到系统估计；
- coverage 和昨日参考时刻清楚；
- 自动学习记录能回答证据、变化、时间和控制；
- automatic 不是静默变化；
- 模式说明和新参数族授权独立；
- 反馈可跳过且不反复催促；
- 错误不泄露敏感数据；
- 200% 字号、小屏、横屏和 TalkBack 可完成核心流程；
- 没有把估计写成医学、能力或客观真值。

## 6. 全量验证命令

在 app 目录：

    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    dart format --output=none --set-exit-if-changed lib test
    flutter analyze
    flutter test
    flutter test --coverage
    flutter build apk --debug

若仓库届时新增集成测试或 CI 命令，也必须执行。根目录执行：

    git diff --check
    git status --short

必须检查最终 diff、生成文件、调试入口、预生产配置、敏感 fixture 和未跟踪文件。

## 7. 模拟器矩阵

- 干净安装；
- schema v1 连续覆盖升级到 v5；
- 每个中间版本恢复；
- currentMoment 和 yesterday；
- sample 展示、跳过、响应和失效；
- baseline 与 activity 的 review / automatic；
- 临近 04:00、后台、重启；
- 通知权限关闭；
- 候选取消与模型撤回；
- restore 过期 schedule；
- 数据不足、无需变化、不稳定、配置阻塞和恶化暂停；
- 200% 字号和小屏。

日志不得有未解释 Flutter 异常、Crash、ANR 或数据库错误。

## 8. 真机矩阵

1. 升级前验证并导出外部备份；
2. 从当前真实 schema 分步覆盖升级；
3. 对比聚合、历史、当前模型和规则；
4. 连续自然记录观测；
5. 验证抽样负担；
6. 在获得真实生产授权时验证通知、取消和未来生效；
7. 重启、后台和跨生活日；
8. v5 备份、预览和恢复；
9. 验证旧历史不变；
10. 连续使用后记录两个参数族的产品状态。

不得用 ADB 修改真实数据库来通过产品门。涉及高风险自动变化前必须有外部可恢复备份。

## 9. P0 缺陷门

以下任一未解决即工程 incomplete：

- 数据丢失或不可恢复迁移；
- 静默参数变化；
- 重复运行或激活；
- 当前日或历史漂移；
- 不同证据分组串用；
- 两参数族同时变化；
- automatic 缺通知、取消或撤回；
- 模式或授权互相继承；
- 生产门关闭但写路径可达；
- 用户主动反馈进入生产 factor；
- 过期恢复后补应用；
- 敏感内容进入日志、hash 或仓库。

P1 问题若影响理解、可访问性或撤回，也必须在发布前修复。纯视觉 P2 可以记录延期。

## 10. 最终产物

- 每个阶段的实现与验收记录；
- 更新后的 PRD、配置、算法、技术方案和追踪矩阵；
- schema v1 至 v5 fixtures；
- backup compatibility fixtures；
- 全量测试与构建日志摘要；
- 模拟器与真机验收记录；
- baseline 与 activityImpact 产品验证报告；
- 已知限制、非目标和后续 Backlog；
- 最终提交哈希和可安装 APK 路径。

## 11. 完成判定

只有追踪矩阵所有 P0 有直接证据、全部自动化与设备门通过、正式构建不含预生产绕过、没有未解决
P0，并且两个参数族的工程生命周期均完成，才可将 MVP-B 工程状态标为 complete。

真实证据不足不阻止工程能力完成，但对应产品状态必须是 inconclusive，生产门保持与证据相符；
不得把工程全绿改写成“自动学习已经证明有效”。
