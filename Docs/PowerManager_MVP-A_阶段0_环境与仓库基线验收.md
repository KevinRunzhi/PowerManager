# PowerManager MVP-A 阶段 0：环境与仓库基线验收

## 0. 文档状态

- 阶段：0 / 环境与仓库基线
- 执行日期：2026-07-26
- 开发分支：`mvp-a-flutter-foundation`
- 依据：《PowerManager MVP-A 分阶段开发计划 Spec v1》第 4 节
- 结果：通过

---

# 1. 工程创建参数

阶段 1 使用以下固定参数：

```text
仓库目录        E:\code\Project\PowerManager
Flutter 工程    E:\code\Project\PowerManager\app
Dart package    power_manager
Android app ID  com.kevin.powermanager
应用显示名       精力值
目标平台         Android
Android 语言     Kotlin
最低 SDK         API 24
```

最低 SDK 沿用 Flutter 3.44.8 当前模板的 `flutter.minSdkVersion`。本机
`FlutterExtension.kt` 中的默认值为 24；阶段 1 不手工降低该值。

Flutter 工程使用 `app/` 子目录，因此不会覆盖仓库根目录的 `Docs/`、参考原型和历史文件。

---

# 2. 工具链实测

```text
Windows             Windows 11 家庭版 25H2
Flutter             3.44.8 stable
Flutter revision    058e0af2c2
Engine revision     0cd610717b
Dart                3.12.2
DevTools            2.57.0
Android SDK         36.1.0
Android platform    android-36.1
Android build-tools 36.1.0
Android emulator    36.5.10
Java                Android Studio JBR 21.0.10
验证设备            Pixel_7 / emulator-5554 / Android 14 API 34
```

`flutter doctor -v` 结果：

- Android toolchain：通过；
- Android licenses：全部接受；
- Connected device：通过；
- Network resources：通过；
- 唯一提示为当前 Codex 进程未重新载入用户 `Path`，不是工具链阻塞项；
- 用户级 `Path` 已配置 Flutter bin，重新打开终端后生效；
- 本阶段及后续自动验证使用 Flutter SDK 的绝对路径，避免旧进程环境造成歧义。

---

# 3. E 盘目录确认

```text
FLUTTER_ROOT      E:\develop\PowerManagerFlutter\flutter
GRADLE_USER_HOME  E:\develop\PowerManagerFlutter\cache\gradle
PUB_CACHE         E:\develop\PowerManagerFlutter\cache\pub
ANDROID_USER_HOME E:\develop\PowerManagerFlutter\android-user
ANDROID_HOME      E:\develop\SDK
ANDROID_SDK_ROOT  E:\develop\SDK
ANDROID_AVD_HOME  E:\develop\Android\avd
```

Flutter、Gradle、Pub、Android 用户数据和 AVD 的主要开发目录均位于 E 盘。

---

# 4. 仓库保护

- 开工前工作区包含前期产品文档、技术文档和设计原型改动；
- 阶段 0 不删除、不回滚这些内容；
- `.idea/` 属于本机 IDE 状态，已加入忽略列表；
- 根目录与 `prototypes/` 中存在哈希相同的 HTML 小样；正式文档只引用
  `prototypes/PowerManager_动效小样.html`，阶段 0 不擅自删除根目录副本；
- Flutter 工程目标 `app/` 在创建前不存在。

---

# 5. 可重复验证命令

在当前未重新载入用户环境变量的进程中使用绝对路径：

```powershell
& 'E:\develop\PowerManagerFlutter\flutter\bin\flutter.bat' --version
& 'E:\develop\PowerManagerFlutter\flutter\bin\flutter.bat' doctor -v
& 'E:\develop\PowerManagerFlutter\flutter\bin\flutter.bat' devices
& 'E:\develop\Android Studio\jbr\bin\java.exe' -version
```

工程创建后，阶段 1 增加：

```powershell
flutter analyze
flutter test
flutter build apk --debug
flutter run -d emulator-5554
```

---

# 6. 验收结论

| 验收项 | 证据 | 结果 |
|---|---|---|
| Android toolchain 可用 | `flutter doctor -v` 通过 | 通过 |
| Pixel_7 可识别 | `flutter devices` 返回 `emulator-5554` | 通过 |
| 环境 Spec 与实际版本一致 | 版本、SDK、JDK 和目录逐项核对 | 通过 |
| 工程目标目录明确 | `app/` | 通过 |
| applicationId 明确 | `com.kevin.powermanager` | 通过 |
| 最低 SDK 明确 | Flutter 3.44.8 默认 API 24 | 通过 |
| 不覆盖现有文件 | `app/` 创建前不存在 | 通过 |

阶段 0 退出条件已满足，可以在提交本阶段基线后进入阶段 1。
