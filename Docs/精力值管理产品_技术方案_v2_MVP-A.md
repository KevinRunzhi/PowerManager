# 精力值管理产品 技术方案 v2（MVP-A）

## 0. 技术基线

```text
Flutter + Dart
Riverpod（不启用 Riverpod codegen）
Drift + SQLite
Flutter 原生路由
```

MVP-A 暂不引入 Freezed、go_router 和完整 JSON 代码生成体系。

目标平台先 Android，架构不写入 Android 专属领域逻辑。

---

# 1. 架构原则

采用精简本地分层：

```text
features     页面、组件、交互
application 用例编排与事务
domain      纯计算、生活日、重放、汇总
data        Drift 表、DAO、导出
```

原则：

- UI 不直接计算或写数据库。
- 领域规则优先纯函数。
- 当前日状态从源数据派生。
- 已结算历史读取不可变快照。
- MVP-A 没有自动学习和规则迁移。

推荐目录：

```text
lib/
  app/
  core/time/
  data/db/
  data/repositories/
  domain/energy/
  domain/life_day/
  application/
  features/home/
  features/activity/
  features/check_in/
  features/observations/
  features/summary/
  features/settings/
  shared/
```

---

# 2. 数据模型

## 2.1 app_settings

| 字段 | 说明 |
|---|---|
| id | 固定单行 |
| baseEnergy | 当前个人基准线 |
| pendingBaseEnergy | 下一生活日待生效值 |
| baseEnergyEffectiveLifeDay | 生效生活日 |
| activeRuleVersion | 当前规则版本 |
| pendingRuleVersion | 下一生活日待生效规则 |
| pendingRuleEffectiveLifeDay | 待生效规则对应的生活日；与 pendingRuleVersion 成对为空或成对有值 |
| onboardingCompleted | 首次说明完成状态 |
| createdAt / updatedAt | UTC 时间 |

## 2.2 morning_check_ins

| 字段 | 说明 |
|---|---|
| id | UUID |
| lifeDay | 唯一 |
| overallState | bad / normal / good |
| freeTimeLevel | low / medium / high |
| pressureSource | study / practice / both / low |
| sleepRecovery | bad / normal / good |
| morningAdjustment | 保存当时值 |
| completedAt | UTC |

## 2.3 activity_records

| 字段 | 说明 |
|---|---|
| id | UUID |
| lifeDay | 记录归属 |
| completedAt | 大致完成时间，UTC |
| createdAt / updatedAt | UTC |
| category / subcategory | 稳定枚举 |
| durationMinutes | 固定档位 |
| theoreticalDelta | 规则结果 |
| appliedDelta | 最近一次当天重放结果 |
| ruleVersion | 计算版本 |
| status | active / deleted |
| deletedAt | 逻辑删除时间 |

约束：

- 默认查询只处理 active。
- 已结算生活日不允许修改。
- 同一天记录按 `completedAt, createdAt, id` 排序。

## 2.4 energy_observations

| 字段 | 说明 |
|---|---|
| id | UUID |
| lifeDay | 生活日 |
| type | dailyAbsolute / relativeCorrection |
| absoluteState | exhausted / low / okay / good / full |
| relativeState | lower / aboutRight / higher |
| estimateAtObservation | 当时估计，可空 |
| observedAt | UTC |

约束：

- 每个 lifeDay 最多一条 dailyAbsolute。
- relativeCorrection 可多条。
- 原始枚举不可被数值映射覆盖。

## 2.5 daily_summaries

| 字段 | 说明 |
|---|---|
| lifeDay | 主键 |
| baseEnergy | 当日基准线 |
| ruleVersion | 当日规则 |
| morningAdjustment | 早间修正 |
| shortTermAdjustment | 短期修正 |
| initialEstimatedEnergy | 初始估计 |
| finalEstimatedEnergy | 最终估计 |
| totalConsumption / totalRecovery | 汇总 |
| categorySummaryJson | 分类汇总 |
| isStandardEffectiveDay | 标准有效日 |
| isWeakEffectiveDay | 弱有效日 |
| settledAt | UTC |

快照在 MVP-A 中不可更新。

每日实际状态保留在 `energy_observations`，历史页面按 lifeDay 关联读取。这样用户可以在下一生活日补充上一日实际状态，而不修改已经冻结的计算快照。

## 2.6 prompt_receipts

| 字段 | 说明 |
|---|---|
| id | UUID |
| type | onboarding / morning / dailyObservation / yesterday / energyBand |
| scopeKey | 去重键 |
| action | shown / skipped / dismissed |
| occurredAt | UTC |

`type + scopeKey + action` 按业务需要建立唯一约束。它只负责回执，不承担复杂周期状态机。

## 2.7 rule_config_versions

| 字段 | 说明 |
|---|---|
| version | 主键 |
| valuesJson | 24 × 6 固定表和相关参数 |
| createdAt | UTC |

已被记录引用的版本不可原地修改。

---

# 3. 领域服务

## 3.1 LifeDayCalculator

纯函数：

```text
lifeDayFor(localDateTime, boundaryHour = 4)
```

保存 UTC 时间戳，创建记录时持久化 lifeDay。时区改变不重新归属历史。

## 3.2 EnergyCalculator

纯函数：

```text
calculateInitialEstimate(base, morning, shortTerm)
calculateTheoreticalDelta(ruleVersion, subcategory, duration)
calculateAppliedDelta(theoretical, current, initial)
calculateBand(current, initial)
```

## 3.3 CurrentDayProjector

输入：

- 当日基准线和规则版本
- MorningCheckIn
- 前一生活日 DailySummary
- 当日 active ActivityRecord

输出：

- initialEstimate
- currentEstimate
- 每条 appliedDelta
- 档位和分类汇总
- 有效日状态

它是当前日单一派生入口。

## 3.4 SettlementService

职责：

- 结算存在源数据但尚无摘要的过去生活日
- 写入唯一 DailySummary
- 重复调用幂等
- 不为空生活日创建摘要

## 3.5 OperationPreparationService

所有启动、回前台和业务写操作先调用：

1. 计算目标生活日。
2. 从旧到新结算更早生活日。
3. 应用到期的 pendingBaseEnergy 和 pendingRuleVersion。
4. 返回当前日上下文。

---

# 4. 应用用例

## 4.1 CreateActivity

事务：

1. prepare
2. 校验目标为当前生活日
3. 使用当日规则计算 theoreticalDelta
4. 插入记录
5. CurrentDayProjector 重放
6. 批量刷新当天 active 记录 appliedDelta

## 4.2 EditActivity

事务：

1. prepare
2. 校验记录属于当前未结算生活日
3. 就地更新字段和 updatedAt
4. 使用当天 ruleVersion 重算 theoreticalDelta
5. 重放当天

## 4.3 DeleteActivity

事务：

1. prepare
2. 校验当前生活日
3. 标记 deleted 并写 deletedAt
4. 重放当天

## 4.4 SaveMorningCheckIn

事务：

1. prepare
2. upsert 当天唯一记录
3. 只根据 overallState 计算 morningAdjustment
4. 重放当天

## 4.5 SaveObservation

- dailyAbsolute：同一 lifeDay 唯一
- relativeCorrection：保存当时 estimate 快照
- 不触发规则或基准线更新

---

# 5. 规则版本

- App 首次运行插入 `energy-rules-v2-mvp-a`。
- 每个生活日开始时确定当天规则版本。
- 新版本写入 pendingRuleVersion，从下一生活日起生效。
- 当前生活日和历史不迁移。
- 不实现 ruleMigrationReplay。

---

# 6. 提示与交互

- 点击式记录流程首先完整交付。
- 能量球手势只产生临时选择，确认后调用同一 CreateActivity。
- 5 秒快捷撤销调用 DeleteActivity。
- 超时后仍可从当天记录列表编辑或删除。
- 能量档位提示在撤销窗口结束后生成 prompt receipt。

---

# 7. 测试

## 7.1 Domain

- 04:00 边界
- 初始估计
- 短期修正
- 24 × 6 规则完整性
- 恢复上限
- 稳定排序
- 当前日派生
- 汇总口径

## 7.2 Data

- 七张表迁移
- 唯一约束
- 逻辑删除过滤
- DailySummary 不可重复
- 事务失败回滚

## 7.3 Application

- 创建、补记、编辑、删除后派生一致
- 补做早间后重放
- 持续前台跨 04:00
- 多次 prepare 幂等
- 已结算历史拒绝修改
- 新基准线和规则只在下一生活日生效

## 7.4 Widget / 真机

- 点击式完整记录
- 每日实际状态先选后展示估计
- 随时校正
- 当天纠错
- 能量球回滑和取消
- 手势 20 次任务至少 18 次成功且零错误记录

---

# 8. 里程碑

1. 工程骨架与数据库
2. 生活日、规则和当前日派生
3. 点击式活动记录与当天纠错
4. 早间确认、实际状态和随时校正
5. 首页、概览、提醒和结算摘要
6. JSON 导出
7. 能量球手势原型与真机验证
8. 7 日自用验证
