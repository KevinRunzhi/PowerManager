# PowerManager MVP-A 阶段 19：生活日刷新与交互数据安全加固实现与验收记录

## 0. 文档状态

- 日期：2026-08-14
- 对应 Spec：`PowerManager_MVP-A_阶段19_生活日刷新与交互数据安全加固_Spec_v1.md`
- 实现基线：`ee9a908 feat: complete stage 18 energy orb upgrade`
- Flutter：3.44.8 stable
- Dart：3.12.2
- 状态：实现与自动化验收完成；Pixel_7 手工验收因 ADB offline 待补
- 真实使用状态：连续七日观察待执行，不计入本次自动化通过

---

# 1. 实施结果

## 1.1 生活日刷新

- 新增带 `revision` 和 `PreparationTrigger` 的统一刷新请求；
- `currentPreparationProvider` 的初始触发改为 `coldStart`；
- 根 App 不再直接调用第二次 `OperationPreparer.prepare`；
- resumed 时刷新同一 Provider，首页会消费新的投影而不是丢弃准备结果；
- 新增 `lifeDayBoundary` 触发原因；
- App 仅在 resumed 前台安排下一本地 04:00 Timer，离开前台即取消；
- Timer 到期后刷新当前生活日、清除旧提醒并重新安排下一边界；
- `appSettingsProvider` 同步监听刷新请求，使跨生活日生效的待定基准线更新；
- Debug 阶段标识与 App README 已从 Stage16 对齐到 Stage19。

## 1.2 凌晨完成时间

- `LifeDayCalculator` 新增 `nextBoundaryAfter` 纯函数；
- 新增无 Flutter 依赖的 `CompletionTimeResolver`；
- 00:00～03:59 选择 23:00 时会解析为上一日 23:00；
- 未来时间与其他生活日分别返回类型化失败；
- 月末、年末和当前分钟秒数均有测试；
- Activity Sheet 的默认时间、预设、自定义时间和操作 ID 使用注入 `Clock`；
- 无效自定义选择会保留错误并禁用提交，不能误保存旧时间。

## 1.3 活动删除恢复与统一撤销

- `ActivityMutator` / `ActivityUseCases` 新增 `restore(activityId)`；
- restore 继续经过生活日准备、当前日/结算检查、串行队列和 Drift 事务；
- 恢复保留原 ID、创建/完成时间、分类、时长、理论变化和规则版本；
- 恢复后清空 `deletedAt`、更新 `updatedAt` 并完整重放受恢复上限影响的变化；
- 重复恢复 active 记录幂等，不重复插入；
- 活动删除后显示 5 秒撤销，点击后调用 restore；
- 创建撤销与删除撤销共用同一反馈函数和 ScaffoldMessenger 队列；
- 显式设置 `SnackBar.persist = false`，确保新版 Flutter 中带 Action 的反馈仍按 5 秒结束；
- 移除平行关闭 Timer，窗口从实际显示开始；
- 全局撤销状态改为引用计数，混合队列全部结束后才允许低精力提醒；
- 撤销失败显示安全文案，不输出内部异常。

## 1.4 此刻校正

- 保存中禁用三个选择、阻止关闭并显示进度；
- 当前选择有高亮与选中语义；
- 失败在 Sheet 内显示 live-region 错误，保留 Sheet 和选择；
- Sheet 改为可滚动并允许全高约束，避免横屏/错误状态溢出；
- 成功 Snackbar 包含具体选择语义并使用 live region；
- 观测 ID 使用注入 `Clock`。

## 1.5 备份一致性与临时文件

- `JsonExportService` 注入 `TransactionRunner`；
- 设置和七类业务数据在同一数据库事务内顺序读取；
- DTO 转为纯 JSON Map 后，以只捕获可发送对象的独立任务进入 `Isolate.run`；
- 避免编码闭包意外捕获 Drift 数据库连接；
- 当前恢复预览计数也改为事务一致读取；
- 恢复外层事务覆盖“生成安全副本 → 原子保存 → 完整替换”；
- 现有 Drift 版本的嵌套事务已通过成功与安全副本失败测试；
- 新增 `TemporaryExportFileStore`，分享结束后在 `finally` 尽力清理临时 JSON；
- 临时清理失败只报告 Flutter 错误，不反转已经完成的分享结果；
- 设置页基准线保存、本机备份、临时导出和恢复使用统一互斥忙碌状态。

数据表、数据库 schemaVersion、JSON schemaVersion、七类 DTO 和能量规则均未改变。

---

# 2. 自动化验收

## 2.1 格式与静态分析

在 `app/` 执行：

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

结果：格式检查通过；`flutter analyze` 为 `No issues found`。

## 2.2 全量测试

执行：

```text
flutter test
```

结果：202 项全部通过。Stage18 基线为 183 项，本阶段净增加 19 项回归覆盖。

新增或扩展覆盖包括：

- 04:00 前、恰好边界、边界后、月末与年末；
- 凌晨 23:00 映射、未来拒绝、跨生活日拒绝；
- 冷启动单次准备、resumed 消费新投影、前台边界刷新；
- 删除后恢复、字段保持、完整重放、幂等、缺失和已结算拒绝；
- 删除撤销、5 秒自动结束、撤销引用计数；
- 此刻校正失败保留选择与成功语义；
- 一致导出事务调用、Isolate 可发送边界；
- 安全副本失败不替换、成功安全副本与完整替换；
- 临时 JSON 写入、删除和重复删除。

## 2.3 覆盖率

执行：

```text
flutter test --coverage
```

排除 `app_database.g.dart` 后：

- 纳入文件：60；
- 可执行行：4860；
- 命中行：3795；
- 行覆盖率：78.1%。

Stage18 同口径为 76.7%，本阶段提升 1.4 个百分点。

## 2.4 Android 构建

执行：

```text
flutter build apk --debug
```

结果：成功生成 `app/build/app/outputs/flutter-apk/app-debug.apk`，文件大小 188,159,237 字节。

---

# 3. Pixel_7 模拟器验收状态

当前机器存在 `Pixel_7` AVD。2026-08-14 尝试启动后：

1. `flutter emulators --launch Pixel_7` 能拉起 emulator 进程；
2. `adb devices` 在 50 秒等待后仍显示 `emulator-5554 offline`；
3. 执行一次 `adb reconnect offline` 后状态未恢复；
4. `emulator.exe` 响应，但 `qemu-system-x86_64.exe` 显示无响应；
5. 已停止本次启动的挂起 emulator / QEMU 进程，未安装 APK、未修改模拟器业务数据。

因此本记录不声明 Pixel_7 手工验收通过。以下场景待设备恢复后补验：

- 首页正常启动与 Stage19 Debug 标识；
- 活动删除 → 撤销恢复 → 再删除等待超时；
- 此刻校正成功反馈与失败可滚动状态；
- 前后台恢复刷新；
- 分享 JSON 后临时缓存清理；
- 本机备份、恢复预览和恢复前安全副本。

03:59 → 04:00 与凌晨 23:00 的精确边界已由注入时钟的纯逻辑和 Widget 测试覆盖；模拟器
补验不通过篡改真实用户数据来伪造七日结果。

---

# 4. 验证中发现并修复的问题

1. 事务导出重构后，`Isolate.run` 闭包曾捕获完整 `JsonExportService`，导致 Drift 连接不可发送；
   改为只携带纯 JSON Map 的 `_JsonEncodingTask` 后通过真实 SQLite 测试。
2. 当前 Flutter 中带 Action 的 Snackbar 默认可持久显示；显式 `persist: false` 后 5 秒窗口
   Widget 测试通过。
3. 此刻校正失败增加错误行后，默认半高 Bottom Sheet 在紧凑高度溢出 13px；改为
   `isScrollControlled` + `SingleChildScrollView` 后回归通过。
4. 生命周期边界测试原先依赖上一测试留下的 resumed 状态；测试现在显式设置生命周期，单独
   运行和全量运行均通过。

---

# 5. 未完成项与风险

- Pixel_7 手工验收因本地 AVD / ADB offline 待补；
- 未做真机验收，继续遵循既有“整个 MVP-B 后统一真机验收”决定；
- 连续七日真实使用和“每日实际状态至少 4 日”尚未发生，不能由测试替代；
- 发布签名、CI、历史分页和结算增量扫描不属于 Stage19；
- Debug APK 使用开发构建流程，不作为正式发布包。

---

# 6. 阶段结论

Stage19 规格中的代码实现、自动化测试、覆盖率和 debug APK 构建已经完成。当前状态可作为
独立工程基线提交，但阶段的 Pixel_7 手工验收和七日真实产品观察仍明确待补。下一步应先修复
本地 AVD/ADB 状态并补做非破坏性模拟器验收，再依据真实七日覆盖决定 Stage17-B、规则调整或
MVP-B，不以本阶段自动化通过替代产品有效性证据。
