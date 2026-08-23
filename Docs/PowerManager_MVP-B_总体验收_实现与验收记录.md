# PowerManager MVP-B 总体验收：实现与验收记录

## 1. 记录状态

- 初始日期：2026-08-15
- 最近更新：2026-08-23
- 对象：MVP-B B0-0 至 B3-2 工程能力、Pixel_7 模拟器门与 V2359A 首次真机覆盖升级
- 当前结论：工程实现、自动化、模拟器、最终 Debug 构建和真实 schema v1 → v5 首次覆盖升级已通过；
  总验收仍需完成多生活日自然使用及其余真机矩阵
- baseline 产品状态：inconclusive
- activityImpact 产品状态：inconclusive
- 独立产品状态报告：`PowerManager_MVP-B_产品验证状态报告_v1.md`
- P0 直接证据审计：`PowerManager_MVP-B_P0直接证据审计_v1.md`
- 正式生产学习、baseline 自动应用、activityImpact 自动应用：均保持关闭

本记录不把隔离 fixture、预生产水印、模拟器行为或一次成功迁移写成真实产品效果。用户于
2026-08-23 授权进入最终 APK 和实体手机阶段；覆盖安装前已保存旧 APK、schema v1 数据库和匿名聚合，
没有清除应用数据。

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
| `flutter build apk --debug` | 通过；`app/build/app/outputs/flutter-apk/app-debug.apk`，版本 `0.1.4+10012`，SHA-256 `027B760DED14C317756590D6435167693F77AE353AE1698B9A62B1CB15DB245C` |
| `git diff --check` | 通过 |

2026-08-16 CST 追加复核：`flutter analyze` 通过；`flutter test --coverage` 仍为 525 项全通过；
`dart format --output=none --set-exit-if-changed lib test` 检查 159 个文件且 0 改动；
`dart run build_runner build --delete-conflicting-outputs` 完成 44 个生成输出且无工作树差异；
最终 `git diff --check` 通过。build_runner 提示当前版本忽略已移除的
`--delete-conflicting-outputs` 选项，未产生错误或生成文件漂移。

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

## 5. V2359A 首次真机覆盖升级证据

- 设备：V2359A，Android 16 / API 36，序列号仅在本地执行记录中使用。
- 覆盖前版本：`0.1.0+2002`；覆盖后版本：`0.1.4+10012`；包名均为
  `com.kevin.powermanager`，首次安装时间保持不变。
- 覆盖前旧 APK 与 schema v1 数据库保存到电脑外部目录
  `E:\PowerManagerBackups\20260823-104009`；数据库 SHA-256 为
  `CBB3DBDFAAF98E1AD9D1A7AFAAEBEB719AD576CC573E20829F63BE3F1478ABA1`，`integrity_check=ok`。
- 覆盖前匿名聚合：规则 1、晨间确认 9、活动 31、观测 2、日总结 10、提醒回执 5、设置 1。
- 新旧 APK 的签名证书 SHA-256 均为
  `506d87805d0ba8f1c1b8d173b0a92005638c85fd047984f9b180c21afd4fe8b1`。
- 流式安装因 Vivo 设备授权返回 `INSTALL_FAILED_ABORTED`，没有修改应用；用户解锁并授权后，标准
  `adb install --no-streaming -r -d` 覆盖安装成功，没有卸载或清数据。
- 首次冷启动后数据库 `user_version=5`，`integrity_check=ok`，`foreign_key_check` 无输出；原七表聚合
  与覆盖前完全一致。
- v5 新表初始化结果：1 个 `active` personalization version，learning run、notice、consent、activity
  factor/sample 均为 0，符合 legacy 数据不得自动获得学习资格的合同。
- 冷启动、迁移后再次拉起均成功；logcat 未发现应用 FATAL、Flutter 未处理异常、ANR 或数据库错误。
- 迁移后数据库快照已保存在同一外部备份目录，SHA-256 为
  `33D83B51445621A20D76BC09B45CA0AFAE5ACCC3FDD8A8EC4645B571289CBBAC`。

## 6. 尚未执行的总验收项

以下项目仍不在本轮假装通过：

1. 应用内 v5 JSON 备份、预览、恢复和恢复后再次启动；
2. 通知权限关闭、后台/恢复、系统重启、跨 04:00 生活日、TalkBack 和横屏人工矩阵；
3. 连续自然记录、真实 sampled feedback、抽样负担和两个参数族的产品状态；
4. 最终已知限制复核和总验收签收。

因此当前工程状态不能写成“自动学习已经证明有效”。真实产品结论仍为 inconclusive，生产门继续关闭；
一次成功覆盖迁移只证明升级安全路径，不证明学习算法改善了真实用户结果。

## 7. 后续入口

继续按 `PowerManager_MVP-B_总体验收_Spec_v1.md` 第 8～10 节完成剩余真机矩阵和自然观察。若真实
证据不足，仍保持 inconclusive，不为制造变化而打开生产门。
