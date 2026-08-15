# 精力值算法规则 v3（MVP-B）

## 0. 定位

- 版本：3.2
- 日期：2026-08-15
- 状态：已确认，作为 MVP-B 算法实施基线

本文档定义 MVP-B 的观测资格、影子学习、个人模型版本、自动生效和活动影响学习机制。所有
常量和功能开关以《精力值规则配置 v3（MVP-B）》为唯一来源。

## 1. 核心不变量

1. 系统估计与用户实际状态分开保存和展示。
2. 实际状态只具有顺序，不表示精确精力点数。
3. 只有同一参考时刻的完整配对可以用于方向性对齐。
4. 旧版观测不因数据库迁移自动变成合格证据。
5. B1 影子学习永远不激活候选模型。
6. 每次学习必须冻结证据、源模型、算法版本和配置版本。
7. 每次运行只允许修改 `baseline` 或 `activityImpact` 一个参数族。
8. 新模型只影响满足生效规则的未来生活日及以后，当前日和历史结果永不重算。
9. 同一证据、源模型和算法不得重复生成或重复激活同一候选。
10. `automatic` 模式无需逐次批准，但必须受步长、边界、冷却和恶化保护约束。
11. 任何模式下都必须保留变更通知、原因、取消和撤回路径。
12. 不使用系统产生的 `finalEstimatedEnergy` 自我证明系统正确。

## 2. 每日观测配对

### 2.1 参考类型

每日五档状态允许两种参考类型：

| referenceType | 用户回答的问题 | 系统比较值 |
|---|---|---|
| `currentMoment` | 你现在的整体状态 | 保存事务内的当前估计快照 |
| `previousLifeDayEnd` | 昨天结束时的整体状态 | 昨日不可变摘要中的最终估计 |

`observedAt` 表示用户实际提交时间；旧讨论稿中的 `capturedAt` 与它是同一语义，不新增第二个
字段。`referenceType` 和 `lifeDay` 表示用户所评价的对象。补填昨日时不得把 `observedAt` 当作
昨日状态发生时间。

### 2.2 必须冻结的快照

一条 observation contract v1 的每日状态至少冻结：

- `lifeDay`
- `referenceType`
- `absoluteState`
- `estimateAtObservation`
- `initialEstimateAtObservation`
- `estimatedOrdinalAtObservation`
- `baseEnergyAtObservation`
- `ruleVersionAtObservation`
- `comparisonBandVersion`
- `personalizationVersionAtObservation`
- `effectiveModelFingerprintAtObservation`
- `modelRegimeEpochAtObservation`
- `activeActivityCountAtObservation`
- `coverageState`
- `observedAt`

同日修改每日状态时，更新同一业务记录并替换整组快照。已经结算且完成的昨日状态继续只读。
分析服务不得在以后使用变化后的活动记录重新猜测当时估计。

### 2.3 原子性

同日观测必须在同一个串行事务中完成：

1. 执行生活日准备；
2. 读取当前投影和当前个人模型版本；
3. 根据规则配置计算比较档位；
4. 写入实际状态、估计快照和上下文；
5. 提交后才揭示比较结果。

任何一步失败都不得留下只有状态、没有估计或模型快照的半条证据。

## 3. 可学习资格

### 3.1 与 MVP-A 有效日分离

MVP-A 的标准 / 弱有效日继续用于描述性总结。MVP-B 另行派生
`LearningEligibility`，不得复用一个布尔值代表两种语义。

### 3.2 基准线学习资格

每日观测同时满足以下条件才是 `eligible`：

1. `type = dailyAbsolute`；
2. observation contract 为当前受支持版本，不是 legacy；
3. 快照字段完整且 `initialEstimateAtObservation > 0`；
4. `coverageState = confirmed`；
5. 对应生活日完成早间确认；
6. 参考时刻前至少有一条 active 活动；若计数为 0，`coverageState = confirmed` 必须明确表示
   “截至参考时刻没有需要记录的主要活动”，不另造隐含无活动标记；
7. 观测没有损坏、重复或引用不一致；
8. 参考生活日已经结算，观测不再允许普通编辑；
9. 所属模型分组满足稳定版本要求。

不合格观测仍用于历史复盘，并保存机器可读的排除原因，例如：

```text
legacyContract
missingEstimateSnapshot
coverageUncertain
missingMorningCheckIn
invalidInitialEstimate
unsettledLifeDay
modelRegimeMismatch
integrityFailure
```

现有 `relativeCorrection` 可以作为“用户曾主动指出偏差”的描述性上下文，但不计入每日配对
门槛，也不能冒充活动直接反馈。它没有活动绑定关系，不得用于活动影响学习。

当前生活日内可更新的 observation 只用于即时复盘和进度展示，必须等生活日结算后才成为
学习证据。这样用户修正同日答案时，不会留下基于旧答案的待生效模型。

### 3.3 模型分组

学习不得混合以下任一项不同的观测：

- `referenceType`
- `baseEnergyAtObservation`
- `ruleVersionAtObservation`
- `comparisonBandVersion`
- `effectiveModelFingerprintAtObservation`
- `modelRegimeEpochAtObservation`

这些值共同构成 `modelRegimeKey`。同日随时填写的 `currentMoment` 与次日回忆的
`previousLifeDayEnd` 不能互相补足样本。`personalizationVersionAtObservation` 用于审计，但不能仅因
数据库换了版本 ID 就切断证据。`effectiveModelFingerprint` 必须由实际参与计算的参数确定；
schema v4 创建的初始模型与 `fixed-mvp-a` 参数完全相同时沿用同一指纹。

`model-regime-sha256-v1` 固定对下列 UTF-8 canonical JSON 做 SHA-256，并保存为
`model-regime-sha256-v1:<lowercase hex>`：

```text
{
  "referenceType": <code>,
  "baseEnergy": <integer>,
  "ruleVersion": <string>,
  "comparisonBandVersion": <string>,
  "effectiveModelFingerprint": <string>,
  "modelRegimeEpoch": <string>
}
```

字段顺序、名称和字符串值必须精确一致；不得加入 observation ID、lifeDay、observedAt 或
personalization version ID。原始组成字段仍分别保存在 observation 中供审计，哈希键只用于稳定
分组和比较。

最小样本数和日期跨度必须在同一个 `modelRegimeKey` 内满足。手动或自动变化真正改变有效
参数后，才从新模型分组重新积累基准线证据。`modelRegimeEpoch` 在每次真实模型激活时更新，
包括撤回到数值相同的旧参数；因此撤回后不会立即复用旧窗口再次提出同一变化。纯 schema
迁移且计算参数完全不变时不更新 epoch。

## 4. 方向性对齐

按规则配置将实际状态和估计快照转换为两个有序类别：

```text
alignmentDelta = actualOrdinal - estimatedOrdinal
```

解释：

```text
alignmentDelta < 0  -> 用户实际状态低于系统对应档位
alignmentDelta = 0  -> 两者属于相同档位
alignmentDelta > 0  -> 用户实际状态高于系统对应档位
```

`alignmentDelta` 可以用于分布和方向统计，但绝不能直接转换成 `baseEnergy += alignmentDelta`
或任何伪精确点数。

## 5. 个人模型与学习运行

### 5.1 不可变个人模型

每个 `PersonalizationVersion` 至少包含：

- 唯一版本 ID 和父版本 ID；
- 由实际有效参数确定的 `effectiveModelFingerprint`；
- 每次真实激活更新的 `modelRegimeEpoch`；
- `baseEnergy`；
- `baselineAnchorEnergy`：最近一次用户明确设定的值，初始为进入 MVP-B 时的当前基准线；
- 按“子类 × 影响方向”保存的活动影响倍率集合；
- 来源 `learningRunId` 或明确的手动修改来源；
- 算法与配置版本；
- 创建时间、计划生效生活日和状态。

新版本完整复制未学习的参数族。例如基准线学习只改变 `baseEnergy`，活动影响倍率原样复制。
已结算生活日始终引用当时版本，禁止用当前版本回算历史。

基准线累计自动变化始终相对 `baselineAnchorEnergy` 计算。自动激活、自动撤回或恢复旧值都不
重置 anchor；只有用户在明确说明后手动设定基准线才创建新 anchor、失效旧候选并开启新 epoch。

schema v4 升级前已经存在的 `pendingBaseEstimatedEnergy` 属于用户手动决定，不是学习候选。它
必须转换为 `creationSource = legacyManualPending`、`scheduleSource = legacyManualPending` 的
模型版本；生效时以该值建立新的 baseline anchor。不得把它标记为自动学习结果、丢弃或与新
候选同时应用。

### 5.2 学习运行

每次 `LearningRun` 固定保存：

- `parameterFamily = baseline | activityImpact`；
- 源个人模型版本和参数族对应的 `sourceModelIdentity`；
- 合格证据 ID、排除原因摘要和不可变 `evidenceHash`；
- 算法、配置和观测合同版本；
- 当前值、候选值、方向、置信门结果和原因码；
- 触发时间、完成时间和运行结果。

算法结果使用 `insufficientEvidence`、`readyForAudit`、`unstable`、`noChange`、`candidate`
和 `configurationBlocked`。当前配置只有最低证据门时，最多得到 `readyForAudit`，不得得到
`candidate`。

运行状态与算法结果分开：事务中断、数据库暂时错误等记为 `retryableFailure`，复用同一 run ID
和幂等键重试；不支持的配置或确定性完整性错误记为 `terminalFailure`，只有证据、源模型、算法
或配置变化后再运行。任何失败都不得创建候选或修改当前模型。

### 5.3 候选版本生命周期

```text
candidate -> awaitingReview -> scheduled -> active -> superseded
candidate -> scheduled                     (automatic 模式)
awaitingReview -> rejected | deferred | invalidated
deferred -> awaitingReview | rejected | invalidated
scheduled -> awaitingReview | canceled | invalidated
active -> superseded | reverted
```

- `review` 模式把合格候选置为 `awaitingReview`；接受后才进入 `scheduled`。
- `automatic` 模式把通过自动安全门的候选直接置为 `scheduled`，并立即生成可见通知。
- `scheduled` 与持久化通知记录必须在同一事务提交；通知记录失败时保持当前模型且不得安排。
- `automatic` 的 `effectiveLifeDay` 必须取“严格晚于当前生活日”且满足配置最短通知时间的
  最早生活日；只能在对应生活日准备事务中激活一次，此前用户可以取消。最短通知时间未配置
  时不得自动安排。
- 从 `review` 切换到 `automatic` 不会自动安排已有 `awaitingReview / deferred` 候选；它们仍需
  明确处理。`automatic` 降为 `review` 时，未生效的自动安排退回 `awaitingReview` 并清除生效日。
- 某参数族切换到 `off` 时，该参数族所有未激活候选都进入 `canceled / invalidated`，不能在
  以后静默恢复；另一个参数族不受影响。
- 拒绝、主动取消和撤回不作为相反方向的数值证据，但会启动配置定义的参数族冷却期；冷却期
  内即使 evidence hash 因新数据变化，也不得反复生成近似候选。
- 手动修改同一参数族、恢复到不兼容备份或源模型改变，会使未激活候选 `invalidated`。
- 激活前必须重新校验证据仍存在且内容哈希一致；证据被更正、删除或失效时不得应用旧候选。
- 激活前必须重新检查对应生产门、模式、暂停状态以及算法 / 配置版本仍受支持；配置被撤回或
  参数族关闭时旧候选失效。
- 证据超过 `maximumProductionEvidenceAge`，或候选超过 `maximumCandidateLifetime`，必须
  `invalidated`；打开 App、切换模式或恢复备份都不能复活过期候选。
- 备份恢复出的**自动安排**若生效生活日已经到达或错过，必须 `invalidated`；不得在恢复后的
  首次 prepare 中立即补应用。`reviewAccepted / manual / legacyManualPending` 代表用户已经明确
  决定，按其原生效日幂等处理。新的自动候选必须基于恢复后状态重新学习并满足全部安全门。
- 撤回通过创建一个未来生效的新版本恢复上一组参数，不改写已使用该版本的历史。

### 5.4 幂等键

`evidenceHash` 使用配置声明的版本化规范编码：证据先按各自稳定排序键排列，对象键按字典序
编码，枚举使用稳定代码，整数不得转浮点，时间统一为 UTC ISO-8601，再对 UTF-8 字节计算
SHA-256。编码只包含学习必需的快照字段、ID 和资格结果，不包含活动标题、备注或展示文案。

哈希用于重现和防重，不是匿名化或访问控制；UI 不展示原始哈希，导出仍按敏感数据处理。

以下组合必须唯一：

```text
parameterFamily
+ sourceModelIdentity
+ algorithmVersion
+ configVersion
+ evidenceHash
```

基准线的 `sourceModelIdentity` 使用 `modelRegimeKey`；活动影响使用第 8.3 节的
`activityImpactRegimeKey`。完整个人模型版本仍单独保存，供候选复制未变化参数并在生效前
检查父版本。

全局同时最多存在一个 `candidate / awaitingReview / deferred / scheduled` 个人模型版本，而
不是每个参数族各一个。重复启动、后台恢复、跨 04:00、重复 prepare 和备份恢复不得重复
生成或重复激活。

## 6. B1 自动影子学习

### 6.1 输入

- 单一 `modelRegimeKey` 下的合格每日观测；
- 按 `lifeDay + observedAt + id` 稳定排序，并按配置取最近一组固定数量证据；
- 满足规则配置中的总量、日期跨度和双窗口要求；
- B3 准备阶段可同时读取合格活动反馈，但仍按独立参数族运行。

影子报告必须按 `referenceType` 分开展示。生产算法配置未明确允许的 reference type 不得生成
可执行候选；若多个来源分别达标，必须使用配置的固定优先级，不能合并后投票。

### 6.2 输出

影子运行自动生成并保存：

- 合格、排除和仍缺少的证据数；
- 覆盖的日期范围；
- `低于 / 相符 / 高于` 的方向计数；
- 两个连续窗口各自的原始方向分布；
- 当前配置仅有最低证据门时的 `证据不足 / 可以审计` 结论。

B1-1 发布明确标记为 shadow-only 的方向判定、候选步长和边界后，新的影子算法版本才可额外
输出 `方向不稳定 / 无需变化 / 存在候选`、候选个人模型及反事实结果。shadow-only 参数不得
被生产激活服务读取。

### 6.3 禁止行为

- 不写当前或 pending 基准线；
- 不创建可激活的生产版本；
- 不更新活动影响倍率；
- 不把影子候选描述成已经学会或即将生效；
- 不跨模型分组补足样本；
- 不因接近门槛而降低资格条件。

## 7. B2 基准线自动学习

B2 只有在 B1 真实数据审计完成、规则配置补齐生产参数并启用对应构建门后才能运行。

### 7.1 候选生成

候选方向固定为：持续 `alignmentDelta < 0` 表示系统长期偏高，基准线候选只能向下；持续
`alignmentDelta > 0` 表示系统长期偏低，基准线候选只能向上。`alignmentDelta` 的绝对值仍不
直接决定点数，步长只能来自已发布配置。

基准线学习必须同时满足：

- 单一模型分组内达到生产样本、跨度和方向一致性阈值；
- 不在冷却期；
- 全局没有任一参数族的待审核、稍后或待生效版本；
- 候选步长和累计值均在配置边界内；
- 候选绝不能越过既有 `60～140` 基准线硬范围；
- 冻结证据的反事实回放未触发恶化保护；
- 当前源模型与运行开始时一致。

生产阈值、步长和边界尚未在规则配置发布时，只能得到 `insufficientEvidence` 或影子候选，
不能生成可执行版本。

### 7.2 模式处理

生产候选还需同时通过：

```text
automaticLearningEngineEnabled == true
baselineProductionLearningEnabled == true
learningMode(baseline) != off
```

- `review`：候选等待用户接受、拒绝或稍后处理，未经接受参数不变。
- `automatic`：只有 `baselineAutoApplyEnabled == true` 且通过自动安全门时才安排最早可生效的
  未来生活日；
  否则保持当前模型并记录阻塞原因，不能静默降级为越权应用。
- 基准线 `off`：不创建该参数族的新运行，取消该参数族未激活版本；已激活模型保持不变，
  用户可明确撤回或重置。

### 7.3 生效后观察

激活新基准线版本后进入冷却期，并在新的 `modelRegimeKey` 独立积累证据。若后续达到配置
定义的恶化条件：

1. 暂停该参数族的新自动学习；
2. 当前模型继续保持 active，并在学习状态中标记需要关注，而不是立即反复震荡；
3. 通知用户查看证据并提供撤回；
4. 只有未来配置明确允许自动撤回时，才可自动安排恢复版本。

## 8. B3 活动影响自动学习

### 8.1 反馈语义

活动反馈必须绑定一条具体活动并冻结当时快照：

```text
strongerImpact
aboutRight
weakerImpact
directionMismatch
```

B3 schema v5 的每条反馈同时记录 `collectionSource = userInitiated | sampledPrompt`；抽样反馈
还记录抽样策略版本、被抽中时间和 sample ID。v2 旧反馈统一迁移为 `userInitiated`。用户主动
反馈天然偏向异常体验，MVP-B 只把受支持策略产生的 `sampledPrompt` 反馈用于生产倍率学习；
`userInitiated` 反馈用于单条复盘、影子统计和规则方向审计。

“更强 / 更弱”始终表示影响幅度：

- 消耗活动更强：绝对消耗应更大；
- 恢复活动更强：恢复量应更大；
- `aboutRight`：支持当前倍率，不代表倍率必须等于 `1.0`；
- `directionMismatch`：默认方向可能不成立，不得交给保持符号的倍率模型处理。

### 8.2 反馈资格

反馈只有同时满足以下条件才可进入活动影响学习：

- 活动仍真实存在，反馈后未被删除或实质编辑；
- `collectionSource = sampledPrompt`，且抽样策略版本受当前生产算法支持；
- 反馈所属生活日已经结算，活动与反馈不再允许普通编辑；
- 保存了子类、时长、规则版本、个人模型版本、默认 / 个性化理论变化和实际变化快照；
- 默认理论值不为 0；
- `appliedDelta == personalizedTheoreticalDelta`，没有受到恢复上限截断；
- 反馈不是 `directionMismatch`；
- 所属活动影响 regime 和影响方向可追溯。

不合格反馈仍保留用于产品和规则研究，但不得更新倍率。

抽样选择不得读取用户之后的反馈结果，也不得只挑理论变化特别大、恢复被截断或用户曾主动
抱怨的活动。跳过必须记录为“未响应”而不是任一反馈方向，同日不得反复追问。

`directionMismatch` 虽不进入保持符号的倍率计算，但必须计入该 `ActivityImpactKey` 的安全
审计。当前生产配置未定义否决阈值，或当前 regime 达到该阈值时，该键不得生成倍率候选，
并进入固定规则复核。

### 8.3 模型键与计算边界

活动影响倍率至少使用：

```text
ActivityImpactKey = subcategory + impactSign(consumption | recovery)
activityImpactRegimeKey = ActivityImpactKey + ruleVersion + factor + factorRegimeStartedLifeDay
```

同一子类的恢复证据不得改变消耗倍率，反之亦然。没有个人倍率时使用 `1.0`。生产计算先在
默认理论变化上应用当前版本倍率，再按既有规则取整得到 `personalizedTheoreticalDelta`，最后
执行恢复上限得到 `appliedDelta`。活动记录和反馈必须冻结默认理论值、倍率、个性化理论值、
实际值、个人模型版本和活动影响 regime。

倍率只对其声明的固定 `activityRuleVersion` 有效。规则版本不匹配时不得静默沿用旧倍率或学习
新反馈；MVP-B 冻结 `energy-rules-v2-mvp-a`，未来规则迁移必须另写兼容 Spec。

每个键只使用 `factorRegimeStartedLifeDay` 当日及之后、在当前活动影响 regime 下产生的反馈。活动
倍率变化会开启新 regime，旧反馈不能再次推动下一步变化；只修改基准线并复制相同倍率时，
不得重置这个活动 regime 或把旧证据当成一批新证据。

`strongerImpact / weakerImpact / aboutRight` 如何聚合为候选倍率、最小样本量、步长和范围，
必须由 B1 / B3 真实数据审计后的配置版本定义，禁止在实现中猜默认值。

候选方向只能是：`strongerImpact` 的稳定证据提高影响绝对值倍率，`weakerImpact` 的稳定证据
降低倍率，`aboutRight` 支持保持当前值。倍率始终为正并保留固定规则方向；任何试图跨过 0
翻转方向的候选都必须拒绝，并交给 `directionMismatch` 规则审计。

### 8.4 自动学习与安全应用

B3 必须实现完整活动影响学习器，而不是只做可行性报告：

- 按 `ActivityImpactKey` 独立聚合合格反馈；
- 同一键跨固定规则时长档位明显异质时返回 `unstable`，不得用单一倍率强行平均；
- 每次只生成一个参数族版本，可在一个版本中包含同批审计通过的多个互不冲突键；
- `review` 与 `automatic` 沿用第 5 节生命周期；
- 生成可执行候选要求 `activityImpactProductionLearningEnabled == true`；
- 生成用户特定运行还要求 `learningMode(activityImpact) != off`；
- 自动安排还要求 `activityImpactAutoApplyEnabled == true`；
- 稀疏或不稳定的键保持当前倍率，不能为了“自动学习”伪造更新；
- 零值和 `directionMismatch` 进入规则审计，不被硬塞进倍率模型。

## 9. 调度、模式切换与评估

### 9.1 自动触发

观测或反馈提交后只刷新进度；它们所属生活日结算并变成不可变证据后、生活日准备后以及安全
恢复完成后，应用才请求学习协调器运行。协调器必须串行、可中断、幂等；没有新证据时直接
返回，不进行轮询或重复写入。

schema v4 引入用户模式后，`learningMode(parameterFamily) = off` 时协调器不得为该参数族创建
新的用户特定影子或生产运行。B1 在此之前的影子审计必须以项目作者的显式授权为前提。

### 9.2 参数族隔离

若基准线与活动影响同时具备候选条件：

1. 只处理配置定义的优先参数族；
2. 激活并完成冷却观察；
3. 另一个参数族基于新源模型重新学习。

不得用一次前后对比同时归因两个参数族的变化。

### 9.3 效果评估

后续报告只做同一用户、同一模型分组的描述性比较：

- 新窗口方向分布是否更接近相符；
- 是否从持续单向偏差变为震荡或反向偏差；
- 活动反馈中 `aboutRight` 比例是否改善；
- 用户是否取消、撤回或认为参考价值下降；
- 记录与反馈负担是否上升。

小样本结果不得表述为统计显著、普遍有效或医学准确。自动学习的成功标准是更稳定地贴近
这个用户的主观观测，而不是频繁产生参数变化。
