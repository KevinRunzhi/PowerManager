# PowerManager MVP-B 阶段 B3-2 实现与验收记录

## 1. 实现范围

- 活动影响学习运行器：按 sampled feedback、活动快照、生活日结算和当前 factor regime 组装证据，使用确定性幂等键持久化 LearningRun，并复用 ModelActivationService 的 review / automatic 生命周期。
- 准备流程：活动影响 learner 与 monitoring 均接入统一 preparation；只有正式生产门和本族模式同时打开时才创建活动监测协调器，默认构建仍 fail-closed。
- 安全门：活动影响生产学习、自动学习引擎、模式、暂停、冷却、支持算法/配置和全局 pending 槽均参与候选生成；baseline 与 activityImpact 共用一个待处理槽，避免并发交叉激活。
- 因子生命周期：候选版本保存完整 factor 集，接受/自动安排时重新校验证据、策略、规则和父模型；激活只切换活动影响族，变化键开启新 regime，未变化键保留旧 regime，历史活动不回算。
- 活动快照：新建、编辑和预览读取当前 active 版本的 factor，保存 default / factor / personalized delta / version / regime；回放仍只使用已持久化的 personalized delta。
- 撤回：活动影响撤回创建未来版本并使用旧 factor 数值，但所有键开启新的 factor regime。
- 监测：新增活动影响 monitoring evaluator/coordinator；directionMismatch veto 或恶化结果只暂停 activityImpact，不自动往返调参。
- schema v5 兼容：在新建数据库、v4→v5 升级和已有 v5 打开路径统一确保 LearningRunsTable 接受 activityImpact 的 factors JSON；历史 schema v1–v4 fixture 仍保持原约束。
- 备份链路：JSON export/restore、完整性校验、本地备份、升级 readiness 与 data health 共用按生产门配置的 codec，并包含 activity factors。

## 2. 验收结果

- `flutter analyze`：通过，无 issue。
- `flutter test test/data/db/schema_v2_migration_test.dart test/data/db/schema_v4_migration_test.dart test/data/db/schema_v5_migration_test.dart`：通过。
- 全量 `flutter test --reporter compact`：通过，518 tests passed；新增活动影响 monitoring 边界和 review→schedule→activate 回归。
- `flutter analyze`：通过，无 issue。
- 模拟器 `flutter run -d emulator-5554 --debug --no-resident`：启动、安装和同步成功；logcat 未发现 FATAL EXCEPTION、FlutterError、Unhandled 或 SQLite 数据库错误。只产生了本次 Debug 验证所需的临时 debug APK，不作为交付物。

## 3. 明确限制

- 正式 provider 仍保持 activityImpactProductionLearningEnabled / activityImpactAutoApplyEnabled 关闭；本阶段只提供受门控的工程路径，不代表已经开启真实用户自动调参。
- 真实 sampled feedback 的连续两天/多生活日产品观察，以及最终 APK 和手机安装，按总体验收计划延期。
