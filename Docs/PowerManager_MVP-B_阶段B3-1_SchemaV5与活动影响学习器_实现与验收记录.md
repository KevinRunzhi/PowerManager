# PowerManager MVP-B 阶段 B3-1：Schema v5 与活动影响学习器实现与验收记录

## 1. 结论

- 工程结论：通过。
- 产品结论：`inconclusive`。learner 只在确定性 fixture 上生成带水印的 shadow candidate，未把 fixture 或主动反馈升级为真实生产证据。
- 数据库：schema v4 → v5 迁移、失败回滚、factor/sample 表、活动与反馈快照和 v5 备份往返已完成。
- 生产门：`activityImpactProductionLearningEnabled=false`、`activityImpactAutoApplyEnabled=false`；B3-2 之前不可达。
- 最终 APK 与实体手机：不在本阶段执行，延期到 MVP-B 总体验收。

## 2. 实现范围

1. Schema v5 增加 `personalization_activity_factors` 与 `activity_feedback_samples`，并为活动记录、反馈增加默认理论值、factor、个性化理论值、personalization version、factor regime、采样来源、策略版本、sample 时间和 sample ID 快照。
2. v4 → v5 迁移先做 preflight，重建活动/反馈表以保留检查约束；旧反馈复制为 `userInitiated`、factor `1.0`、无 sample，旧活动不回算、不切 regime；任一步失败完整回滚。
3. JSON v5 导出、导入、严格验证、备份恢复和业务计数覆盖 factors、samples 与新快照；恢复顺序满足版本 / learning run 外键，状态终态保持。
4. `ActivityFeedbackMaintenance` 在活动编辑、删除或重放导致快照变化时，同事务失效 active feedback 与非终态 sample；repository update 保持全部 v5 快照字段。
5. `ActivityImpactLearner` 只接受 settled、sampledPrompt、受支持 policy、responded sample、完整快照、当前 factor regime、未截断且 `applied == personalized` 的证据；userInitiated、旧 policy、未结算、零值、方向不符、截断、失效和旧 regime 均排除。
6. learner 按 `subcategory × impactSign` 独立聚合，执行最小样本 / 跨日门、directionMismatch veto、时长异质门和 factor 步长 / 范围门；stronger 只提高绝对影响、weaker 只降低绝对影响，输出 canonical、可重现的 factorBps candidate 与 evidence hash。
7. learner 结果为纯领域值，不写数据库、不注册 personalization version、不改变 baseline；生产开关关闭时 candidate 明确标记为不可执行 shadow candidate。

## 3. 自动化验收

- `test/data/db/schema_v5_migration_test.dart`：无反馈迁移、旧主动反馈来源复制、快照默认值、sample 空表和中途失败回滚。
- `test/data/db/schema_v2_migration_test.dart`、`schema_v4_migration_test.dart`：旧 v1/v2/v3/v4 bridge 回归，保持历史 DDL 与失败注入语义。
- `test/domain/learning/activity_impact_learner_test.dart`：主动反馈隔离、确定性候选、stronger/weaker/aboutRight、旧 regime、截断 / policy、directionMismatch veto、时长异质。
- `test/domain/learning/activity_impact_contract_test.dart`：抽样选择、状态转换、冷却、按键审计、calculator 与安全门。
- 现有 activity use case、Drift repository、JSON codec / restore、database initialization、readiness、data health 和 widget 回归保持通过。

## 4. 工程验证命令

已执行并通过：

```text
dart format（B3-1 touched Dart files）
flutter analyze lib
flutter test --reporter compact
git diff --check
```

全量结果：514 tests passed。

## 5. 模拟器 gate

- 设备：`emulator-5554`，Android 14 / API 34，Pixel_7 x86_64。
- 本阶段只允许 `flutter run -d emulator-5554 --debug --no-resident` 临时构建 / 安装验证；不执行
  `flutter build apk`，不生成或交付最终 APK，不操作实体手机。
- 需在提交前执行冷启动、首页、设置页和数据健康页非破坏性验证；默认 Provider 不构造活动影响生产配置，两个生产开关仍为 `false`。

## 6. 未验证与后续

- B3-2 负责 activityImpact review / automatic 的 candidate 注册、通知、取消、未来生效、快照实际使用、撤回和恶化暂停；本阶段不提前开启。
- 真实抽样负担、真实参数改善、真实通知理解和产品状态只能在最终安装后的自然数据中验证；数据不足时保持 `1.0`、`inconclusive` 和生产门关闭。
