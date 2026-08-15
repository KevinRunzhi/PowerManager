# PowerManager MVP-B 阶段 B1-0：自动影子学习器实现与验收记录

## 0. 结论

- 日期：2026-08-15
- 实现起点：`0607359`（B0-3 阶段提交）
- 阶段结论：**通过自动化与 Pixel_7 模拟器工程门，可以进入 B1-1 工程决策轨**
- App：`0.1.4+10012`
- 数据库：schema v2 无损升级到 schema v3
- 学习能力：自动运行只读证据审计；不生成候选、不激活模型、不改变生产参数
- 产品验证状态：`inconclusive`；自然使用实验延期到 MVP-B 总体验收安装真机后
- 真机与最终 APK：按设备策略继续延期到 MVP-B 总体验收

本记录只保存匿名聚合、合成 golden vector 和工程结论。模拟器数据库、备份正文、UI dump、截图
和隔离 fixture 均位于 Git 忽略目录，没有进入仓库；fixture 结果不作为真实产品有效性证据。

## 1. 实现内容

### 1.1 schema v3 与可恢复状态机

- 新增 `learning_runs`，固定 baseline、`evidence-shadow-v1`、
  `evidence-readiness-14x21-v1` 和 `canonical-evidence-sha256-v1` 合同；
- 数据库约束分开保存运行状态与算法结果，evidence-only 运行的 candidate 必须为 SQL `NULL`；
- 五元组唯一键与确定性 run ID 双重防重，completed / terminalFailure 由触发器保护为不可更新；
- v1 → v2 → v3 在同一升级事务顺序执行，v2 → v3 只新增学习表、索引和保护触发器，不重写
  原业务行；任一失败检查点完整回滚；
- pending、running、retryableFailure 可复用同一 id 和 triggeredAt 恢复；terminalFailure 不进入
  忙循环；
- schema v3 不存在 `personalization_versions`，也没有候选或激活外键。

### 1.2 规范证据与只读评估

- `CanonicalJsonEncoder` 递归按 Unicode key 排序，只允许 null、bool、integer、string、list 和
  object；UTC 固定六位微秒；double 与非规范 JSON 被拒绝；
- 每个 referenceType 与 model regime 独立构造证据，稳定按 lifeDay、observedAt、id 排序，只取
  最近 14 条，按 7 + 7 切窗，并按 21 个日历日跨度判断；
- 更早 eligible 只进入描述性总计，不改变当前 hash；scoped excluded 只保存 id、生活日、时间和
  稳定 reason code；不复制活动标题、备注或其他自由文本；
- 当前算法只返回 `insufficientEvidence`、`readyForAudit` 或 `configurationBlocked`，始终不输出
  candidate；
- v3 备份导入对证据字段做精确白名单，并交叉验证排序、方向、窗口、跨度、排除统计、就绪门、
  结果和原因码；额外隐私字段或伪造描述会在写库前拒绝。

冻结的合成 golden vector：

```text
evidenceHash = 236b25f654a0c329589e41592d7359c16f240b52778e0c11067ebe783315d05d
runId = learning-run-sha256-v1:a9b7787f28ff5c4a5d65806fee059fb450c2dc893a12281cb1658f84907512e0
```

### 1.3 自动协调、生命周期与零副作用

- `AutomaticLearningCoordinator` 与现有业务写入共用 `BusinessWriteCoordinator`，在一致读取、
  完整性门通过后分段写 pending → running → completed；
- 冷启动、恢复前台、生活日结算和安全恢复在 prepare 结束后请求；普通 provider invalidate 不重复
  请求；同证据、重启、并发请求均零新增；
- 备份恢复事务内不运行学习器；恢复完成、缓存重建、safeRestore prepare 与完整性门依次通过后
  才请求一次；
- 学习失败被限制在影子路径，不阻断首页和核心 prepare；
- 依赖图没有 `ModelActivationService`，协调器只能读取证据和写 `learning_runs`，不能写
  app settings、规则或活动计算参数。

### 1.4 备份、Data Health 与安全文案

- JSON 备份升级为 schemaVersion 3；v1 / v2 继续可导入，v3 完整往返学习运行；恢复失败回滚
  业务表与保护触发器；
- 业务内容摘要包含 learning runs，恢复预览显示运行数量；
- Data Health 展示两个 referenceType 的数量、跨度、双窗口、方向分布、排除原因、最近安全结果
  与失败状态；
- 固定说明“达到审计门不代表系统会改变参数”，普通 UI 不展示 evidence hash、run id、模型 key
  或内部异常。

## 2. 自动化验收

在 `app/` 执行：

- `dart run build_runner build`：通过，schema / DAO 生成结果一致；
- `dart format --output=none --set-exit-if-changed .`：通过；
- `flutter analyze`：通过，0 个问题；
- `flutter test --coverage --reporter expanded`：331 项通过，0 失败；
- 行覆盖：7756 / 11061（70.12%）；
- `git diff --check`：通过，无 whitespace error。

关键覆盖包括：v1 / v2 → v3 空库与全量迁移、失败回滚、约束与 final immutability、v1 / v2 / v3
备份往返、恢复失败、13 / 14 / 15 条、20 / 21 / 22 日边界、最近 14 条、稳定排序、双窗口、全部
排除原因、reference / regime 隔离、字段顺序与时区稳定、golden vector、较早证据 hash 不变、13 →
14 落库结果、无新证据零写入、并发防重、pending / running / retryable 崩溃恢复、terminal 防忙循环、
完整性 fail-closed、配置关闭、safeRestore、200% 字号、小屏、失败安全文案与隐私字段拒绝。

## 3. Pixel_7 模拟器验收

设备：`emulator-5554`，Android 14 / API 34。ADB 只发现这一台模拟器；所有命令均显式指定该
设备，物理手机未连接、未操作。

### 3.1 真实模拟器数据覆盖升级

- 使用普通 profile 临时构建覆盖安装 `0.1.4+10012`，未卸载、未清数据；firstInstallTime 保持
  `2026-07-26 07:16:04`；
- schema v2 → v3 后原聚合保持：晨间 9、活动 30、观测 4、活动反馈 1、总结 11、回执 5；
- schema v3 自动创建 2 条 baseline 只读运行：当前参考口径 1 条 eligible，昨日结束口径 0 条
  eligible；均为 `insufficientEvidence`，candidate 全部为 SQL `NULL`；
- base 保持 100，pending base / pending rule 为空，active rule 保持
  `energy-rules-v2-mvp-a`。

### 3.2 隔离 13 → 14 条生命周期

使用可恢复的 schema v3 本地副本和独立 base 101 model regime：

- 13 条、2025-01-01 至 2025-01-25、跨度 24 日：自动生成一条
  `insufficientEvidence`，窗口 `[7,6]`，还差 1 条；
- 强制停止并重启后，run id、triggeredAt、completedAt 和总数完全不变；
- 在同一数据库追加已结算第 14 条后，旧运行保持不可变，新 hash 自动生成第二条
  `readyForAudit`，跨度 26 日，窗口 `[7,7]`；
- 两条运行 candidate 均为 SQL `NULL`，base 始终为 101，规则和 pending 字段未变化；
- Data Health 实机画面显示“14 / 14”“26 / 21 天”“7 / 7 · 7 / 7”“已达到审计门”，并明确
  不会生成候选值或改变基准线；UI dump 不含任何 hash、run id 或 model key；
- fixture 验证结束后按保存的字节级副本恢复原模拟器数据库，再次启动首页显示 base 100。

### 3.3 v3 备份与最终状态

- 在恢复后的正常数据上重新生成 latest，UI 显示 42.6 KiB；严格回读为 schemaVersion 3、App
  `0.1.4+10012`、规则 1、晨间 9、活动 30、观测 4、反馈 1、学习运行 2、总结 11、回执 5；
- 备份内 candidate 非空数量 0，evidence hash 格式异常数量 0；
- Data Health 显示 schema v3 完整重放通过、0 项异常，当前口径为 1 / 14；
- 全流程日志没有 Flutter fatal、SQLite / Drift、FileSystemException、未处理异常、Crash 或 ANR；
- 验收后模拟器保留 `0.1.4+10012` 和原业务数据，临时 profile APK 已从工作区精确删除。

## 4. 门禁与未验证项

- `automaticLearningEngineEnabled = true` 只开启 B1 evidence-only 引擎；
- `baselineProductionLearningEnabled`、`baselineAutoApplyEnabled`、
  `activityImpactProductionLearningEnabled`、`activityImpactAutoApplyEnabled` 均保持 `false`；
- baseline / activityImpact 用户模式仍默认为 `off`，schema v4 前尚未提供用户模式 UI；
- 本阶段没有个人模型、候选、安排、激活、取消、撤回或活动倍率生产路径；
- 自然填写负担、方向稳定性和学习是否真正有帮助仍未验证，产品状态只能是 `inconclusive`；
- 未构建或交付最终 APK，未安装或修改物理手机。

## 5. 放行决定

B1-0 的停止条件均未命中。证据选择、规范哈希、状态恢复、自动触发、备份往返、UI 隐私和生产
零副作用均通过；允许提交本阶段并进入 B1-1 工程决策轨。B1-1 只能形成带水印、不可发布的工程
决策包，真实产品轨继续等待全部 MVP-B 工程完成后的真机自然使用，四个生产 / 自动应用门保持
关闭。
