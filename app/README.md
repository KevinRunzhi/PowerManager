# PowerManager Flutter App

PowerManager 的 Android Flutter 应用。

当前阶段：MVP-B B2-0 已完成工程验收，准备进入 B2-1。数据库已升级到 schema v4；B1
继续自动生成确定、幂等、只读的审计运行，B2-0 已建立不可变个人模型、候选生命周期、备份恢复
和两个参数族模式，但正式生产学习与自动应用仍保持关闭。

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
B1-1 工程决策包和 B2-0 schema v4 决策为准，下一阶段以 B2-1 Spec 接入基准线 learner 为准。
