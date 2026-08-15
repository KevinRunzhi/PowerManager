# PowerManager MVP-B 阶段 B2-2：基准线调整后监测实现与验收记录

## 1. 结论

- 工程结论：通过。
- 隔离预生产结论：通过监测评估、冷却/不足证据、恶化暂停、恢复入口、通知幂等和参数族隔离。
- 模拟器结论：正式 gate 通过；只使用 Android 模拟器临时调试运行。
- 产品结论：`inconclusive`。尚未安装到实体手机，不能把 fixture 或模拟器结果写成真实改善。
- 生产门：`automaticLearningEngineEnabled=false`、正式生产配置为空、生产自动应用保持关闭。

## 2. 实现范围

1. `BaselineMonitoringEvaluator` 是无 IO 纯评估器，固定新 epoch 14 条 / 21 日 / 2×7，检查 aligned、预期反向计数、窗口边界和 ordinal error。
2. `BaselineMonitoringCoordinator` 只选择当前 active model regime 的新证据，不拼接旧 epoch；冷却、暂停和无证据时零写入或只返回报告；同一 evidence hash 幂等。
3. 评估为 `worsened` 时在同一事务中保存 monitoring learning run，并调用既有 `suspendLearning`：只暂停 baseline、失效同族 pending、不自动回滚 active、不改变 activityImpact。
4. 设置页显示暂停原因并提供手动恢复；恢复仍受正式 gate、模式和冷却约束。
5. 正式 Provider 默认返回 no-op requester；只有隔离预生产显式注入带水印配置才构造监测协调器。

## 3. 自动化验收

- `test/domain/learning/baseline_monitoring_test.dart`
  - 改善必须同时满足 aligned 至少 +2 和 absolute ordinal error 至少 -2；
  - 预期反向总数越界判定恶化；
  - 13 条或窗口不完整返回 `insufficientEvidence`。
- `test/application/baseline_monitoring_coordinator_test.dart`
  - 隔离数据库先完成 review 候选激活，再写入新 epoch 14×21 证据；
  - 恶化写入一次 monitoring run、暂停 baseline、保留 active=98、不影响 activityImpact；
  - 重复请求不重复 run 或 `learningSuspended` 通知。
- 既有 `model_activation_service_test.dart` 覆盖暂停/恢复事务、pending 失效和参数族隔离。

## 4. 工程验证命令

已执行并通过：

```text
dart format（全部 B2-2 touched Dart files）
flutter analyze
flutter test --reporter compact（全量）
flutter test test/domain/learning/baseline_monitoring_test.dart
flutter test test/application/baseline_monitoring_coordinator_test.dart
git diff --check
```

全量测试结果：496 tests passed（B2-1 基线为 492，新增 3 个纯评估测试 + 1 个协调器测试）。

## 5. 模拟器 gate

- 设备：`emulator-5554`，Android 14 / API 34，Pixel_7 x86_64。
- 使用 `flutter run -d emulator-5554 --debug --no-resident` 临时构建并安装验证；未执行
  `flutter build apk`，未生成或交付最终 APK。
- 冷启动、进入设置页和生产门关闭回归通过；默认 Provider 没有构造预生产监测配置，页面不显示
  生产水印或开放入口；最终 logcat 清理检查无 app `FATAL`、`FlutterError`、`Unhandled`、`SQLiteLog`。

## 6. 未验证与后续

- 实体手机自然观察、真实主观价值、真实通知负担和真实改善仍延期到 MVP-B 总体验收。
- B3-0 只能在本阶段产出的新 epoch / feedback 合同上分析 activityImpact，不能把 B2-2 fixture
  当作活动倍率证据。
