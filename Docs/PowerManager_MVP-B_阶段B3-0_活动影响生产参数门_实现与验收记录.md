# PowerManager MVP-B 阶段 B3-0：活动影响生产参数门实现与验收记录

## 1. 结论

- 工程结论：通过。
- 产品结论：`inconclusive`。本阶段没有把 fixture 或 userInitiated 反馈升级为生产证据。
- 数据库：保持 schema v4；没有提前迁移、创建 factor 表或改变活动历史。
- 生产门：`activityImpactProductionLearningEnabled=false`、`activityImpactAutoApplyEnabled=false`。
- 最终 APK 与实体手机：不在本阶段执行，延期到 MVP-B 总体验收。

## 2. 实现范围

1. `ActivityImpactKey` 以 `subcategory|impactSign` 稳定隔离 consumption、recovery 和 zero。
2. `ActivityImpactFeasibilityAudit` 汇总 userInitiated 研究数据与 sampledPrompt 资格数据，记录跨日、方向、
   invalidated、零理论值、恢复截断、规则版本和时长，不把主动反馈转换为生产证据。
3. `ActivityImpactSamplingPolicyV1` 固定预生产水印、支持规则版本、每日 1 条上限、跳过 1 日和未响应 3 日冷却，
   并保持两个生产开关关闭。
4. `ActivityImpactSampler` 只读取模式、当前日合格活动和 sample 状态，用 policy/day/activity ID 的 SHA-256
   排序选择；不读取反馈方向、预测误差、详情打开或投诉。
5. `ActivityImpactSampleState` 约束 selected → prompted/responded/skipped/expired/invalidated 的终态转换，
   跳过不创建伪 feedback，invalidated 不占日上限。
6. `ActivityImpactFactorGate` 固定最小 sampledPrompt 观察门（8 条、4 日）、directionMismatch veto（至少 2 条且
   占比 >=25%）、时长跨度 60 分钟和规则/零值/截断安全门。
7. `ActivityImpactFactorCalculator` 明确正倍率范围 `[0.50, 1.50]`、步长 `0.05`、先取整再应用恢复上限，
   乘数不跨 0。

## 3. 自动化验收

`test/domain/learning/activity_impact_contract_test.dart` 覆盖：

- userInitiated 与 sampledPrompt 来源隔离；invalidated、zero、recovery truncation 仅进入审计；
- off 模式零提示、daily cap、跳过/未响应冷却；
- 重启重复调用稳定、invalidated 与旧 policy 独立；
- 活动资格过滤、方向 mismatch veto、时长异质、最小样本/跨日门；
- factor 取整、恢复 ceiling、zero 与越界倍率拒绝。

## 4. 工程验证

已执行并通过：

```text
dart format --output=none --set-exit-if-changed lib/domain/learning/activity_impact_contract.dart test/domain/learning/activity_impact_contract_test.dart
flutter analyze
flutter test --coverage --reporter compact
git diff --check
flutter run -d emulator-5554 --debug --no-resident
```

全量结果：506 tests passed；B2-2 基线为 496，新增 B3-0 纯领域合同测试 10 项。

模拟器设备为 `emulator-5554`（Android 14 / API 34 / Pixel_7 x86_64）。临时 debug run 成功构建并安装，
冷启动、首页和设置页可用；设置页显示两个参数族为“未开放”，未出现 B3 生产入口或水印配置。最后
logcat 扫描无 app `FATAL EXCEPTION`、`FlutterError`、`Unhandled` 或 `SQLiteLog`。本次只是模拟器临时
调试运行，不是最终 APK 构建或交付。

## 5. 未验证与后续

- schema v5、持久 sample、活动 learner 和版本化 factor 迁移属于 B3-1；B3-0 不提前写数据库。
- review/automatic 活动影响安全激活、串行、撤回和恶化暂停属于 B3-2。
- 真实抽样负担、真实参数改善和产品状态只能在最终安装后的自然数据中验证；数据不足时保持 `1.0`、
  `inconclusive` 和生产门关闭。
