# PowerManager Flutter App

PowerManager 的 Android Flutter 应用。

当前阶段：MVP-B B0-3 正确观测与活动反馈合同已通过，准备进入 B1-0。数据库保持 schema v2，
新观测、活动覆盖、活动绑定反馈和结算后资格判断已经可用；影子学习与生产自动学习保持关闭。

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
B0-3 Spec 及其验收记录为准，下一实现阶段以 B1-0 Spec 为准。
