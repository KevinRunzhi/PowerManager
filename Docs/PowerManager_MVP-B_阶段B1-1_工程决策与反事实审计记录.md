# PowerManager MVP-B 阶段 B1-1：工程决策与反事实审计记录

## 0. 结论

- 日期：2026-08-15
- 实现起点：`f5b6849`（B1-0 阶段提交）
- 工程轨：**通过，可以进入 B2-0**
- 产品轨：**inconclusive**，等待 MVP-B 全部工程完成后的真机自然使用
- 数据库：保持 schema v3，不修改已发布 DDL
- 正式生产门：四项全部保持 `false`
- 真机与 APK：本阶段不执行

本阶段形成的是带强水印、不可发布的工程输入，用于证明 B2 生命周期可以在明确参数下实现和
验证。它不回答“真实用户是否应该采用这些阈值”，不授权生成或激活正式个人模型。

## 1. 第一次证据审计

### 1.1 正常模拟器数据

B1-0 结束时的匿名聚合为：

| referenceType | eligible | B1 最低门 | 结论 |
|---|---:|---:|---|
| currentMoment | 1 | 14 条、21 日、2 × 7 | insufficientEvidence |
| previousLifeDayEnd | 0 | 14 条、21 日、2 × 7 | insufficientEvidence |

现有模拟器数据不足以比较两种来源的真实完成负担、理解一致性或方向稳定性。因此：

- 不选择任何生产 referenceType；
- 不发布生产方向阈值、步长或自动应用授权；
- 不把 B1-0 的隔离 14 条 fixture 记为自然证据；
- 产品状态保持 `inconclusive`。

### 1.2 冻结工程 fixture

工程 fixture 只证明合同和边界：

- 13 条、跨度 24 日得到 `insufficientEvidence`；
- 第 14 条、跨度 26 日得到 `readyForAudit`；
- 14 条稳定分为 `[7, 7]`，重启和相同输入零新增；
- currentMoment 与 previousLifeDayEnd 不合并，model regime 不拼接；
- candidate 始终为 SQL `NULL`，base、rule 和 pending 字段不变化。

fixture 可以放行第二次离线回放，但不能放行生产门。

## 2. 发现并关闭的 P0 合同缺口

### 2.1 schema v3 与 shadow-only 候选矛盾

schema v3 已冻结以下 CHECK：

```text
algorithmVersion = evidence-shadow-v1
configVersion = evidence-readiness-14x21-v1
candidateValuesJson IS NULL
```

B1-1 又要求新 shadow-only 算法输出候选。若在不升 schema 的前提下持久化非空候选，就必须篡改
已发布 v3 DDL 或绕过 CHECK，两者都会破坏迁移与备份合同。

最终裁决：

- B1-1 候选回放是纯函数和离线报告，不写 `learning_runs`；
- 离线候选 JSON 强制包含
  `PREPRODUCTION_ONLY_DO_NOT_ACTIVATE_OR_SHIP` 与
  `activationAllowed = false`；
- 正常 App、Provider、DAO、备份和 Data Health 均不读取这套预生产配置；
- schema v4 才重建 `learning_runs`，支持正式候选结果并引用源个人模型。

### 2.2 “恰好一个 active”不能只靠唯一索引

SQLite partial unique index只能保证“最多一个 active”，不能在允许状态转换的同时以普通行级
CHECK 保证“至少一个 active”。最终裁决是：

- 数据库 partial unique index保证最多一个；
- 参数列不可变触发器、禁止删除和合法状态转换触发器缩小破坏面；
- 创建、激活、撤回在单事务内保持旧 active 与新 active 的交接；
- onCreate、onUpgrade、restore 和每次 prepare 后运行完整性验证，要求恰好一个；
- 不在文档中虚构 SQLite 本身能表达的约束。

### 2.3 B2-2 缺少可持久化监测结果

原 learning result 列表没有 `improved / worsened`，无法明确保存恶化暂停依据。schema v4 最终
合同把两者加入受支持结果；监测仍复用不可变 learning run 的证据、hash、算法和配置，不另造
无法重放的布尔标志。

### 2.4 持久通知仅靠系统通知不完整

B2-2 暂停通知不一定对应一个新候选版本，单靠模型行的 `noticeCreatedAt` 也无法表达多种通知与
去重。schema v4 最终合同增加 `learning_notices`，App 内记录与安排 / 暂停状态原子提交；系统
通知只做增强。

### 2.5 基准线真源与历史引用

schema v4 后 `app_settings` 删除三个 legacy base 字段；active personalization version 是唯一
可写真源。新 daily summary 保存 personalization version 引用；迁移前历史使用显式 legacy 空引用
并继续依赖已冻结的 inline base/rule，不伪造当时不存在的版本。

## 3. 预生产配置

### 3.1 身份与发布边界

```text
algorithmVersion = baseline-shadow-replay-v1
configVersion = preprod-baseline-lifecycle-v1-do-not-ship
watermark = PREPRODUCTION_ONLY_DO_NOT_ACTIVATE_OR_SHIP
activationAllowed = false
baselineProductionLearningEnabled = false
baselineAutoApplyEnabled = false
```

数值只存在于本文、测试支持文件和显式预生产测试输入。正式 App 不提供默认实例，不能由运行时
开关把它升级为生产配置。

### 3.2 证据与方向门

| 参数 | review 工程门 | automatic 工程门 |
|---|---:|---:|
| eligible / span / windows | 14 / 21 日 / 2 × 7 | 14 / 21 日 / 2 × 7 |
| 每窗同向最少 | 5 / 7 | 6 / 7 |
| 两窗同向合计最少 | 10 / 14 | 12 / 14 |
| 每窗允许反向最多 | 1 | 0 |
| 两窗方向 | 必须相同 | 必须相同 |

工程来源优先级为 `currentMoment → previousLifeDayEnd`。这是为了覆盖选择器，不是生产来源结论；
两个来源始终分别运行，不能投票或互补。

### 3.3 候选与反事实门

```text
singleStep = 2
anchorCumulativeLimit = ±8
hardRange = 60..140
minimumAlignedGain = 1 / 14
minimumTotalAbsoluteOrdinalErrorReduction = 1
```

回放把基准线差值 `delta` 同时应用到冻结的 `estimateAtObservation` 和
`initialEstimateAtObservation`，再使用正式五档比较器重算。它是局部、方向性反事实，不宣称
因果或统计显著。

候选必须同时满足：

- aligned 数量不下降且至少增加 1；
- opposite 数量不增加；
- total absolute ordinal error 不增加且至少减少 1；
- 完整步长不越过 anchor 边界与 60～140；不做部分 clamp；
- source regime、referenceType 和冻结证据结构完整。

### 3.4 B2 生命周期工程时间

| 参数 | 预生产值 |
|---|---:|
| minimumAutomaticChangeNoticeDuration | 24 小时 |
| maximumProductionEvidenceAge | 45 天（以最旧选中证据计） |
| maximumCandidateLifetime | 7 天 |
| rejected cooldown | 14 天 |
| canceled cooldown | 14 天 |
| reverted cooldown | 28 天 |
| activated cooldown | 21 天 |
| manual baseline change cooldown | 21 天并切新 epoch |
| deferred reminder interval | 至少 72 小时 |
| deferred reminders | 每候选最多 2 次 |
| 参数族同时就绪 | baseline 优先；完成激活与观察冷却后再处理 activityImpact |

automatic 的生效生活日必须严格晚于当前 lifeDay，并且其 04:00 距安排时间不少于 24 小时；否则
继续向后选择，不把“下一生活日”当成固定答案。

### 3.5 生效后监测工程门

- 新 epoch 独立收集 14 条、21 日、2 × 7；旧 epoch 不补样本；
- 最小有用改善：相对来源窗口 aligned 至少增加 2，total absolute ordinal error 至少减少 2；
- 不恶化：aligned 不下降、预期反向总数不超过 2 / 14 且每窗不超过 1；
- 明确恶化并暂停：两个窗口各至少 5 / 7 为预期反向，或 aligned 至少减少 3 且 absolute ordinal
  error 至少增加 3；
- 暂停保持当前 active，不自动回滚；提供保持、未来撤回和人工恢复；
- 最近 4 个具备完整观察窗的变化中，取消 / 撤回 / 暂停任一比例超过 25% 时，不得判定产品
  validated；样本不足 4 个时保持 inconclusive；
- 自动撤回在本配置中固定关闭。

这些门只用于 B2-2 状态机边界测试，不是产品有效性阈值。

## 4. 反事实矩阵

| 冻结输入 | 模式 / 参数 | 结果 | 安全结论 |
|---|---|---|---|
| 每窗 5 lower + 2 aligned | review，step 2 | 100 → 98 candidate | 10 lower 变为 aligned，水印存在 |
| 同上 | automatic | unstable | 未达到每窗 6 条，不能自动 |
| 每窗 6 lower + 1 aligned | automatic，step 2 | 100 → 98 candidate | 12 lower 改善，零反向 |
| 每窗 6 higher + 1 aligned | automatic，step 2 | 100 → 102 candidate | 方向只能向上 |
| 14 aligned | review | noChange | 不为了产生版本而变化 |
| 窗口 1 lower、窗口 2 higher | review | unstable | 连续窗口冲突 |
| 13 条 | review | insufficientEvidence | 不降门槛 |
| 稳定 lower | step 1 | noChange | fixture 上未产生最小有用改善 |
| 稳定 lower | step 5 | noChange | 4 条原 aligned 被推向反向，判过度反应 |
| base 60 且方向向下 | automatic | noChange | hard range 拒绝完整步长 |
| anchor 100、current 93、方向向下 | automatic | noChange | 候选 91 越过 ±8 anchor 边界 |
| 未允许 referenceType | 任意 | configurationBlocked | 来源 fail-closed |
| activationAllowed = true 或水印错误 | 任意 | configurationBlocked | 配置 fail-closed |
| 冻结 JSON 结构损坏 | 任意 | configurationBlocked | 不生成候选 |

纯函数没有 repository、DAO、Provider、settings 或 activation 依赖；候选 JSON 不是 schema v3
候选格式，也不会进入备份。

## 5. 产品决策

| 决策项 | 当前结论 |
|---|---|
| 真实填写负担 | 未验证 |
| 生产 referenceType | 未选择 |
| 生产方向阈值 | 未发布 |
| 生产步长与累计边界 | 未发布 |
| 生产 review / automatic 安全差异 | 未发布 |
| baselineProductionLearningEnabled | false |
| baselineAutoApplyEnabled | false |
| 产品状态 | inconclusive |

工程轨允许 B2 使用第 3 节参数走真实门禁和状态机；任何正式构建、最终 APK 或真机路径仍必须
读取生产门为 false。最终真机自然实验可以确认、修改或拒绝全部预生产数值。

## 6. 自动化与模拟器验证

### 6.1 自动化

- `dart format --output=none --set-exit-if-changed .`：131 个文件，0 变化；
- `flutter analyze`：0 问题；
- B1-1 反事实定向测试：11 项通过；
- `flutter test --coverage --reporter compact`：342 项通过，0 失败；
- 行覆盖：7969 / 11286（70.61%）；
- tampered snapshot、错误水印和 `activationAllowed = true` 均 fail-closed；
- 静态依赖检查确认正常 Provider、DAO、backup 和 UI 没有预生产配置引用。

### 6.2 Pixel_7 模拟器

- ADB 只发现 `emulator-5554`；未连接或操作物理手机；
- 不重新安装、不构建交付 APK，复用已安装 `0.1.4+10012` 做只读验证；
- 重启前后均为 schema v3、base 100、2 条 `insufficientEvidence` learning run、0 非空
  candidate、0 personalization version；
- 当前规则仍为 `energy-rules-v2-mvp-a`；
- UI dump 不含“预生产”、watermark 或候选入口，正常 App 首页可用；
- 重启日志没有 Flutter fatal、SQLiteException、DriftRemoteException、Crash 或 ANR。

这次模拟器检查只证明 B1-1 没有把离线配置泄漏到正常 App，不把现有聚合当作真实产品实验。

## 7. 阶段产物

- 本工程决策与反事实审计记录；
- `PowerManager_MVP-B_阶段B1-1_模式与通知UI_Spec_v1.md`；
- `PowerManager_MVP-B_阶段B2-0_SchemaV4最终迁移决策_v1.md`；
- `BaselineShadowReplayEngine` 纯函数；
- 测试专用 `preprod-baseline-lifecycle-v1-do-not-ship` 配置；
- 反事实、边界、水印与损坏输入自动化测试；
- 更新后的配置、算法、技术方案、阶段 Spec 和追踪矩阵。

## 8. 放行决定

B1-1 工程轨所需输入已经无空值，且 schema v3 候选写路径仍为物理不可达。允许开始 B2-0 的
schema v4 与模型生命周期实现。真实观察记录、负担结论和生产参数决定继续登记为待最终安装项，
不得在后续工程阶段被自动改写为 validated。
