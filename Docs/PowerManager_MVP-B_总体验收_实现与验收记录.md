# PowerManager MVP-B 总体验收：实现与验收记录

## 1. 记录状态

- 日期：2026-08-15
- 对象：MVP-B B0-0 至 B3-2 工程能力与 Pixel_7 模拟器门
- 当前结论：工程实现与自动化/模拟器证据已完成，最终总验收仍等待用户授权后的实体手机矩阵与交付构建
- baseline 产品状态：inconclusive
- activityImpact 产品状态：inconclusive
- 独立产品状态报告：`PowerManager_MVP-B_产品验证状态报告_v1.md`
- P0 直接证据审计：`PowerManager_MVP-B_P0直接证据审计_v1.md`
- 正式生产学习、baseline 自动应用、activityImpact 自动应用：均保持关闭

本记录不把隔离 fixture、预生产水印或模拟器行为写成真实产品效果。按照用户当前要求，本次不生成
交付 APK、不覆盖安装实体手机；`flutter run` 产生的 Debug APK 只作为模拟器启动载体，不是交付物。

## 2. 阶段与代码基线

阶段实现和独立验收记录已覆盖：B0-0、B0-1、B0-2、B0-3、B1-0、B1-1、B2-0、B2-1、B2-2、
B3-0、B3-1、B3-2。当前代码基线为 B3-2，最近安全修订提交为 `015632f`（前一轮活动闸门修订为
`67b829d`）。

追踪矩阵 `MVP-B_规则与实现追踪矩阵_v1.md` 已逐能力关联产品来源、算法/配置、代码、持久化、
测试和设备证据。B3-2 新增的 P0 重点如下：

| P0 | 直接实现与证据 | 结论 |
|---|---|---|
| 活动影响安全候选 | `ActivityImpactLearningCoordinator`、`ModelActivationService`、factor v5 表；learner、激活和备份校验测试 | 通过 |
| 活动影响展示与控制 | 设置页显示方向、倍率、抽样/覆盖、策略、排除和 mismatch 说明；候选操作与独立暂停恢复 UI 回归 | 通过 |
| 参数族串行 | shared pending slot、activity→baseline 与 baseline→activity 阻断；`baseline_production_coordinator_test.dart` 回归 | 通过 |
| 恶化保护 | activity monitoring evaluator/coordinator 只暂停 activity，不自动回滚；边界与 UI 测试 | 通过 |
| 生产门 | 正式 provider 使用 closed gate，未构造生产配置；活动/基准线写路径仅在显式隔离测试 gate 可达 | 通过 |

本轮总验收前修订还补齐了三项 P0 防线：automatic 模式必须同时打开
`activityImpactAutoApplyEnabled`，没有 responded sample 时 learning/monitoring 均零写入，且重复活动证据
不会重复计数；活动候选注册使用 activity-rule contract，并在激活前重验 evidence 快照、采样策略、父模型
和 factor regime。

## 3. 自动化验收

在 `app` 目录执行：

| 命令 | 结果 |
|---|---|
| `flutter pub get` | 通过；依赖锁定，无新增依赖 |
| `dart run build_runner build --delete-conflicting-outputs` | 通过；生成文件无工作树差异。Drift 报告的 learning_runs 循环外键警告与现有手写 v5 迁移真源一致，未产生错误输出 |
| `dart format --output=none --set-exit-if-changed lib test` | 通过；同时修正 5 个既有未格式化文件 |
| `flutter analyze` | 通过，No issues found |
| `flutter test --coverage` | 通过，525 tests passed；覆盖率文件已生成（含活动协调器闸门、零证据与幂等回归） |
| `git diff --check` | 通过 |

已有测试直接覆盖的总验收场景包括：v1→v2→v3→v4→v5 迁移和回滚、v1/v2/v3/v4/v5 备份往返、
foreign key/integrity/index/trigger、current/yesterday 隔离、结算与当前日排除、sample 展示/跳过/
响应/失效、baseline 与 activity review/automatic 生命周期、通知/取消/未来激活/撤回、恢复后不重复
运行、04:00 与重启准备、数据不足/noChange/unstable/config blocked、directionMismatch veto、
倍率边界和活动影响恶化暂停。

## 4. Pixel_7 模拟器证据

- `adb devices -l`：当前仅连接 `emulator-5554`，未操作实体手机。
- `flutter run -d emulator-5554 --debug --no-resident`：构建、安装、同步和启动成功。
- 本次启动对应提交 `015632f`，仅为模拟器 Debug 验证；没有执行交付 APK 构建或实体手机安装。
- 模拟器本轮增量安装首次因设备存储返回 `INSTALL_FAILED_INSUFFICIENT_STORAGE`，Flutter 随后卸载
  旧模拟器安装并完成干净安装、启动和同步；该操作只涉及 `emulator-5554`，不涉及实体手机。
- 本轮 logcat 未发现应用 FATAL、FlutterError、Unhandled、NoSuchMethodError 或 SQLite 数据库错误；
  `/data/user/0` 可用空间约 530 MB，存储告警作为模拟器环境限制记录。
- 启动日志未发现 `FATAL EXCEPTION`、`FlutterError`、`Unhandled`、`NoSuchMethodError` 或 SQLite 数据库错误。
- 仅有 Android/图形栈的正常 warning，以及一次与应用无关的 SQLite double-quoted literal warning；没有应用崩溃或 ANR。
- 追加模拟器验证（2026-08-16 CST）：临时设置系统字号 200%，当前提交实际构建、安装、启动成功；
  应用日志未发现 `FlutterError`、未处理异常、`RenderFlex overflow` 或数据库错误，验证后已恢复字号。
- 设置页 200% 字号、紧凑横屏、活动反馈和学习控制通过 widget 回归；活动影响暂停卡新增独立恢复回归。
- 本次尝试通过 AVD 系统旋转切换横屏未生效，因此不把它记录为横屏人工设备通过；横屏结论仅来自已有
  Widget 回归，待后续 AVD 能切换时再补人工矩阵。

## 5. 尚未执行的总验收项

以下项目按用户“整个 MVP 完成后再装手机”的要求保留，不在本轮假装通过：

1. `flutter build apk --debug` 的最终交付构建与 APK 路径签收；
2. 实体手机安装前版本/匿名聚合记录与外部备份；
3. 实体手机 schema v1 → v5 覆盖迁移、历史/模型/规则对比、自然记录和跨生活日观察；
4. 实体手机 v5 备份恢复、通知权限关闭、后台/重启、真实 sampled feedback 和两个参数族产品状态。

因此当前工程状态不能写成“自动学习已经证明有效”。真实产品结论仍为 inconclusive，生产门继续关闭；
在用户授权最终总验收前，不生成交付 APK、不安装或更新实体手机。

## 6. 后续入口

当用户确认 MVP-B 工程范围已冻结并允许最终总验收时，按
`PowerManager_MVP-B_总体验收_Spec_v1.md` 第 6～10 节先执行正式构建，再在手机外部备份和覆盖安装后
完成真机矩阵。若真实证据不足，仍保持 inconclusive，不为制造变化而打开生产门。
