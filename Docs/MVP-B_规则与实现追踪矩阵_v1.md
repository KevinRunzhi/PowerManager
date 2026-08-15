# MVP-B 规则与实现追踪矩阵 v1

## 0. 状态

- 版本：1.5
- 日期：2026-08-15
- 状态：B0-3 已实现并通过自动化与 Pixel_7 模拟器验收，B1-0 可实施

| 能力 | 产品来源 | 参数 / 算法来源 | 技术落点 | 主要验证 | 当前状态 |
|---|---|---|---|---|---|
| schema v1 升级准备证明 | B0-1 Spec 2、4、5 | 无学习参数 | `MvpBUpgradeReadinessService`、readiness store、设置页与 Data Health | 备份回读、当前摘要一致、持久化、变化失效、重启复核 | B0-1 已实现；自动化与模拟器通过 |
| 规范业务内容摘要 | B0-1 Spec 4 | SHA-256 canonical business v1 | `BackupContentDigester` | 忽略传输元数据、集合顺序稳定、业务变化必变 | B0-1 已实现 |
| 固定备份文件可恢复替换 | B0-1 Spec 6、7 | 无业务参数 | `RecoverableAtomicTextFile`、latest / before-last / readiness stores | 替换失败保留旧文件、中断恢复、读写双向串行 | B0-1 已实现 |
| 设置页异步恢复生命周期 | B0-1 Spec 7、8 | 无业务参数 | `SettingsPage` reload 保留 content state | 文件选择返回触发 provider reload 时不销毁恢复流程 | B0-1 已修复并有回归测试 |
| 同日估计—实际配对 | PRD 4.1 | 配置 1、算法 2 | `energy_observations` v2、WellbeingUseCases | 原子快照、先选后揭示、跨日拒绝 | B0-3 已实现；insert / update、失败回滚、04:00 stale 和模拟器流程通过 |
| 昨日结束状态配对 | PRD 4.1 | 算法 2.1 | DailySummary + referenceType | 提交时间与参考日分离、只读 | B0-3 已实现；不可变 summary、只读拒绝和模拟器补填通过 |
| 五档方向比较 | PRD 1、2 | 配置 1、算法 4 | ObservationComparisonService | 所有严格边界、无点数映射 | B0-3 已实现；整数边界与非法 initial 全覆盖 |
| 活动覆盖确认 | PRD 3.1、4.1 | 算法 3 | observation coverageState | confirmed / uncertain 分流 | B0-3 已实现；两种覆盖均可保存，uncertain 正确排除 |
| 可学习资格 | PRD 3.2 | 配置 2、算法 3 | LearningEligibilityService | 全 reason code、三处复用 | B0-3 已实现；稳定 reason 顺序并由 Data Health 直接聚合，B1-0 复用同一服务 |
| 结算后才学习 | PRD 2、3.2 | 算法 3.2、8.2、9.1 | settlement + AutomaticLearningCoordinator | 当前日不入模、结算后单次触发 | B0-3 已实现未结算排除与结算后资格转换；自动单次触发属于 B1-0 |
| model regime 隔离 | PRD 2、3.2 | 算法 3.3 | modelRegimeKey + fingerprint + epoch | 迁移不切组、真实激活 / 撤回必切组 | B0-3 已实现 canonical key、固定哨兵与完整性校验；真实模型生命周期属于 B2 |
| reference type 隔离 | PRD 4.1 | 配置 2、4.1、算法 3.3、6.1 | modelRegimeKey + learner | current / yesterday 不互补、生产来源有优先级 | B0-3 已在 key 与 Data Health 中隔离；学习窗口与生产优先级属于 B1 / B2 |
| 活动绑定反馈 | PRD 3.1、4.2 | 算法 8.1、8.2 | activity_feedback、ActivityFeedbackUseCases | 编辑删除失效、快照完整、无参数更新 | B0-3 已实现主动 UI、完整快照、重复更新、stale 拒绝及编辑 / 删除 / 重放失效 |
| schema v1 → v2 | PRD 5.1 | 无业务参数 | Drift onUpgrade、表重建 | 数据无损、失败回滚、约束保留 | B0-2 已实现；实际 v1 DDL fixture、失败注入与模拟器覆盖升级通过 |
| 备份 v1 / v2 兼容 | PRD 5.1 | 无业务参数 | JsonBackupCodec、BackupRestore | v1 导入、v2 往返、损坏拒绝 | B0-2 已实现；B0-3 增加 ordinal / canonical regime key 严格校验，模拟器新合同回读通过 |
| B1 自动影子学习 | PRD 3.2 | 配置 2、算法 5、6 | schema v3、BaselineLearner、AutomaticLearningCoordinator | 证据配置不产候选、自动触发、确定性、零激活 | 未实现 |
| 学习运行审计 | PRD 4.3、5.1 | 算法 5.2、5.4 | learning_runs v3 | evidence hash、输入重现、失败结果 | 阻塞于 B1 |
| 不可变个人模型 | PRD 2、3.3 | 算法 5.1、5.3 | personalization_versions v4 | 唯一 active、历史冻结、单参数族 | 阻塞于 B1 |
| legacy pending base 桥接 | PRD 5.1 | 算法 5.1 | schema v4 bridge transaction | 未来 / 到期 / 残缺 / 重启不丢不重 | 阻塞于 B1 |
| 分参数族学习模式 | PRD 4.4 | 配置 0、算法 7.2、9.1 | app_settings、AutomaticLearningCoordinator | 两族独立模式、新能力不继承授权 | 阻塞于 B1 |
| 基准线自动学习 | PRD 3.3 | B1 后生产配置、算法 7 | BaselineLearner + model version v4 | 冷却、边界、反事实、相同证据防重 | 阻塞于 B1 |
| 未来生活日幂等激活 | PRD 2、3.3 | 算法 5.3、5.4 | ModelActivationService + prepare | 通知窗口、重启、04:00、恢复只激活一次 | 阻塞于 B1 |
| 通知、取消与撤回 | PRD 3.3、4.3、4.4 | 算法 5.3、7.2 | model history UI、ActivationService | 激活前取消、激活后未来恢复 | 阻塞于 B1 |
| 恶化暂停 | PRD 3.3、5.3 | B1 后生产配置、算法 7.3、9.3 | learning suspension + evaluation | 不震荡、原因可见、手动恢复 | 阻塞于 B2 |
| 活动倍率方向隔离 | PRD 3.4 | B3 配置、算法 8.3 | factors v5、activity snapshot | consumption / recovery 不串用 | 阻塞于 B3-0 |
| 活动 factor regime 隔离 | PRD 3.4 | 算法 5.4、8.3 | factor regime snapshot + learner | 旧证据不重复、基准线变化不重置 | 阻塞于 B3-0 |
| 活动反馈抽样 | PRD 3.4、4.2 | 配置 3、算法 8.1、8.2 | ActivityFeedbackSampler + source snapshot | 低频可跳过、选择无结果偏差、来源隔离 | 阻塞于 B3-0 |
| 活动影响自动学习 | PRD 3.4、5.3 | B3 配置、算法 8.4 | ActivityImpactLearner + model version v5 | 资格、确定性、幂等、无证据不伪造 | 阻塞于 B3-0 |
| 参数族串行 | PRD 2、6 | 算法 9.2 | AutomaticLearningCoordinator | 同时就绪仍只变化一个参数族 | 阻塞于 B2 / B3 |
| v3 / v4 / v5 备份兼容 | PRD 5.1 | 算法 5 | BackupCodec、restore coordinator | 运行、版本、倍率往返且不重复激活 | 阻塞于 B1 / B2 / B3 |

## 1. P0 追踪结论

- 自动学习现在贯穿 PRD、配置、算法、Schema、服务、测试和阶段门禁，不再停留在候选建议。
- 基准线和活动影响均属于 MVP-B 核心；真实证据不足允许“不变化”，但学习器和安全闭环不能
  因此省略。
- B0-3 已在 schema v2 上实现正确观测、活动覆盖、活动绑定反馈、共享业务写队列和统一资格服务；
  当前只有证据采集与只读资格统计，不存在 learning run、个人模型或参数激活写路径。
- 生产阈值没有隐藏默认值，必须通过真实影子数据门禁后发布新的配置版本。
- MVP-A 历史规则和 schema v1 数据不会被自动解释成新证据。
- 自动应用不等于静默应用：版本记录、通知、取消、撤回、冷却和恶化暂停都是 P0。
- 中间阶段只以自动化与 Pixel_7 模拟器放行；最终 APK、物理手机迁移和真实产品结论集中到
  MVP-B 总体验收，真实证据不足时生产门保持关闭。
