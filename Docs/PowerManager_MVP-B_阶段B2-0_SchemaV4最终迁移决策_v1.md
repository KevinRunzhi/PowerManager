# PowerManager MVP-B 阶段 B2-0：Schema v4 最终迁移决策 v1

## 0. 文档状态

- 版本：1.0
- 日期：2026-08-15
- 状态：B1-1 工程决策已冻结，作为 B2-0 实现真源
- 来源 schema：v3
- 目标 schema：v4
- 正式生产激活：关闭

本文件收敛 B2-0 原 Spec 中仍无法直接编码的字段、约束、旧数据语义和迁移顺序。若与早期技术
方案的概念性表格不一致，以本文件和 B2-0 最新 Spec 为准。

## 1. v4 数据真源

- `personalization_versions` 中唯一 active 行是当前基准线的唯一可写真源；
- `app_settings` 删除 `base_energy`、`pending_base_energy` 和
  `base_energy_effective_life_day`；
- 手动修改也创建版本，不直接写整数；
- 新 daily summary 引用生成它的 personalization version；
- v4 前历史 summary 保留 inline base/rule，并明确标记为 legacy，不伪造历史版本；
- observation 现有 `personalizationVersionAtObservation` 从 v4 起保存真实版本 ID，v2 / v3 行继续
  保留 `fixed-mvp-a` sentinel；
- schema 升级本身不改变 B1 的 base、fingerprint、epoch 或 modelRegimeKey。

## 2. `personalization_versions`

### 2.1 字段

| 字段 | SQLite | 规则 |
|---|---|---|
| id | TEXT PK | trim 后非空；版本化确定性 ID |
| parent_version_id | TEXT NULL FK self | initial 为空，其余非空；RESTRICT |
| effective_model_fingerprint | TEXT NOT NULL | 当前算法为 `effective-model-sha256-v1:*` 或 initial sentinel |
| model_regime_epoch | TEXT NOT NULL UNIQUE | 真实激活窗口；候选创建时预分配 |
| creation_source | TEXT NOT NULL | initial / learningRun / manual / legacyManualPending / revert |
| schedule_source | TEXT NULL | automatic / reviewAccepted / manual / legacyManualPending / revert |
| source_learning_run_id | TEXT NULL FK | learningRun 来源必填，其余为空；RESTRICT |
| algorithm_version | TEXT NOT NULL | 学习版本或明确 sentinel |
| config_version | TEXT NOT NULL | 配置版本或明确 sentinel |
| changed_parameter_family | TEXT NOT NULL | none / baseline / activityImpact |
| base_energy | INTEGER NOT NULL | 60～140 |
| baseline_anchor_energy | INTEGER NOT NULL | 60～140 |
| status | TEXT NOT NULL | 见 2.2 |
| effective_life_day | TEXT NULL | YYYY-MM-DD；安排后永久保留 |
| created_at | INTEGER NOT NULL | UTC Drift DateTime |
| activated_at | INTEGER NULL | 首次 active 时写入 |
| ended_at | INTEGER NULL | 离开 active 或进入终态时写入 |
| transition_reason | TEXT NOT NULL | 稳定 reason code，不保存自由文本 |

v4 尚无 activity factor 表；基准线新版本完整复制 parent 的其他有效参数语义。initial 使用：

```text
creationSource = initial
algorithmVersion = initial-fixed-mvp-a-v1
configVersion = initial-fixed-mvp-a-v1
changedParameterFamily = none
effectiveModelFingerprint = fixed-mvp-a
modelRegimeEpoch = fixed-mvp-a-initial
baselineAnchorEnergy = 当前明确 base
status = active
```

### 2.2 状态与形状

状态：

```text
candidate, awaitingReview, deferred, scheduled, active, superseded,
rejected, reverted, canceled, invalidated
```

约束：

- candidate / awaitingReview / deferred：effectiveLifeDay、activatedAt、endedAt 为空；
- scheduled：scheduleSource、effectiveLifeDay 非空，activatedAt、endedAt 为空；
- active：activatedAt 非空、endedAt 为空；initial active 可没有 effectiveLifeDay，其余 active 保留；
- superseded / reverted：activatedAt、effectiveLifeDay、endedAt 非空；
- rejected / canceled / invalidated：endedAt 非空，activatedAt 为空；
- learningRun 来源必须有 sourceLearningRunId、algorithmVersion 和 configVersion；
- initial 的 parent、schedule、source run 均为空；
- manual / legacyManualPending / revert 不得伪造 source run；
- changedParameterFamily 与 parent 参数差异由领域校验器逐字段验证；initial 为 none；
- automatic、reviewAccepted、manual、legacyManualPending、revert 的生效来源不可互换。

### 2.3 数据库与 Application 共同约束

SQLite 直接保证：

- partial unique index：最多一个 active；
- partial unique constant index：全局最多一个
  candidate / awaitingReview / deferred / scheduled；
- sourceLearningRunId 非空时唯一；
- modelRegimeEpoch 唯一；
- parent / source run 外键 RESTRICT；
- 参数、来源、fingerprint、epoch、创建时间插入后不可更新；
- terminal 状态不可再转换；
- 禁止物理删除。

Application 事务和完整性检查保证：

- 任意可用数据库恰好一个 active；
- parent 链无环且 parent 创建不晚于 child；
- source run 为 completed + candidate，且 family / source model / values 与版本一致；
- active 交接、通知和冷却原子；
- changedParameterFamily 与实际差异一致。

SQLite 普通 CHECK 无法表达“至少一个 active”或跨行 parent 无环；实现和验收不得把“最多一个”
误报为“恰好一个”。

## 3. v4 `learning_runs` 重建

v3 DDL把算法、配置、结果和 candidate 锁死为 evidence-only。v4 必须重建而不是原地增加列。

### 3.1 保留字段与新增语义

字段集合保持 v3，`source_personalization_version_id` 从预留空值变为真实 FK。约束调整为：

- algorithmVersion、configVersion 和 evidenceHashVersion trim 后非空；受支持版本由 Application
  allowlist 和备份 codec 决定，不在 v4 CHECK 中只写死一个版本；
- status 仍为 pending / running / completed / retryableFailure / terminalFailure；
- result 扩展为：

```text
insufficientEvidence, readyForAudit, unstable, noChange, candidate,
configurationBlocked, improved, worsened
```

- result = candidate 时 candidateValuesJson 必须是 canonical object；baseline v4 精确为
  `{"baseEnergy":<60..140>}`，不得包含 B1-1 预生产水印；
- 其他 completed result 以及所有中间 / failure 状态的 candidateValuesJson 必须为 SQL NULL；
- B1 `evidence-shadow-v1` 行继续要求 sourcePersonalizationVersionId 和 candidate 为空；
- B2 baseline production / monitor 行必须引用 source active personalization version；
- final completed / terminalFailure 行不可更新；
- v3 五元组唯一键、确定性 ID、hash 和时间形状继续保留。

### 3.2 旧行复制

所有 v3 learning run 逐字段复制，字节不变；copy 后验证：

- 数量一致；
- 每行 ID、hash、snapshot/current/reason JSON 和时间一致；
- sourcePersonalizationVersionId 仍为空；
- candidate 非空数量为 0；
- 所有旧行仍能通过 v3 严格 codec 重放。

不得回填 initial version ID，因为这些运行在版本表出现前已经冻结。

## 4. `app_settings` v4

保留 rule、onboarding 和时间字段，删除三个 legacy base 字段，新增：

```text
baseline_learning_mode = off | review | automatic
activity_impact_learning_mode = off | review | automatic
baseline_learning_suspended = false
baseline_learning_suspended_at = null
baseline_learning_suspension_reason = null
activity_impact_learning_suspended = false
activity_impact_learning_suspended_at = null
activity_impact_learning_suspension_reason = null
baseline_learning_cooldown_until = null
activity_impact_learning_cooldown_until = null
```

约束：

- 两个模式默认 off，互不继承；
- suspended false 时 suspendedAt / reason 均为空；true 时二者均非空；
- reason 为稳定 code；
- cooldown 为 UTC，可为空；
- pendingRuleVersion 与 effectiveLifeDay 的成对约束和 rule FK 保留；
- settings 不保存 active model ID 或 base 副本，避免第二真源。

## 5. `learning_consents`

为首次模式授权新增独立审计表：

| 字段 | 规则 |
|---|---|
| parameter_family | baseline / activityImpact |
| disclosure_version | trim 后非空 |
| accepted_at | UTC |

复合主键为 parameterFamily + disclosureVersion。切到非 off 前必须存在当前说明版本的接受记录；
off 不删除记录，新说明版本仍需重新接受。该表不表示生产门开启。

## 6. `learning_notices`

App 内持久通知独立于系统通知：

| 字段 | 规则 |
|---|---|
| id | 确定性主键 |
| parameter_family | baseline / activityImpact |
| type | candidateAvailable / changeScheduled / changeActivated / learningSuspended / changeCanceled / changeReverted |
| personalization_version_id | 可空 FK，版本型通知必填 |
| learning_run_id | 可空 FK，暂停 / 证据型通知可填 |
| dedup_key | UNIQUE，按事件语义确定性生成 |
| status | unseen / seen / dismissed |
| reason_code | 稳定 code |
| created_at / seen_at / dismissed_at | UTC，按 status 成对 |

安排 automatic 或 reviewAccepted schedule 时，changeScheduled notice 与版本状态在同一事务写入；
notice insert 失败则 schedule 失败。learningSuspended 与 suspension settings、相关 worsened run 和未激活
版本失效同事务提交。系统通知发送不在该事务中，失败不删除 App 内记录。

## 7. `daily_summaries` v4 重建

新增：

```text
model_snapshot_source = legacyInline | personalizationVersion
personalization_version_id = TEXT NULL FK personalization_versions(id)
```

约束：

- v1～v3 迁移行全部为 legacyInline + NULL，原 inline base / rule /结果字节不变；
- v4 新结算只能写 personalizationVersion + 非空 ID；
- 不把 initial active 回填到旧日，因为它不能证明当日使用的是该版本；
- active 版本被 superseded / reverted 后外键仍保留，禁止删除版本；
- 备份恢复验证 inline base 与被引用版本在新行上一致。

## 8. Legacy pending base 桥接

### 8.1 预检

迁移事务开始前后都检查：

- 当前 base 在 60～140；
- pending base 与 effectiveLifeDay 同空或同有；
- pending base 在 60～140；
- pendingRuleVersion 与 effectiveLifeDay 必须**同时为空**；即使成对非空也拒绝升级；
- v3 外键、integrity_check、备份导出再解析通过。

### 8.2 桥接

1. 用当前 base 创建 initial active，anchor 等于当前 base；
2. 无 pending 时不创建其他版本；
3. 有 pending 时创建 initial 的 scheduled child：
   - creationSource / scheduleSource = legacyManualPending；
   - baseEnergy / baselineAnchorEnergy = pending base；
   - effectiveLifeDay 保留原值；
   - changedParameterFamily = baseline；
   - algorithm / config = legacy-stage19-pending-v1 sentinel；
   - 预分配新 fingerprint 和 epoch；
4. 不在迁移层根据当前时钟提前、丢弃或激活；
5. 首次 v4 prepare 先结算旧生活日，再按原日期幂等激活；
6. 重启和迁移重试不能创建第二份 initial / legacy child。

legacy pending 是用户明确决定，不要求 production gate，也不生成 learning run。

## 9. 迁移顺序与回滚

在一个 SQLite transaction 内、外键暂时关闭时顺序执行：

1. 执行全部 v3 预检并记录表计数 / 关键聚合；
2. 将旧 app_settings、learning_runs、daily_summaries 改为唯一临时名，并在事务内删除随旧表改名
   保留的 canonical index / trigger 名称；临时表数据仍完整；
3. 创建 v4 learning_runs、personalization_versions、app_settings、daily_summaries、
   learning_consents、learning_notices；互相引用表允许先声明后创建；
4. 逐字段复制 v3 learning runs；
5. 创建 initial active 与可选 legacy pending child；
6. 复制 settings，模式 off、暂停 false、冷却 null；
7. 复制 summaries 为 legacyInline；
8. 删除临时表；
9. 创建 partial unique indexes、查询 indexes 和保护触发器；
10. 执行 foreign_key_check、integrity_check、恰好一个 active、全局 pending、父链、run 重放、
    计数和业务聚合验证；
11. 提交后恢复 foreign_keys；再执行完整 JSON 导出再解析。

每个关键点提供 failure hook。任一步失败回滚全部 DDL / DML，原 v3 表、user_version 和业务数据
保持不变；禁止清库或默认重建。

## 10. 生命周期转换真值表

允许：

```text
candidate -> awaitingReview | scheduled | invalidated
awaitingReview -> deferred | scheduled | rejected | canceled | invalidated
deferred -> awaitingReview | rejected | canceled | invalidated
scheduled -> active | awaitingReview | canceled | invalidated
active -> superseded | reverted
```

- automatic → review：仅 automatic scheduled 可退回 awaitingReview，清除未来安排语义但保留历史
  schedule 事件；不能直接 active；
- review → automatic：既有 awaitingReview / deferred 不自动安排；
- off：该 family 未激活版本 canceled / invalidated，另一 family 不变；
- manual：使同 family 未激活版本 invalidated，建立新 anchor；
- source / evidence / gate / config 变化：激活前 invalidated；
- automatic 过期 restore：invalidated，不补应用；
- reviewAccepted / manual / legacyManualPending / revert restore：保留明确用户意图并幂等处理；
- terminal 状态不复活。

所有转换使用条件更新并检查恰好一行变化。

## 11. ID、fingerprint 与 epoch

- 版本 ID：`personalization-version-sha256-v1:<sha256(canonical identity)>`；
- notice ID：`learning-notice-sha256-v1:<sha256(dedup identity)>`；
- effective fingerprint：由 base、固定活动规则语义和已有 factors 的 canonical 参数决定；
- initial 未改变有效参数时必须沿用 `fixed-mvp-a`；
- 每个真实激活版本使用预分配且唯一的新 epoch；
- 撤回到数值相同仍创建新 epoch；
- schema 迁移、状态查看、defer 和取消不切 epoch。

规范编码仍只接受 null / bool / int / string / list / object，不使用随机 UUID 作为幂等真源。

## 12. Backup v4

v4 导出新增：

- personalizationVersions；
- learningConsents；
- learningNotices；
- appSettings 模式、暂停、冷却；
- v4 learning runs；
- summary model snapshot source / version reference。

导入 v1～v3 时，在临时解析对象上执行与 onUpgrade 相同的 base / pending / rule 预检和桥接，再
替换当前数据库。导入 v4 严格验证：

- 恰好一个 active、全局最多一个未处理版本；
- parent 无环、source run 与 candidate values 一致；
- schedule、notice、时间和状态形状；
- run evidence hash、版本 allowlist 和 final immutability；
- summary 引用；
- automatic 到期 / 错过恢复失效策略。

恢复完成后先重建内存、prepare、完整性检查和导出再解析，再请求协调器；恢复事务内不运行学习。

## 13. 必测边界

- v3 无 pending、未来 pending、到期 pending；base / pending / rule 字段所有残缺组合；
- 每个 migration failure hook 回滚；v1 直升 v4 与 v2 / v3 分步升级一致；
- 旧 learning run 与 summary 逐字段一致；
- active 最多一个的 SQL 约束和至少一个的完整性拒绝；
- parent 环、错误 source run、candidate JSON / watermark、非法转换全部拒绝；
- 两参数族模式、暂停、冷却和 consent 不继承；
- schedule + notice 原子失败；
- 24 小时通知跨 04:00 边界；
- review / automatic / off 升降级；
- cancel、revert、manual、restore 和重复 prepare 幂等；
- v1～v4 backup、损坏拒绝与恢复中断；
- 新 summary 引用 active，旧 summary 保持 legacyInline；
- 正式配置生产门关闭时无法创建或激活预生产候选。

## 14. 不做的事

- v4 不创建 activity factors 或 sampling 表；
- 不把 B1-1 水印候选复制进数据库；
- 不回填伪造历史 personalization version；
- 不迁移 pending rule；
- 不在 settings 保留第二份 base 或 active model pointer；
- 不依靠系统通知保存审计事实；
- 不声称 schema 单独保证所有跨行不变量。
