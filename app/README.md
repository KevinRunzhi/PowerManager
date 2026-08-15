# PowerManager Flutter App

PowerManager 的 Android Flutter 应用。

当前阶段：MVP-B B1-1 工程决策轨已通过，准备进入 B2-0。数据库仍为 schema v3，会自动生成
确定、幂等、只读的审计运行；离线反事实只使用强水印测试配置，候选、个人模型、生产学习和
自动应用仍保持关闭。

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
B1-1 工程决策包为准，下一阶段以 B2-0 Spec 与 schema v4 最终迁移决策为准。
