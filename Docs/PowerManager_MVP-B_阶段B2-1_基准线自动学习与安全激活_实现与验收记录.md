# PowerManager MVP-B 阶段 B2-1 实现与验收记录

## 1. 状态

- 阶段：B2-1 基准线自动学习与安全激活
- 文档版本：1.0
- 日期：2026-08-15
- 当前状态：代码、自动化与模拟器正式 gate 回归通过；预生产生命周期使用隔离自动化 harness 验证；生产门关闭
- 数据库：schema v4，无新增迁移
- 设备策略：本阶段只使用 Android 模拟器，不构建最终 APK，不操作实体手机

## 2. 已实现范围

### 2.1 纯生产学习器

- 新增 `BaselineProductionConfig` 与 `BaselineProductionLearner`。
- learner 只消费冻结 `ShadowEvidencePackage`，先重新绑定 production algorithm/config 身份，再调用
  无 IO 的 counterfactual replay；不会读取设置、写数据库或激活模型。
- 预生产阈值固定在显式测试输入：review 每窗 5 / 7、合计 10 / 14、最多 1 个反向；automatic
  每窗 6 / 7、合计 12 / 14、零反向；单步 2、anchor ±8、hard range 60～140、反事实改善各至少 1。
- run 的 `candidateValuesJson` 只保存 canonical `baseEnergy`，不把预生产水印写入持久数据。
- replay 的冻结证据校验同时兼容 B1 shadow identity 和重新身份化的 B2 production identity；ordinal
  差仍只用于方向和反事实比较，不换算为点数。

### 2.2 协调器与安全 gate

- `AutomaticLearningCoordinator` 保留 B1 shadow-only 路径，并在显式传入 B2 依赖时生成第二条 production
  run；off 模式零新 production run。
- production run 绑定当前 active personalization version，按 evidence hash / parent / 配置确定性幂等。
- engine、production learning、supported algorithm/config、suspension、cooldown、automatic auto-apply
  任一门关闭都会保存 `configurationBlocked`，不静默降级为变化。
- candidate 只在 run 已完成且 revalidation 通过后交给 `ModelActivationService`；review 原子写入
  awaitingReview + app notice，automatic 原子写入 scheduled + 24 小时通知；通知失败不会留下 schedule。
- 自动安排、生效前取消、生效后未来生活日撤回继续复用 B2-0 lifecycle，新 epoch 与历史快照不变。

### 2.3 用户界面

- 设置页新增候选详情卡：方向、当前/候选 base、单步、合格证据数、日期范围、referenceType、排除数。
- review 支持接受、稍后、重新打开、拒绝；automatic/review scheduled 支持生效前取消。
- learning run 激活后显示“撤回上一轮自动调整”，撤回只安排未来生活日并保留历史。
- 正式 gate 关闭时仍显示明确未开放状态；预生产 override 才显示工程水印。

## 3. 自动化验证

执行目录：`app`

```text
dart format
flutter analyze                         ✅
flutter test --coverage --reporter compact ✅ 492 tests passed
git diff --check                         ✅
```

新增永久测试：

- `test/domain/learning/baseline_production_learner_test.dart`：candidate、clean values、水印边界、配置阻断；
- `test/application/baseline_production_coordinator_test.dart`：review、automatic 24 小时排程、重复触发、
  engine gate blocked、notice 与 candidate 生命周期。

## 4. 模拟器与隔离预生产矩阵

隔离自动化 harness 已覆盖以下预生产生命周期：

1. review candidate → defer/reopen/reject/accept；
2. automatic schedule → notice → cancel → due activation；
3. 03:59 / 04:00 边界、重启、重复 prepare、恢复；
4. evidence insufficient / noChange / unstable / configurationBlocked；
5. 激活后撤回与历史引用冻结。

模拟器 `emulator-5554`（Android 14 / API 34，sdk gphone64 x86_64）使用当前代码完成正式 gate 回归：

- `flutter run -d emulator-5554 --debug --no-resident` 构建并安装临时 debug 调试产物；
- 冷启动 `LaunchState: COLD` 成功，进入设置页后可见“自动学习”、两个参数族“未开放”；
- 正式 gate 下无预生产水印、无候选写入入口；`adb logcat` 未发现 `FATAL EXCEPTION`、`FlutterError`、
  `Unhandled Exception` 或 `SQLiteLog`；
- 未发现实体手机，未执行 APK 交付或手机安装。

预生产 review/automatic 全生命周期由隔离数据库自动化 harness 验证，不把 fixture 写入模拟器正式数据库。
因此 B2-1 工程门通过；生产配置和实体手机仍保持关闭 / 延期。

## 5. 风险与非目标

- 正式 Provider 不构造预生产配置，当前正式 gate 仍为 closed；生产自然证据和最终参数仍未确认。
- 系统通知权限不是持久记录的前提；本阶段只保证 App 内 `learning_notices` 原子记录。
- 活动影响学习与调整后恶化监测不在 B2-1，分别由 B3 与 B2-2 实现。
