# PowerManager Flutter App

PowerManager 的 Android Flutter 应用。

当前阶段：MVP-B B0-1 迁移准备版已通过，准备进入 B0-2。数据库仍为 schema v1，生产自动
学习保持关闭。

## 常用命令

```powershell
flutter pub get
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter run -d emulator-5554
```

现有记录与精力计算继续以 `Docs/` 中的 v2 / MVP-A 文档为准；MVP-B 新增能力以 v3 总基线
和 `PowerManager_MVP-B_阶段B0-1_迁移准备版_Spec_v1.md` 为准。
