# PowerManager MVP-A 阶段 2：领域规则与纯算法验收

## 0. 文档状态

- 阶段：2 / 领域规则与纯算法
- 执行日期：2026-07-26
- 依据：《PowerManager MVP-A 分阶段开发计划 Spec v1》第 6 节
- 数值来源：《精力值规则配置 v2（MVP-A）》
- 机制来源：《精力值算法规则 v2（MVP-A）》
- 结果：通过

---

# 1. 阶段边界

本阶段只实现不依赖 UI、Flutter Binding、Drift 或 SQLite 的确定性领域规则：

- 稳定枚举与持久化代码；
- `LifeDay`、可注入 `Clock` 和 04:00 边界计算；
- `energy-rules-v2-mvp-a` 固定规则；
- 初始估计、理论变化、恢复上限、估计档位和短期透支修正；
- `completedAt, createdAt, id` 稳定重放；
- 分类净变化、绝对变化总量、时长和总消耗 / 总恢复；
- 标准有效日和弱有效日。

本阶段没有建立数据库表、Repository、应用用例或 UI 数据绑定。这些属于后续阶段。

---

# 2. 领域实现

## 2.1 稳定类型

已定义：

```text
ActivityCategory       4
ActivitySubcategory   24
DurationSlot           6
MorningOverallState
SleepRecovery
AbsoluteEnergyState
RelativeCorrection
EstimatedEnergyBand
ActivityRecordStatus
```

大类和子类使用独立稳定代码，不把中文显示名称当作数据库标识。用户实际状态保留原始枚举，不映射成估计数值。

## 2.2 生活日

`LifeDay` 是不含时间和时区的日历值对象，支持：

- 严格 `yyyy-MM-dd` 解析；
- 比较、前一日和后一日；
- 月末、闰年和年末正规化；
- 值相等语义。

`LifeDayCalculator` 使用本地时间 04:00 作为边界：

```text
03:59:59 -> 前一生活日
04:00:00 -> 当前生活日
04:00:01 -> 当前生活日
```

计算器可注入 `Clock`。系统时钟或时区变化只影响之后的新计算；已捕获并持久化的 `LifeDay` 值不被重新归属。实际持久化约束在阶段 3 落实。

## 2.3 版本化规则

规则版本：

```text
energy-rules-v2-mvp-a
```

内置规则完整编码了 24 个子类 × 6 个时长档位。配置及每行规则均为只读视图。

完整性校验覆盖：

- `ruleVersion` 非空；
- 无重复子类；
- 不缺少任何子类；
- 每个子类恰好 6 个时长档；
- 总计恰好 144 个单元格。

单元测试逐格断言全部 144 个数值，而不只检查数量。

## 2.4 估计算法

`EnergyCalculator` 实现：

```text
initialEstimate =
  baseEstimatedEnergy + morningAdjustment + shortTermAdjustment
```

- 综合状态：`-6 / 0 / +6`，跳过为 `0`；
- `100` 不作为上限；
- 短期修正只读取紧邻前一生活日摘要，空摘要为 `0`；
- 正变化受当日初始估计上限约束；
- 零或负变化不截断，允许估计进入负数；
- 档位使用整数交叉相乘，避免 25% / 50% 浮点误差。

用户实际状态没有进入任何估计计算函数。

## 2.5 稳定重放与汇总

`CurrentDayProjector`：

1. 过滤逻辑删除记录；
2. 按 `completedAt ASC, createdAt ASC, id ASC` 复制排序，不修改输入；
3. 从 `initialEstimate` 开始逐条重算 `appliedDelta`；
4. 输出当前估计、估计档位、逐条结果和分类汇总；
5. 分开输出 `netDelta` 与 `grossDelta`；
6. 判定标准有效日、弱有效日或非有效日。

活动时间戳必须是 UTC；记录同时携带非空 `ruleVersion`。恢复上限的顺序依赖通过完整重放保留，删除或编辑不能使用反向加减代替。

---

# 3. 测试发现与修复

## 3.1 月末和年末切换失败

首轮测试发现 `LifeDay.previous / next` 直接把 `day - 1 / day + 1` 传给严格构造器，导致：

```text
2025-12-31.next
2026-03-01.previous
```

被错误识别为非法日期。

修复方式：先使用 Dart 日历完成跨月 / 跨年正规化，再创建严格 `LifeDay`。修复后月末和年末测试通过。

## 3.2 恢复上限顺序依赖

测试确认同样的消耗和恢复记录在不同完成顺序下可能得到不同结果：

```text
先消耗 -20，再恢复 +10 -> 90
先恢复 +10，再消耗 -20 -> 80
```

这不是误差，而是恢复上限规则的预期结果。因此重放排序被集中在 `CurrentDayProjector`，调用方不能自行累加。

## 3.3 满值以上的防御性输入

按有效重放不变量，当前估计不会被恢复推到初始估计之上。纯函数仍对异常的 `currentEstimate > initialEstimate` 输入返回 `0` 恢复，而不是把正理论值错误转成负变化。

---

# 4. 验证证据

## 4.1 纯 Dart 领域测试

执行：

```text
dart test test/domain
```

结果：

```text
42 tests passed
```

测试文件只导入 `package:test` 和 `package:power_manager` 的纯领域代码；领域实现及测试均不导入 Flutter、Drift 或 SQLite。

覆盖内容：

- 三个 04:00 边界；
- 月末、年末、时钟回拨和非法边界；
- 4 × 6 分类结构及稳定枚举；
- 144 个规则值逐格匹配；
- 不完整、重复和空版本规则拒绝；
- 早间 `-6 / 0 / +6`；
- 短期修正全部五个区间及边界；
- 无前日摘要；
- 满值恢复、部分截断和防御性截断；
- 消耗进入负数；
- 恰好 0、25%、50% 及非整除阈值；
- 三字段稳定排序和输入顺序确定性；
- 逻辑删除排除；
- 顺序依赖完整重放；
- `grossDelta`、`netDelta`、时长和消耗 / 恢复分离；
- 标准有效日和弱有效日。

## 4.2 工程回归

阶段提交前已执行：

```text
dart format --output=none --set-exit-if-changed .  通过，24 个文件无变化
dart run build_runner build                       通过
dart test test/domain                             通过，42 / 42
flutter analyze                                   通过，No issues found
flutter test                                      通过，45 / 45
flutter build apk --debug                         通过
```

Debug APK 已在 `emulator-5554 / Pixel_7 / Android 14 API 34` 覆盖安装并冷启动，前台 Activity 为：

```text
com.kevin.powermanager/.MainActivity
```

---

# 5. 验收结论

| 验收项 | 结果 |
|---|---|
| Domain 测试不依赖 Flutter Binding 或 SQLite | 通过 |
| 4 大类、24 子类、6 时长档稳定定义 | 通过 |
| 144 个规则单元格完整且逐格匹配 | 通过 |
| `ruleVersion` 非空且规则不可变 | 通过 |
| 04:00、月末、年末边界 | 通过 |
| 初始估计和五档短期修正 | 通过 |
| 恢复上限和负数估计 | 通过 |
| 0 / 25% / 50% 精确档位 | 通过 |
| 三字段稳定排序和确定性重放 | 通过 |
| 删除记录不参与重放 | 通过 |
| 分类净值、绝对值和时长分离 | 通过 |
| 标准 / 弱有效日判定 | 通过 |
| 估计字段与用户实际状态语义分离 | 通过 |

阶段 2 的领域逻辑已具备进入阶段 3 数据层实现的条件。
