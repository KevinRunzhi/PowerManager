# PowerManager MVP-A 阶段 1：Flutter 工程骨架验收

## 0. 文档状态

- 阶段：1 / Flutter 工程骨架
- 执行日期：2026-07-26
- 依据：《PowerManager MVP-A 分阶段开发计划 Spec v1》第 5 节
- 结果：通过

---

# 1. 工程结果

```text
工程目录        E:\code\Project\PowerManager\app
Dart package    power_manager
Android app ID  com.kevin.powermanager
Android label   精力值
最低 SDK         flutter.minSdkVersion / API 24
目标平台         Android
Android 语言     Kotlin
```

Flutter 工程只生成 Android 平台目录，保留 Flutter 3.44.8 模板提供的 Gradle、AGP、Kotlin、SDK 和 NDK 兼容配置，没有手工升级生成版本。

---

# 2. 已建立的骨架

```text
lib/
  app/
    app.dart
    app_routes.dart
    theme/
  core/time/
  data/
    db/
    repositories/
  domain/
    energy/
    life_day/
  application/
  features/
    debug/presentation/
    home/presentation/
  shared/widgets/
test/
  widget/
```

实现内容：

- `ProviderScope` 包裹根应用；
- Material 3 深色主题和第一版语义化设计令牌；
- Flutter 原生命名路由；
- 静态首页骨架；
- 晨间提示、弱光能量球、“+”占位入口和底部工具带；
- Debug 阶段标识和环境信息占位页；
- 空 Drift 数据库生成入口；
- 竖屏、路由和紧凑横屏 Widget 测试。

阶段 1 不包含领域计算、真实记录、持久化表或复杂动效。

---

# 3. 依赖基线

运行依赖：

```text
flutter_riverpod 3.3.2
drift            2.34.2
drift_flutter    0.3.1
```

开发依赖：

```text
drift_dev   2.34.0
build_runner 2.15.1
flutter_lints 6.0.0
```

依赖决策：

- 不启用 Riverpod codegen；
- 不加入 Freezed 和 go_router；
- 使用 `drift_flutter` 提供 Flutter/SQLite 打开能力；
- 不直接加入已进入 EOL 占位状态的 `sqlite3_flutter_libs`；
- Drift Manager API 与 DAO/Repository 架构重复，因此通过 `build.yaml`
  设置 `generate_manager: false`。

---

# 4. 测试发现与修复

## 4.1 空 Drift 生成代码分析警告

问题：空表数据库默认生成 Manager API，其中 `_db` 在没有表时未使用，导致
`flutter analyze` 报警告。

处理：不修改生成文件，不虚构临时业务表；关闭项目不使用的 Manager API 生成。

结果：代码生成成功，`flutter analyze` 无问题。

## 4.2 当前进程没有继承 E 盘环境变量

问题：Codex 进程早于用户环境变量修改启动，初次 Android 构建没有继承
`GRADLE_USER_HOME`、`PUB_CACHE`，直接调用 Gradle 时还会继承旧 JDK 8。

处理：本次及后续当前任务中的 Flutter/Gradle 命令显式注入：

```text
GRADLE_USER_HOME  E:\develop\PowerManagerFlutter\cache\gradle
PUB_CACHE         E:\develop\PowerManagerFlutter\cache\pub
JAVA_HOME         E:\develop\Android Studio\jbr
ANDROID_USER_HOME E:\develop\PowerManagerFlutter\android-user
```

结果：Gradle 9.1、Pub 和 Android 用户缓存均实际写入 E 盘，构建使用 JBR 21。

## 4.3 NDK 安装不完整

问题：`E:\develop\SDK\ndk\28.2.13676358` 只有 `.installer`，缺少
`source.properties`，AGP 报 `CXX1101`。

处理：

1. 验证目标严格位于 `E:\develop\SDK\ndk`；
2. 将异常目录移动为
   `E:\develop\SDK\ndk\28.2.13676358.malformed-20260726`；
3. 使用 Android `sdkmanager` 重新安装 NDK 28.2.13676358；
4. 验证 `Pkg.Revision = 28.2.13676358`。

结果：APK 构建通过。异常旧目录保留为可恢复备份，没有直接删除。

## 4.4 紧凑横屏溢出

问题：能量球只根据屏幕宽度计算，在 640×360 视口下纵向溢出 81px。

处理：球体直径同时受宽度和高度约束；低矮视口最小为 132dp，普通 Pixel_7
竖屏尺寸保持不变。

结果：紧凑横屏 Widget 回归测试通过。

## 4.5 Debug 冷启动跳帧

首次安装和 Debug 冷启动出现模拟器 Choreographer 跳帧提示。保留进程后的 hot
launch 为 339ms，应用自身 PID 没有 Flutter 异常或布局错误。

该现象当前归类为 Debug/JIT 启动开销，不作为阶段 1 阻塞项。能量球复杂动效和
60fps 验收必须在后续阶段使用 profile 模式和真机重新验证，不能引用本阶段结果替代。

---

# 5. 验证证据

## 5.1 自动化

```text
dart run build_runner build  通过
dart format check            通过，0 个文件需要修改
flutter analyze              通过，No issues found
flutter test                 通过，3/3
flutter build apk --debug    通过
```

Widget 测试覆盖：

1. `ProviderScope` 与首页启动；
2. 原生命名路由构建 Debug 页面；
3. 640×360 紧凑横屏无 RenderFlex 溢出。

## 5.2 Android 集成

```text
APK     build\app\outputs\flutter-apk\app-debug.apk
设备    emulator-5554 / Pixel_7 / Android 14 API 34
包名    com.kevin.powermanager
前台    com.kevin.powermanager/.MainActivity
Impeller OpenGLES
```

最终缓存完成后，Debug APK 重建耗时约 35 秒；交互式 `flutter run` 构建耗时约
25 秒。

## 5.3 热重载

交互式 Flutter 会话发送 `r` 后收到：

```text
Reloaded 0 libraries in 757ms
```

Hot reload 验收通过。

## 5.4 视觉检查

Pixel_7 模拟器截图已检查：

- 深色单画布正常；
- 晨间提示、能量球、“+”和底部工具带完整；
- SafeArea 正常；
- 无 RenderFlex overflow；
- 无 `E/flutter` 或未处理异常。

截图保存在环境日志目录：

```text
E:\develop\PowerManagerFlutter\logs\powermanager-stage1.png
```

---

# 6. 验收结论

| 验收项 | 结果 |
|---|---|
| Android-only Flutter 工程可运行 | 通过 |
| 应用身份与阶段 0 参数一致 | 通过 |
| ProviderScope 正确包裹 | 通过 |
| 原生路由首页可构建 | 通过 |
| Drift 生成器可运行 | 通过 |
| 设计令牌与静态首页骨架存在 | 通过 |
| Pixel_7 安装与启动 | 通过 |
| 紧凑横屏无溢出 | 通过 |
| Hot reload 可用 | 通过 |
| `flutter analyze` 无问题 | 通过 |
| `flutter test` 全部通过 | 通过 |
| Debug APK 可构建 | 通过 |

阶段 1 退出条件已满足。提交本阶段后可以进入阶段 2：领域规则与纯算法。
