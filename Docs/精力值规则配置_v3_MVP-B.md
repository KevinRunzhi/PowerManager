# 精力值规则配置 v3（MVP-B）

## 0. 版本与启用状态

```text
activityRuleVersion = energy-rules-v2-mvp-a
observationContractVersion = mvp-b-observation-v1
comparisonBandVersion = estimate-actual-ordinal-v1
fixedPersonalizationVersion = fixed-mvp-a
fixedEffectiveModelFingerprint = fixed-mvp-a
initialModelRegimeEpoch = fixed-mvp-a-initial
modelRegimeKeyVersion = model-regime-sha256-v1
shadowLearningAlgorithmVersion = evidence-shadow-v1
shadowLearningConfigVersion = evidence-readiness-14x21-v1
evidenceHashVersion = canonical-evidence-sha256-v1

automaticLearningEngineEnabled = true
baselineProductionLearningEnabled = false
baselineAutoApplyEnabled = false
activityImpactProductionLearningEnabled = false
activityImpactAutoApplyEnabled = false
baselineLearningModeDefault = off
activityImpactLearningModeDefault = off

baseEnergyHardMinimum = 60
baseEnergyHardMaximum = 140
```

本文件是 MVP-B 自动学习数值常量和功能开关的唯一来源。MVP-B 不原地修改现有 24 × 6 活动规则表；
未激活个人模型时，活动计算继续读取《精力值规则配置 v2（MVP-A）》中的固定版本。

当前设置表示“B1 只读影子引擎已获准自动运行，但生产学习和自动应用尚未获准启用”：

- `automaticLearningEngineEnabled`：B1 只读影子协调器总门。项目作者已授权按独立阶段 Spec 实施，
  因此从 B1-0 配置起为 `true`；它本身不允许生成候选或改变参数。
- `shadowLearningAlgorithmVersion`：当前只汇总证据就绪情况的算法版本，禁止输出候选值。
- `shadowLearningConfigVersion`：固定绑定本文件第 2 节的 14 条、21 日、2 × 7 窗口门槛。
- `baselineProductionLearningEnabled`：允许生成可执行基准线候选。B1 决策门前保持 `false`。
- `baselineAutoApplyEnabled`：允许基准线候选跳过逐条确认进入自动安排。
- `activityImpactProductionLearningEnabled`：允许生成可执行活动影响候选。B3 决策门前保持 `false`。
- `activityImpactAutoApplyEnabled`：允许活动影响候选跳过逐条确认进入自动安排。
- `baselineLearningModeDefault = off`：基准线参数族首次授权前不运行用户特定学习。
- `activityImpactLearningModeDefault = off`：活动影响参数族必须单独授权，不能继承基准线模式。

不得在代码、测试夹具、数据库默认值或 UI 中绕过这些门。`review` 模式必须等总门和对应
`ProductionLearningEnabled` 开启后才能生成可执行候选；`automatic` 还必须通过对应
`AutoApplyEnabled`。

生命周期测试可以注入一个明确命名、版本化且只存在于测试 / 预生产构建的配置，其中开关和
所有参数完整定义；被测代码仍必须经过同一门禁。禁止用 mock 直接跳过 gate，预生产配置也
不得打包进正式 APK。

B1 尚未提供用户模式时，只能在项目作者明确同意影子审计后开启总门，且数据库结构保证候选
无法激活。schema v4 引入分参数族模式后，对应参数族的 `off` 必须停止其所有新的用户特定
学习运行，包括影子运行；不得以“只读”为由绕过用户关闭选择。

## 1. 五档比较映射

每日实际状态只转换为有序类别，不转换为精力数值：

| 实际状态 | actualOrdinal |
|---|---:|
| 耗尽 | 0 |
| 偏低 | 1 |
| 尚可 | 2 |
| 良好 | 3 |
| 充足 | 4 |

同一参考时刻的系统估计使用以下**比较档位**。它只用于估计与实际的方向性对齐，不替代首页
四档提醒，也不表示生理状态：

```text
estimate < 0                           -> estimatedOrdinal 0
estimate >= 0 && estimate * 4 < initialEstimate
                                       -> estimatedOrdinal 1
estimate * 2 < initialEstimate         -> estimatedOrdinal 2
estimate * 5 < initialEstimate * 4     -> estimatedOrdinal 3
otherwise                              -> estimatedOrdinal 4
```

边界采用严格小于：`0` 属于档位 1，正好 `25%` 属于档位 2，正好 `50%` 属于档位 3，
正好 `80%` 属于档位 4。`initialEstimate` 按现有规则始终大于 0；违反该不变量时观测不得进入
学习。

```text
alignmentDelta = actualOrdinal - estimatedOrdinal
alignmentDirection = sign(alignmentDelta)
```

学习只使用 `alignmentDirection` 和有序差异分布，不把 `alignmentDelta` 解释成应调整的精力
点数。

## 2. B1 影子证据最低门槛

```text
minimumEligibleObservationPairs = 14
minimumObservationSpanCalendarDays = 21
shadowWindowCount = 2
shadowWindowEligiblePairs = 7
```

在当前 `modelRegimeKey`（包含同一 `referenceType`）中按 `lifeDay + observedAt + id` 稳定排序，
取最近 14 条合格观测；较早 7 条为窗口 1，较晚 7 条为窗口 2。21 日跨度也在这 14 条的最早
与最晚参考生活日之间
计算。更早证据只进入长期描述性统计，不参与本次双窗口结论。

`observedAt` 是 schema 中的 UTC 提交时间；旧讨论稿中的 `capturedAt` 与它是同一语义，不新增
第二个字段。规范编码固定使用六位小数的 UTC `YYYY-MM-DDTHH:mm:ss.ffffffZ`。

这些值只回答“是否值得生成一次影子证据运行”，不定义持续方向、候选值或生产更新。B1-1
必须先发布新的、明确标记为 shadow-only 的候选算法配置，才能生成候选模型并做反事实回放；
shadow-only 配置仍不允许激活。生产配置必须经过该回放审计后另行发布。

## 3. 反馈负担限制

```text
maxSampledActivityFeedbackPromptsPerLifeDay = 0
```

B0 / B1 只允许用户主动从活动记录进入反馈。B3 生产学习必须通过新的规则配置版本明确：

- `activityFeedbackSamplingPolicyVersion`；
- 每生活日提示上限和跳过后的冷却；
- 不依赖“预测误差大小”或用户是否主动打开详情的稳定抽样方法；
- 被抽中活动、未响应和跳过的最小审计字段。

这些值未发布时，活动影响只能做研究报告，不能生成可执行候选。

## 4. 影子审计后必须发布的生产参数

### 4.0 通用自动应用参数

- `minimumAutomaticChangeNoticeDuration`：自动安排到最早生效生活日之间的最短可取消时间；
- `maximumProductionEvidenceAge`：生产学习允许使用的最旧证据年龄；
- `maximumCandidateLifetime`：待审核、稍后或待生效候选的最长生命周期；
- 拒绝、取消或撤回后的最短再次学习冷却期；
- 两个参数族同时就绪时的固定优先级；
- 模式切换时通知去重和提醒上限。

以上任一安全时间未定义时，不得生成或安排生产模型变化；不能简单把“下一生活日”当作必然
有足够取消时间。

### 4.1 基准线参数族

- 所有手动与自动基准线继续受既有绝对范围 `60～140` 约束；
- 生产允许的 `referenceType` 及多种来源同时达标时的固定优先级；
- 方向一致性阈值；
- 单次学习步长；
- 相对 baseline anchor 的累计自动变化边界（必须比绝对硬范围更严格或相等）；
- 激活或撤回后的冷却窗口；
- 自动应用后的恶化判定与暂停阈值；
- `review` 与 `automatic` 候选的不同安全门槛（若有）。

### 4.2 活动影响参数族

- 允许进入生产学习的采样来源和采样策略版本；
- 合格反馈最小样本数和覆盖日数；
- 方向与幅度一致性阈值；
- 同一键跨配置时长档位的一致性门；
- 至少“子类 × `consumption / recovery`”的模型键；
- 倍率范围、单次步长和取整方式；
- 恢复上限截断、零理论值和 `directionMismatch` 的排除策略；
- `directionMismatch` 触发该键停止生产倍率学习的否决阈值；
- 自动应用后的恶化判定、冷却和暂停阈值。

在这些值缺失时，正确行为是“不生成可执行候选”，不是使用旧版 `3 条 / 2 日 / 70%`、
`0.70～1.30` 或固定 `±3 / ±5 / ±8` 参数。B1 可以报告影子候选，但必须标明其不是生产
参数，也不能通过数据库默认值进入当前模型。
