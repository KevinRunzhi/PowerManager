# PowerManager MVP-B P0 直接证据审计 v1

## 0. 审计范围与结论

- 日期：2026-08-15
- 范围：B0-0 至 B3-2 的 P0 工程不变量、自动化测试和 Pixel_7 模拟器证据。
- 证据规则：只有代码路径、持久化合同、正式测试和设备结果同时可定位，才记为工程通过；fixture
  或模拟器不能替代真实自然数据，也不能替代实体手机覆盖迁移。
- 工程侧结论：自动化与 Pixel_7 模拟器门通过；最终总验收仍未执行实体手机矩阵和交付构建。
- 产品侧结论：baseline 与 activityImpact 均为 `inconclusive`；生产学习和两个自动应用门保持关闭。

## 1. P0 逐项证据

| P0 要求 | 权威代码 | 持久化 / Schema 证据 | 自动化证据 | Pixel_7 设备证据 | 工程状态 | 未验证限制 |
|---|---|---|---|---|---|---|
| v1→v5 无损迁移、失败回滚、完整性约束 | `app/lib/data/db/app_database.dart`、迁移实现 | v2/v3/v4/v5 Drift 表、索引、触发器与 `foreign_key_check` | `schema_v2_migration_test.dart`、`schema_v4_migration_test.dart`、`schema_v5_migration_test.dart`、`database_constraints_test.dart` | 当前提交 Debug 冷启动成功、无 SQLite 错误 | 通过 | 实体手机真实 schema v1 覆盖安装尚未执行 |
| v1/v2/v3/v4/v5 备份可恢复且不重复激活 | `JsonBackupCodec`、`JsonBackupRestoreService`、`LocalBackupService` | backup codec allowlist、可恢复原子文件、v5 factor/sample 快照 | `json_backup_codec_test.dart`、`json_backup_codec_v4_test.dart`、`json_backup_restore_service_test.dart`、`backup_restore_test.dart`、`recoverable_atomic_text_file_test.dart` | 设置页与 Debug 启动回归通过 | 通过 | 手机外部备份、恢复过期 schedule 尚未执行 |
| 当前生活日与历史/昨日证据隔离 | `CurrentDayProjector`、`AutomaticLearningCoordinator`、`LearningEligibilityService` | observation `lifeDay`、summary/referenceType、learning evidence hash | `current_day_projector_test.dart`、`shadow_learning_test.dart`、`automatic_learning_coordinator_test.dart`、`life_day_calculator_test.dart` | 04:00 与首页相关 Widget 回归通过 | 通过 | 连续自然跨生活日仍需手机观察 |
| legacy observation 与 userInitiated feedback 不得进入生产学习 | `LearningEligibilityService`、`ActivityImpactLearningCoordinator` | feedback source/status、v5 迁移保留 `userInitiated` | `learning_eligibility_service_test.dart`、`schema_v5_migration_test.dart`、`activity_impact_learner_test.dart` | 活动反馈页面启动与回归通过 | 通过 | 真实用户反馈分布尚未形成 |
| 同一证据确定性、重试幂等、无新证据零写入 | `AutomaticLearningCoordinator`、`ActivityImpactLearningCoordinator` | `learning_runs` idempotency key、immutable result/hash | `automatic_learning_coordinator_test.dart`、`activity_impact_learning_coordinator_test.dart`、`canonical_json_test.dart` | 当前 Debug 启动日志无异常 | 通过 | 尚未在实体手机执行后台/重启后的重复运行矩阵 |
| 模型版本唯一 active、全局 pending、历史冻结 | `ModelActivationService`、`PersonalizationLifecycle` | `personalization_versions` v4/v5 约束、active/pending 唯一性 | `personalization_lifecycle_test.dart`、`model_activation_service_test.dart`、`database_constraints_test.dart` | 设置页模型控制回归通过 | 通过 | 真机迁移后的现有历史对比尚未执行 |
| baseline 的 off/review/automatic 与生产门隔离 | `BaselineProductionLearner`、`BaselineProductionCoordinator`、`AutomaticLearningCoordinator` | baseline personalization version、notice、pending rule | `baseline_production_learner_test.dart`、`baseline_production_coordinator_test.dart`、`baseline_shadow_replay_test.dart`、`json_backup_codec_v4_test.dart` | 模拟器正式 gate 启动无生产写入 | 通过 | baseline 真实生产阈值和自然效果尚未验证，门保持关闭 |
| automatic 必须通知、可取消、未来生效且可撤回 | `ModelActivationService`、`LearningNotice`、设置页操作 | learning notice、scheduled/active/reverted version 状态 | `model_activation_service_test.dart`、`json_backup_codec_v4_test.dart`、相关 Widget 回归 | 模拟器设置页生命周期回归通过 | 通过 | 手机通知权限、真实通知到达和用户取消尚未验证 |
| 恶化监测只暂停对应参数族，不静默继续变化 | `BaselineMonitoringEvaluator/Coordinator`、`ActivityImpactMonitoringEvaluator/Coordinator` | monitoring run、pause/cooldown 状态、族字段 | `baseline_monitoring_test.dart`、`baseline_monitoring_coordinator_test.dart`、`activity_impact_monitoring_test.dart` | 活动暂停卡和恢复入口 Widget 回归通过 | 通过 | 连续真实结果和后台调度尚未验证 |
| activityImpact 只接受 sampledPrompt，按方向/key/rule/regime 隔离 | `ActivityImpactSampler`、`ActivityImpactFactorGate`、`ActivityImpactKey` | v5 factors、samples、feedback snapshot、factor regime | `activity_impact_contract_test.dart`、`activity_impact_learner_test.dart`、`activity_impact_preview_service_test.dart` | 活动反馈与学习控制页面启动回归通过 | 通过 | 真实抽样负担、跳过率和方向分布尚未验证 |
| activityImpact automatic 具有独立闸门、证据重验和安全激活 | `ActivityImpactLearningCoordinator`、`ModelActivationService` | activity candidate evidence snapshot、factor version/regime | `activity_impact_learning_coordinator_test.dart`、`activity_impact_activation_service_test.dart`、`activity_impact_learner_test.dart` | B3-2 Debug run 成功，logcat 无应用异常 | 通过 | activityImpact 生产门保持关闭，尚未用真实 sampled feedback 激活 |
| 两个参数族严格串行，不得同时变化 | `CombinedAutomaticLearningRequester`、两族 production coordinators | 全局 pending slot、family 与 blocked reason | `baseline_production_coordinator_test.dart`、`activity_impact_learning_coordinator_test.dart`、`model_activation_service_test.dart` | 模拟器正式 gate 仍保持零生产写入 | 通过 | 实体手机双族同时就绪场景尚未执行 |
| 敏感内容不得进入日志、hash 或备份白名单 | `CanonicalJson`、evidence digest、错误映射 | canonical allowlist、backup schema 白名单 | `canonical_json_test.dart`、`backup_content_digest_test.dart`、`json_backup_codec_test.dart` | 启动日志未见业务敏感字段或未处理异常 | 通过 | 需要最终交付构建和真机日志抽样复核 |
| 模式、授权、暂停和恢复均能被用户理解且不互相继承 | `SettingsPage`、学习设置/模型控制 ViewModel | 两族独立 app settings、notice/pause 状态 | `settings_service_test.dart`、`model_activation_service_test.dart`、`app_smoke_test.dart` 及相关 Widget 测试 | 200% 字号、紧凑横屏和控制页回归通过 | 工程通过 | TalkBack 全流程、真实通知权限关闭场景尚未做设备人工复核 |

## 2. 明确未完成的总验收门

以下不是以测试缺失掩盖的 P0，而是按用户当前顺序明确后置的设备/产品门：

1. `flutter build apk --debug` 交付构建及 APK 路径签收；
2. 实体手机安装前版本、匿名聚合和外部可恢复备份；
3. schema v1 → v5 一次覆盖安装、历史/模型/规则对比；
4. 连续自然记录、真实 sampled feedback、通知权限、后台、重启和跨生活日；
5. baseline 与 activityImpact 的 `validated / rejected / inconclusive` 产品结论更新。

在这些门完成前，不能宣称“自动学习已被真实用户验证有效”，也不能打开正式生产自动应用配置。
