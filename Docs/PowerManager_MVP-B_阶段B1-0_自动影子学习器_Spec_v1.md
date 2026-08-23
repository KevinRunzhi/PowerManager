# PowerManager MVP-B 阶段 B1-0：自动影子学习器 Spec v1

## 0. 文档状态

- 版本：1.3
- 日期：2026-08-15
- 状态：已实现并通过自动化与 Pixel_7 模拟器工程验收
- 数据库版本：schema v2 升级到 schema v3
- 生产副作用：严格为零
- 下一阶段：B1-1 工程决策轨；真实产品轨延期到最终真机安装后

## 1. 阶段目标

让 App 在新的生活日证据结算后，自动、确定、幂等地生成可重现的影子学习运行。当前配置只
定义证据就绪门，因此运行最多得出 insufficientEvidence 或 readyForAudit，不得伪造候选参数。

本阶段要证明的是“学习输入和运行基础可信”，不是证明自动调整有效。

## 2. 前置条件

- B0-3 已能产生完整 observation contract v1；
- LearningEligibilityService 已被 Data Health 复用；
- currentMoment 与 previousLifeDayEnd 分组稳定；
- schema v2 备份与恢复通过；
- 当前模型哨兵和 regime key 已冻结；
- 项目作者明确授权只读影子运行；
- 生产学习与自动应用门仍关闭。

## 3. Schema v3

新增 learning_runs，字段、唯一键和结果枚举以技术方案 2.3 节为准。必须通过数据库约束保证：

- evidenceHash、hash version、algorithm version 和 config version 非空；
- status 与 result 分开；
- 运行中或失败状态不能带可激活版本引用；
- evidence-only 算法版本的 candidateValuesJson 必须为空；
- 唯一键为 parameterFamily、sourceModelIdentity、algorithmVersion、configVersion、evidenceHash；
- B1 数据库中不存在 personalization_versions；
- activityImpact 接口可以存在，但没有受支持抽样证据时只返回配置或证据不足。

### 3.1 v1.1 精确存储合同

本阶段固定使用：

```text
parameterFamily = baseline
algorithmVersion = evidence-shadow-v1
configVersion = evidence-readiness-14x21-v1
evidenceHashVersion = canonical-evidence-sha256-v1
sourcePersonalizationVersionId = null
candidateValuesJson = null
```

`activityImpact` 只保留 enum / 接口兼容，不创建 learning run；在 B3 发布无选择偏差的抽样合同前，
用户主动反馈不能冒充生产学习证据。

`learning_runs` 的 SQLite 合同固定为：

- id、parameterFamily、sourceModelIdentity、evidenceSnapshotJson、evidenceHash、三个版本字段、
  currentValuesJson、reasonCodesJson、triggeredAt 均非空；所有字符串 ID / 版本 trim 后非空；
- evidenceHash 是 64 位 lowercase hex，版本单独保存在 evidenceHashVersion；
- 三个 JSON 字段必须是合法 JSON；evidenceSnapshotJson 与 currentValuesJson 为 object，
  reasonCodesJson 为 array；currentValuesJson 精确为 canonical `{"baseEnergy":<integer>}`；
- candidateValuesJson 在 `evidence-shadow-v1` 下必须为 SQL NULL，不使用空对象或字符串 `"null"`；
- pending / running 的 result 与 completedAt 必须为空；completed 的 result 与 completedAt 必须存在；
  retryableFailure / terminalFailure 的 result 必须为空且 completedAt 必须存在；
- result 只允许 insufficientEvidence、readyForAudit、configurationBlocked；
- completed 与 terminalFailure 行不可再更新；retryableFailure、pending 和 running 可用同一 id 恢复；
- 复合唯一键和确定性 run ID 双重防重；B1 不创建 candidate / personalization 外键或激活引用。

schema v2 → v3 只创建该表、索引和保护触发器，不重写任何 v2 业务行。App 若从更早 schema
直接升级，1 → 2 → 3 必须在一个可回滚升级事务中顺序执行；v3 任一步失败不得留下“v2 结构但
user_version 仍为 1”的半迁移状态。

## 4. 确定性证据包

### 4.1 选择

对每个单一 modelRegimeKey：

1. 只读取已结算且 eligible 的 observation；
2. 按 lifeDay、observedAt、id 升序稳定排列；
3. 取最近 14 条；
4. 最早和最晚参考 lifeDay 跨度至少 21 个日历日；
5. 前 7 条为窗口 1，后 7 条为窗口 2；
6. 更早数据只进入描述性总计，不进入本次哈希和双窗口结论；
7. 两种 referenceType 分别运行，不合并。

“属于一个 regime”的范围必须可判定：只把声明该 sourceModelIdentity 的新合同 dailyAbsolute
放入该包；其中 key 与快照重算不一致的行保留为该包的 modelRegimeMismatch 排除项。legacy、
缺少 key 的损坏行和其他 regime 不复制到每个包中，它们只进入 Data Health 的全局排除统计。

13 条以及 14 条但跨度不足的包都会产生 deterministic `insufficientEvidence` 运行；第 14 条且
跨度达标时产生 `readyForAudit`。每次结算使该包的 hash input 变化时可以新增一条审计运行；没有
变化时必须零写入。超过 14 条后只选择最近 14 条，更早 eligible 行只进入 UI 的描述性总计，不
进入本次 hash input。

### 4.2 规范编码

- 对象键按字典序；
- 枚举使用稳定代码；
- 整数保持整数；
- UTC 使用统一 ISO-8601 表达；
- 证据按稳定排序键排列；
- 只包含学习必需快照、ID 和资格结果；
- 排除活动标题、备注、展示文案、文件路径和 locale 文案；
- SHA-256 算法由 evidenceHashVersion 标识。

产品文档曾使用的 `capturedAt` 在当前 schema 中精确对应 `observedAt`；规范字段统一命名为
`observedAt`，不再引入第二个时间语义。UTC 固定编码为六位小数的
`YYYY-MM-DDTHH:mm:ss.ffffffZ`，相同时刻的
不同时区表示必须得到同一字节串。

canonical encoder 必须递归按 Unicode key 字典序编码 object，保留 list 顺序，只接受 null、bool、
integer、string、list 和 object，拒绝 double / NaN / locale 相关值。evidenceHash 为以下
`hashInput` 的 canonical UTF-8 SHA-256，不直接对整个展示快照求哈希：

```text
hashInput = {
  algorithmVersion,
  configVersion,
  evidenceHashVersion,
  parameterFamily,
  referenceType,
  sourceModelIdentity,
  readinessThresholds,
  selectedEligibleEvidence[最多最近14条完整学习快照],
  scopedExcludedEvidence[id, lifeDay, observedAt, orderedReasonCodes]
}
```

每条 selectedEligibleEvidence 保存完整 observation contract v1 学习快照、`hasMorningCheckIn = true`、
`settled = true`、actualOrdinal、alignmentDirection 和稳定 ID；不复制活动正文。更早 eligible 总数
只放在 evidenceSnapshotJson 的 `descriptive` 对象中，所以补入一个不影响最近 14 条的更早证据
不会制造新 hash。

编码器必须提供跨进程、字段插入顺序和备份恢复稳定的 golden vectors。

### 4.3 输出

evidenceSnapshotJson 至少记录：

- 当前 regime 和 referenceType；
- eligible、excluded、missing 数；
- 证据 ID 与日期范围；
- 低于、相符、高于计数；
- 两个窗口各自的方向分布；
- 排除原因聚合；
- readiness 门的逐项结果。

快照顶层固定为 `{"descriptive":...,"hashInput":...}`。`descriptive` 还要记录 eligibleTotal、
selectedEligible、excludedTotal、missingToMinimum、最早 / 最晚选中生活日，以及窗口 1 / 2 的
实际大小。方向统计只基于 selectedEligibleEvidence。对象本身也使用同一 canonical encoder，
从而可以逐字节重放，但 evidenceHash 仍只覆盖 hashInput。

不得把用户原始活动正文复制进 learning_runs。

## 5. 运行状态机

运行状态：

- pending；
- running；
- completed；
- retryableFailure；
- terminalFailure。

算法结果：

- insufficientEvidence；
- readyForAudit；
- configurationBlocked。

本版本不得写 unstable、noChange 或 candidate。B1-1 即使发布新的 shadow-only 算法，也只能在
schema v3 外离线返回这些结果；持久化必须等待后续 schema 重建和独立决策记录。

瞬时数据库或中断失败复用同一 run ID 和幂等键。确定性完整性失败记录 terminalFailure，只有
证据、模型身份、算法或配置改变后才允许新运行，禁止启动忙循环。

持久化采用可恢复的分段状态转换，而不是把所有状态包在一个失败即消失的大事务中：

1. 一致读取并构造证据包；
2. 由幂等五元组 SHA-256 生成 deterministic run ID，insert pending；唯一冲突读取既有行；
3. 单独事务把 pending / retryableFailure / 遗留 running 转为 running；
4. 纯函数求值后，单独事务原子写 completed + result + completedAt；
5. 可安全重试的异常尽力写 retryableFailure；下次请求复用原 id、triggeredAt 和幂等键；
6. 确定性完整性 / 不支持配置写 terminalFailure，后续相同幂等键直接跳过。

若数据库故障严重到 failure 状态本身无法落盘，允许保留 pending / running；下次安全请求按同一
id 恢复。任何中间状态都不能有 result、candidate 或模型副作用。

## 6. 自动触发与串行协调

AutomaticLearningCoordinator 只在以下时机被请求：

- 冷启动或恢复前台的 prepare 成功完成并通过完整性门；
- prepare 结算了至少一个旧生活日；
- App 安全恢复并完成完整性检查；
- 前次 retryableFailure 具备安全重试条件。

保存当前日观测只刷新进度，不立即运行。没有新 evidence hash 时零写入。多个并发请求通过
现有串行 tail 合并，后台任务只发请求，不持有跨生命周期事务。

实现上复用 B0-3 的同一个 BusinessWriteCoordinator。冷启动 / 恢复 / 生活日边界在 prepare 完成
且数据库导出再解析完整性门通过后请求；若 prepare 返回 settledSummaries 非空必须请求。备份恢复
事务内绝不运行学习器，恢复成功、内存重建、prepare 和完整性门依次完成后才发一次幂等请求。
beforeWrite 内部不得同步等待一个再次进入同一 BusinessWriteCoordinator 的学习任务，以免自锁。

当前规则配置已将 `automaticLearningEngineEnabled` 开到只读 B1 引擎；四个 production / auto-apply
门仍为 false。总门关闭或版本不受支持时可以记录 configurationBlocked，但不能静默走候选路径。

B1 的依赖图必须无法解析 ModelActivationService 或写 base 设置。用 UI 隐藏按钮不能替代这一
结构性隔离。

## 7. 影子 UI

设置或 Data Health 中提供“自动学习进度”只读区域：

- 当前 referenceType；
- 合格数量与日期跨度；
- 两个窗口原始方向分布；
- 主要排除原因；
- 最近运行时间和结果；
- “证据达到审计门，不代表系统将改变参数”的固定说明；
- retryable / terminal 错误使用安全原因，不展示哈希和内部异常。

不得出现“即将自动调整”“已经学会你的基准线”等超前文案。

## 8. 自动化测试

### 8.1 Migration 与 backup

- v2 空库、全量库和含 invalidated feedback 的 fixture 升级；
- v2 原字段逐项一致；
- learning_runs 初始为空；
- 迁移失败完整回滚；
- v1、v2 备份导入到 v3；
- v3 learning_runs 往返；
- 重复恢复后不生成重复运行。

### 8.2 Domain

- 13、14、15 条证据；
- 20、21、22 日跨度边界；
- 超量时只取最近 14；
- 相同 lifeDay 和 observedAt 时由 id 稳定排序；
- 两个窗口切分准确；
- 每个排除 reason；
- referenceType 与 regime 隔离；
- canonical encoding golden vectors；
- 字段顺序扰动、时区等价和备份往返哈希稳定；
- 活动标题或备注变化不改变 baseline evidence hash。

### 8.3 Application

- 新结算证据自动触发；
- 未结算证据不触发；
- 无新证据零写入；
- 重启、重复 prepare 和并发请求只产生一条；
- retryableFailure 使用同一 run 恢复；
- terminalFailure 不忙重试；
- 配置门关闭时返回 configurationBlocked 或不注册运行；
- candidateValuesJson 始终为空；
- app_settings base 和活动计算零变化；
- B1 构建中不存在激活服务可达路径。

还必须覆盖 v1 直升 v3 的整链失败回滚、pending / running 崩溃恢复、completed / terminal 不可变、
SQL NULL candidate 约束、13 条运行落库语义、较早 eligible 不改变最近 14 条 hash，以及同一 UTC
时刻不同时区输入的六位小数 golden vector。

### 8.4 Widget 与回归

- 进度、排除、就绪、失败和空状态；
- 200% 字号与小屏；
- format、analyze、全量 test、coverage、模拟器可运行构建；
- git diff --check。

## 9. 模拟器验收

可使用明确标记的 fixture 或测试时钟验证工程生命周期：

1. 13 条在结算请求后持久化一条 insufficientEvidence；
2. 增加并结算第 14 条后自动运行；
3. 重启和重复 prepare 不新增运行；
4. 删除或更正未结算数据不影响已冻结运行；
5. 恢复 v3 备份后哈希相同且不重复；
6. 当前 base、pending base、规则和投影完全不变；
7. UI 如实说明只到审计门。

fixture 结果不能写入真实产品验证结论。

## 10. 停止条件

- 影子运行改变任何生产参数；
- 当前日可编辑数据进入证据；
- 两种 referenceType 或不同 regime 混合；
- 相同证据产生不同哈希或不同输出；
- 重启产生重复运行；
- failure 与算法结果混为一个字段；
- evidence-only 运行出现候选值；
- 备份恢复后立即触发不受控学习。

## 11. 退出证据

- schema v3 分步迁移和备份全绿；
- hash golden vectors 固定；
- 幂等、失败恢复和零副作用测试通过；
- 模拟器自动触发记录；
- 当前生产门仍关闭；
- 真实使用可以开始自然积累 B1-1 所需证据。
