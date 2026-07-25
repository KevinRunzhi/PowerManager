# PowerManager Flutter 环境布置 Spec v1

## 0. 目标

在不占用 C 盘主要空间、不移动现有 Android 环境的前提下，为 PowerManager 建立可复现的 Flutter Android 开发环境。

执行日期：2026-07-25

---

# 1. 单一新增目录

在 `E:\develop` 下只新增一个顶层目录：

```text
E:\develop\PowerManagerFlutter
```

内部布局：

```text
PowerManagerFlutter\
  flutter\              Flutter stable SDK
  cache\
    gradle\             Gradle 用户缓存
    pub\                Dart / Flutter Pub 缓存
  android-user\         Android 用户级配置
  downloads\            安装包临时保留位置
```

现有环境继续复用：

```text
Android Studio = E:\develop\Android Studio
Android SDK    = E:\develop\SDK
Android AVD    = E:\develop\Android\avd
```

不移动、不删除、不重新下载现有 Android SDK、模拟器和 Android Studio。

---

# 2. Flutter 安装来源

- 渠道：Flutter stable
- 来源：Flutter 官方 Windows SDK 发布包
- 发布元数据：Flutter 官方 releases JSON
- SDK 目录：`E:\develop\PowerManagerFlutter\flutter`

安装时记录实际 Flutter、Dart、Engine 版本和下载归档名称。

---

# 3. 用户环境变量

设置或更新：

```text
FLUTTER_ROOT=E:\develop\PowerManagerFlutter\flutter
GRADLE_USER_HOME=E:\develop\PowerManagerFlutter\cache\gradle
PUB_CACHE=E:\develop\PowerManagerFlutter\cache\pub
ANDROID_USER_HOME=E:\develop\PowerManagerFlutter\android-user
```

保留现有：

```text
ANDROID_HOME=E:\develop\SDK
ANDROID_SDK_ROOT=E:\develop\SDK
ANDROID_AVD_HOME=E:\develop\Android\avd
```

用户 `Path` 新增并去重：

```text
E:\develop\PowerManagerFlutter\flutter\bin
```

不得覆盖用户 Path 中的其他条目。

---

# 4. Flutter 配置

执行：

```text
flutter config --android-sdk E:\develop\SDK
flutter config --no-enable-web
flutter config --no-enable-windows-desktop
```

MVP-A 首阶段只面向 Android。关闭其他平台只减少无关 doctor 噪音，不影响以后重新开启。

---

# 5. 验证

必须执行：

```text
flutter --version
dart --version
flutter doctor -v
flutter doctor --android-licenses
flutter devices
flutter emulators
```

验收：

- Flutter 和 Dart 命令可运行。
- Flutter SDK 位于 E 盘目标目录。
- Android SDK 被识别为 `E:\develop\SDK`。
- Android Studio 和 Java 被识别。
- Android toolchain 无阻塞错误。
- 现有模拟器仍可被识别。
- C 盘没有新增 Flutter SDK 或大型 Gradle/Pub 缓存目录。

如果许可证需要人工输入，允许通过标准输入接受全部 Android SDK 许可证。

---

# 6. 安全与回退

- 目标目录存在时停止，不覆盖未知内容。
- 环境变量修改前记录原值。
- 安装失败时不删除现有 Android 环境。
- 回退只需要移除 `E:\develop\PowerManagerFlutter` 和本次新增的用户环境变量 / Path 条目。
- 本 Spec 不创建 Flutter 项目，不修改 PowerManager 业务代码。

---

# 7. 实际执行记录

执行结果：

```text
Flutter: 3.44.8 stable
Dart: 3.12.2 stable
DevTools: 2.57.0
Android SDK: 36.1.0
Android Platform: android-36.1
Android Build Tools: 36.1.0
Java: Android Studio JBR 21.0.10
```

官方归档：

```text
flutter_windows_3.44.8-stable.zip
SHA-256:
095c108a08e0377d8a6501fed65aeb288908a070ed3f135e525dc6431c7686e4
```

本地校验结果与官方 SHA-256 完全一致。

最终目录：

```text
E:\develop\PowerManagerFlutter
```

占用约 5.06 GB，其中包含保留在 `downloads` 内、约 1.61 GB 的已校验官方安装包。

环境验证：

- Flutter SDK 路径正确。
- Dart 命令可运行。
- Android SDK 和 Android Studio JBR 已识别。
- Android 许可证已全部接受。
- Android toolchain 通过 `flutter doctor -v`。
- 已识别现有模拟器 `Pixel_7` 和 `Pixel_Tablet_API_34`。
- 2026-07-25 已启动 `Pixel_7`，ADB 状态为 `device`，Flutter 识别为 `emulator-5554`（Android 14 / API 34）。
- 用户 Path 中 Flutter bin 只有一条。

环境变量修改后，需要重新打开终端和 Android Studio，现有进程才会读取新的用户环境。
