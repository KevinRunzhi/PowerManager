# PowerManager Flutter App

PowerManager 的 Android Flutter 应用。

当前阶段：MVP-B B0-2 schema v2 与备份兼容已通过，准备进入 B0-3。数据库为 schema v2，
新观测合同和活动反馈只具备存储与备份基础；生产自动学习保持关闭。

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

现有记录与精力计算继续以 `Docs/` 中的 v2 / MVP-A 文档为准；MVP-B 新增能力以 v3 总基线、
`PowerManager_MVP-B_阶段B0-2_SchemaV2与备份兼容_Spec_v1.md` 和下一阶段 B0-3 Spec 为准。
