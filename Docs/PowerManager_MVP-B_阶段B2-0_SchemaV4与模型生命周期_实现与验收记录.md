# PowerManager MVP-B 阶段 B2-0：Schema v4 与模型生命周期实现与验收记录

## 0. 结论

- 阶段：B2-0
- Spec：`PowerManager_MVP-B_阶段B2-0_SchemaV4与模型生命周期_Spec_v1.md`
- 实现状态：工程轨通过，可以进入 B2-1
- 产品状态：`inconclusive`；正式生产学习、自动应用和生产阈值继续关闭
- 真实设备：未操作；按项目决策延期到 MVP-B 总体验收

B2-0 建立了 schema v4 的个人模型真源、分参数族学习模式、候选生命周期、持久通知、备份恢复
和激活前复验。正式 Provider 使用关闭的 `LearningProductionGate`；只有隔离测试传入显式的
预生产验证开关时，状态机和模式矩阵才可运行。

## 1. 主要实现

### 1.1 数据与迁移

- `personalization_versions` 成为当前基准线的唯一真源，initial / manual / learningRun /
  legacy pending / revert 均使用确定性 ID、fingerprint 和 regime epoch。
- schema v3 → v4 在同一迁移事务中重建 `learning_runs`、桥接 initial active、桥接合法的
  legacy pending base，并拒绝残缺 pending、未决 pending rule 和不一致旧数据。
- `app_settings` 删除旧的 base / pending base 真源，新增 baseline / activityImpact 各自的
  mode、suspension 和 cooldown；新增 `learning_consents` 与 `learning_notices`。
- daily summary 的旧 inline 参数保持字节级兼容并标记 `legacyInline`，新总结引用 active
  personalization version。
- schema 快照新增 `drift_schema_v4.json`，生成迁移帮助代码更新到 v4。

### 1.2 生命周期与安全门

- 实现纯生命周期转换器和 `ModelActivationService`，覆盖 candidate、awaitingReview、deferred、
  scheduled、active、superseded、rejected、canceled、invalidated、reverted。
- automatic 安排要求未来生活日、04:00 前至少 24 小时、持久 `changeScheduled` notice；通知失败
  与版本安排一起回滚。
- 激活前重验 persisted learning run、确定性 run ID、canonical evidence hash、14 条 / 21 日 /
  2×7 就绪门、源 regime、父模型、模式、暂停、冷却、证据年龄和候选寿命。
- 手动修改同参数族会失效旧候选并更新 anchor；相同值撤回仍创建新 epoch；暂停和恢复只影响
  对应参数族。
- 恢复后先做 safe restore preparation，再做完整 export / reparse；自动安排若已到期或错过会失效，
  用户明确安排保留。完整检查失败会明确返回失败，UI 不启动协调器。

### 1.3 备份与界面

- Json backup codec 支持 v1～v4 兼容；v4 对 active 唯一性、父链、source run、candidate 证据、
  consent、notice、schedule 和 production allowlist 做严格校验。
- 设置页提供两个独立参数族入口。正式 gate 下 review / automatic 真禁用且不写 consent；显式
  预生产验证开关下显示不可依赖颜色的文字和无障碍水印：
  `工程预生产验证 · 不会进入正式版本`。
- disclosure 明确说明 review / automatic、单次最多 2、anchor 累计 ±8、60～140 范围、至少
  24 小时通知、取消与撤回边界。

## 2. 测试与修复记录

本阶段永久回归覆盖：

- schema v4：无 pending、未来 pending、到期 pending、残缺 pending、未决 rule、summary / run
  字节保留、每个迁移故障点回滚、重启幂等；
- 生命周期：每个合法 / 非法转换、全局 active / pending 唯一、身份和终态不可变、模式矩阵、
  通知原子性、24 小时边界、证据 / 候选过期、冷却、暂停、撤回和 restore；
- 激活前证据：确定性 run ID、14 条证据、21 日跨度、canonical shape、readiness 描述篡改均会拒绝；
- 数据库：partial unique index、personalization identity / terminal trigger、consent 和 notice
  identity、外键和状态 shape；
- backup：v1～v4、v4 candidate graph、正式 allowlist、watermark、consent、notice、active 数量、
  24 小时安排、恢复后检查失败；
- Widget：正式 gate 零写入、预生产水印、两个参数族独立操作和 200% 文字缩放。

验收命令结果：

| 检查 | 结果 |
|---|---|
| `dart format` | 通过 |
| `flutter analyze` | 通过，无 issue |
| 阶段定向回归 | 209 项通过 |
| 全量 `flutter test --coverage` | 487 项通过 |
| 全项目行覆盖率 | 69.96%（`coverage/lcov.info`） |
| `git diff --check` | 通过 |

## 3. Android 模拟器验收

设备边界：只使用 `emulator-5554`（Android 14 / API 34，sdk gphone64 x86 64）。没有对物理手机
执行安装、清除数据或输入操作。

### 3.1 原地升级

模拟器原有数据库 SQLite header 为 schema v3，升级前校验值为：

`206107295128a8d00377639bc45cfc05dbc35bcef323fad09719f5bd6154f3b5`

通过 `flutter run -d emulator-5554 --debug --no-resident` 原地更新后：

- SQLite header 变为 schema v4；
- 应用冷启动成功，首页、晨间确认、能量球、活动入口、设置入口均出现在 Android UI hierarchy；
- 升级后数据库校验值为 `69641c2f9475717ab5ca459c94814aa2bab1d1fa7112fc6c3824b8d1544a3377`；
- 强制停止并重新冷启动后仍为 schema v4，未见 `AndroidRuntime`、`SQLiteLog` 或 Flutter 异常。

### 3.2 正式 gate UI

真实运行的正式 Provider 设置页 UI hierarchy 显示：

- 基准线与活动影响分别出现；
- 两个参数族均显示“先审核与自动应用将在真实使用验证完成后开放”；
- review / automatic 节点 `enabled=false`，content description 含“未开放”；
- 页面没有预生产水印。

本次 `flutter run` 只为模拟器临时调试安装，未执行 `flutter build apk`，未交付或安装最终 APK。

## 4. 已知边界与下一阶段

- 生成器对 schema 中 learning run 与 personalization 的双向外键报告合法的 circular reference
  warning；实际构建、SchemaVerifier 和全量测试均通过，不能移除任一方向的约束。
- 模拟器首次升级期间出现启动帧抖动日志；没有数据错误或崩溃，B2-1 继续观察 learner 接入后的
  prepare 时延。
- 真实自然数据、生产阈值和产品有效性仍未宣称通过；B2-1 只在明确隔离的预生产配置下接入
  baseline learner，正式 gate 继续关闭。
