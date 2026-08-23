# 精力值规则配置 v2（MVP-A）

## 0. 版本

```text
ruleVersion = energy-rules-v2-mvp-a
```

本文件是 MVP-A 数值参数的唯一来源。该版本不可原地修改；后续新版本只从下一个生活日起影响未来。

---

# 1. 通用约定

时长档位：

```text
15、30、45、60、90、120 分钟
```

每个“子类 × 时长”单元格独立产生正、零或负值：

- 正数：估计恢复
- 0：估计不变
- 负数：估计消耗

```text
theoreticalDelta = 当前规则单元格值
appliedDelta =
  theoreticalDelta > 0
    ? min(theoreticalDelta, initialEstimate - currentEstimate)
    : theoreticalDelta
```

MVP-A 不应用 personalFactor。

---

# 2. 活动规则表

## 2.1 学习

| 子类 | 15 | 30 | 45 | 60 | 90 | 120 |
|---|---:|---:|---:|---:|---:|---:|
| 上课 | -5 | -5 | -8 | -12 | -16 | -20 |
| 自学 / 论文 | -5 | -12 | -16 | -20 | -25 | -25 |
| 写作业 | -5 | -8 | -12 | -16 | -20 | -25 |
| 复习 / 备考 | -5 | -12 | -16 | -20 | -25 | -30 |
| 整理 / 总结 | 0 | -5 | -5 | -8 | -12 | -16 |
| 其他学习 | -5 | -8 | -12 | -16 | -20 | -25 |

## 2.2 实践 / 事务

| 子类 | 15 | 30 | 45 | 60 | 90 | 120 |
|---|---:|---:|---:|---:|---:|---:|
| 实现 / 开发 | -5 | -5 | -8 | -12 | -16 | -20 |
| 做实验 | -5 | -12 | -16 | -20 | -25 | -25 |
| 项目推进 | -5 | -5 | -8 | -12 | -16 | -20 |
| 调试 / 修改 | -5 | -12 | -16 | -20 | -25 | -30 |
| 组织 / 事务 | -5 | -8 | -12 | -16 | -20 | -25 |
| 其他事务 | -5 | -8 | -12 | -16 | -20 | -25 |

## 2.3 休息恢复

| 子类 | 15 | 30 | 45 | 60 | 90 | 120 |
|---|---:|---:|---:|---:|---:|---:|
| 午睡 / 小睡 | +5 | +10 | +10 | +15 | +15 | +10 |
| 轻活动 | +5 | +5 | +5 | +5 | +10 | -5 |
| 放空 / 调整 | +5 | +5 | 0 | 0 | -5 | -8 |
| 运动恢复 | +5 | +5 | +5 | +5 | +5 | -5 |
| 生活休整 | +5 | +5 | +5 | 0 | -5 | -5 |
| 其他恢复 | +5 | +5 | +5 | 0 | -5 | -5 |

## 2.4 娱乐消遣

| 子类 | 15 | 30 | 45 | 60 | 90 | 120 |
|---|---:|---:|---:|---:|---:|---:|
| 打游戏 | -5 | -5 | -12 | -12 | -20 | -25 |
| 刷视频 / 短内容 | 0 | -5 | -5 | -12 | -20 | -25 |
| 看剧 / 观影 | 0 | 0 | 0 | 0 | -5 | -12 |
| 聊天 / 社交 | +5 | 0 | 0 | -5 | -5 | -12 |
| 兴趣娱乐 | +5 | +5 | 0 | 0 | -5 | -5 |
| 其他娱乐 | 0 | 0 | -5 | -5 | -12 | -16 |

---

# 3. 早间确认

只有综合状态直接产生数值：

| 综合状态 | morningAdjustment |
|---|---:|
| 差 | -6 |
| 一般 | 0 |
| 好 | +6 |
| 跳过 | 0 |

以下输入保存为上下文，不直接增减：

- 可自由安排时间
- 主要压力来源
- 睡眠恢复感

```text
initialEstimate = baseEnergy + morningAdjustment + shortTermAdjustment
```

---

# 4. 短期透支修正

只读取紧邻的前一个生活日。前一生活日没有结算摘要时为 0，空生活日中断影响。

| 前一生活日 finalEstimatedEnergy | shortTermAdjustment |
|---:|---:|
| `>= 0` | 0 |
| `-1 ... -5` | -1 |
| `-6 ... -10` | -2 |
| `-11 ... -20` | -3 |
| `< -20` | -4 |

该修正是产品负荷延续机制，不是客观恢复测量，也不用于 MVP-A 长期基准线学习。

---

# 5. 估计档位

按顺序判断：

```text
currentEstimate < 0                       -> estimatedOverdraft
currentEstimate < initialEstimate * 0.25 -> estimatedLow
currentEstimate < initialEstimate * 0.50 -> estimatedMediumLow
otherwise                                 -> estimatedNormal
```

提醒文案必须包含“估计”语义。

---

# 6. 用户实际状态

每日绝对状态保存为枚举，不映射成伪精确数值：

```text
exhausted, low, okay, good, full
```

随时相对校正：

```text
lowerThanEstimate, aboutRight, higherThanEstimate
```

采集层只保存原始枚举、发生时间和对应生活日，不直接改变估计值。

---

# 7. 有效使用日

MVP-A 的描述性总结使用：

- 标准有效日：完成早间确认且至少有 1 条有效活动。
- 弱有效日：未完成早间确认但至少有 2 条有效活动。

两类日期都可进入滚动 7 个有效日总结。MVP-A 不据此推进自动校准周期。

---

# 8. 汇总与稳定排序

```text
totalConsumption = sum(abs(appliedDelta)) where appliedDelta < 0
totalRecovery = sum(appliedDelta) where appliedDelta > 0
categoryNetDelta = sum(appliedDelta)
categoryGrossDelta = sum(abs(appliedDelta))
```

事件顺序：

```text
completedAt ASC, createdAt ASC, id ASC
```

---

# 9. 版本生效

- 当前生活日开始时确定当天规则版本。
- 新规则从下一个生活日起生效。
- 当前生活日和历史记录不迁移。
- 每条活动记录保存 `ruleVersion`、`theoreticalDelta` 和 `appliedDelta`。
- MVP-A 不实现 `ruleMigrationReplay`。
