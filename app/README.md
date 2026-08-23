# PowerManager Flutter App

PowerManager 的 Android Flutter 应用。

当前阶段：MVP-B B3-2 已完成活动影响 schema v5 兼容、持久 sample、factor learner、安全激活、撤回与
恶化暂停的工程实现、自动化与模拟器 gate，产品轨延期到最终安装后；B1 继续自动生成确定、幂等、只读的
审计运行，B2-1 已接入带 gate 的基准线生产 learner、review / automatic 候选生命周期、持久通知、取消和
未来撤回；B2-2 已接入新 epoch 监测、恶化暂停与恢复，但正式生产学习与自动应用仍保持关闭。

B3-0 已冻结带水印的活动影响按键审计、结果盲抽样、冷却、directionMismatch veto、时长异质门、倍率
范围/步长/取整和恢复上限合同；B3-1 已持久化 sample/feedback 快照并接入确定性 learner；B3-2 已接入
活动影响候选展示、安全激活、因子 regime、撤回和监测暂停。`activityImpactProductionLearningEnabled` 与
`activityImpactAutoApplyEnabled` 仍为 `false`，下一步为 MVP-B 总体验收。

## 常用命令

```powershell
flutter pub get
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run --profile -d emulator-5554
```

阶段内只用 `flutter run` 验证 Pixel_7 模拟器；最终 APK 仅在 MVP-B 总体验收构建和交付。

现有固定规则与精力计算继续以 `Docs/` 中的 v2 / MVP-A 文档为准；MVP-B 新增能力以 v3 总基线、
B1-1 工程决策包、B2-0 schema v4 决策、B2-1、B2-2、B3-0、B3-1 实现记录和 B3-2 活动影响安全激活与
监测 Spec 为准；总体验收以 `PowerManager_MVP-B_总体验收_Spec_v1.md` 为准。
