# PowerManager Flutter App

PowerManager 的 Android Flutter 应用。

当前阶段：MVP-B B2-1 已完成代码与自动化验收，待模拟器矩阵后进入 B2-2。数据库保持 schema v4；
B1 继续自动生成确定、幂等、只读的审计运行，B2-1 已接入带 gate 的基准线生产 learner、review /
automatic 候选生命周期、持久通知、取消和未来撤回，但正式生产学习与自动应用仍保持关闭。

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
B1-1 工程决策包、B2-0 schema v4 决策和 B2-1 实现记录为准，下一阶段以 B2-2 调整后监测 Spec 为准。
