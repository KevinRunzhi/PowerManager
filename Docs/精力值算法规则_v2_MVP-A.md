# 精力值算法规则 v2（MVP-A）

## 0. 定位

本文档解释 MVP-A 的计算机制。具体参数以《精力值规则配置 v2（MVP-A）》为唯一来源。

核心不变量：

1. 系统估计与用户实际状态分离。
2. MVP-A 使用固定规则，不自动学习。
3. 当前生活日允许重算，已结算历史冻结。
4. 新规则只影响未来。

---

# 1. 双轨状态

## 1.1 系统估计

```text
initialEstimate = baseEnergy + morningAdjustment + shortTermAdjustment
currentEstimate = replay(initialEstimate, activeRecords)
```

它是可解释的产品估计，不是用户真实状态或能力评分。

## 1.2 用户实际状态

用户观测单独保存：

- 每日一次五档绝对状态
- 当天任意次数三档相对校正

观测不会就地覆盖 `currentEstimate`。页面可以并列展示估计、实际选择和差异。

---

# 2. 当前生活日派生

当前生活日不维护可变 `DailyEnergyState`。

每次读取或修改后：

1. 读取当天生效的基准线和规则版本。
2. 读取早间确认，计算 `morningAdjustment`。
3. 读取紧邻前一生活日摘要，计算 `shortTermAdjustment`。
4. 从 `initialEstimate` 开始重放当天有效记录。
5. 派生当前估计、档位、总消耗、总恢复和分类汇总。

当天记录数量有限，优先保证单一真相来源和可测试性。

---

# 3. 活动记录计算

创建或编辑记录时：

```text
theoreticalDelta = ruleConfig[ruleVersion][subcategory][duration]
```

正值应用恢复上限：

```text
appliedDelta = min(theoreticalDelta, initialEstimate - currentEstimate)
```

零或负值：

```text
appliedDelta = theoreticalDelta
```

MVP-A 不使用 `personalFactor`。

---

# 4. 重放

只保留普通重放语义：

```text
energy = initialEstimate
for record in activeRecords
    ordered by completedAt, createdAt, id:
  record.appliedDelta =
    applyRecoveryCap(record.theoreticalDelta, energy, initialEstimate)
  energy += record.appliedDelta
```

重放触发：

- 新增活动
- 补记活动
- 编辑活动
- 删除活动
- 补做早间确认

编辑活动时按所属生活日的 `ruleVersion` 重新计算该记录 `theoreticalDelta`，然后重放当天。

删除使用逻辑删除，默认查询和重放只处理有效记录。

MVP-A 没有规则迁移重放。

---

# 5. 生活日结算

04:00 后首次启动、回前台或业务写操作前执行幂等准备：

1. 计算当前生活日。
2. 查找存在数据但尚未生成摘要的更早生活日。
3. 按生活日从旧到新派生最终结果。
4. 每个生活日写入唯一 `DailySummary`。
5. 当前生活日只返回派生上下文，不创建空摘要。

`DailySummary` 形成后在 MVP-A 中不可修改。

空生活日：

- 无早间确认
- 无有效活动
- 无实际状态观测

空生活日不生成摘要。

---

# 6. 每日实际状态与校正

## 6.1 每日绝对状态

每个生活日最多一条 daily observation。

交互顺序：

1. 用户先选择实际状态。
2. 保存原始枚举。
3. 再展示结算时或当前时刻的系统估计。
4. 生成描述性差异，不映射为伪精确能量值。

## 6.2 随时相对校正

相对校正绑定：

- 生活日
- 发生时间
- 当时 `currentEstimate`
- 用户选择

它用于复盘估计偏差。MVP-A 不根据单次校正改变规则。

---

# 7. 描述性总结

昨日和滚动 7 个有效日总结可以展示：

- 初始和最终估计
- 实际状态
- 相对校正次数与方向
- 总消耗和总恢复
- 大类时长与净变化
- 估计低精力和透支次数

禁止：

- 把 finalEstimatedEnergy 称为实际结果
- 生成自动能力判断
- 使用估计结果调整长期基准线
- 把每日整体偏差归因给某个活动

---

# 8. MVP-B 入口条件

## 8.1 基准线建议

至少需要 14 个带每日实际状态的有效日。

未来算法比较的是：

```text
systemEstimate vs userObservedState
```

不得继续使用：

```text
finalEstimatedEnergy -> 调整产生它的 baseEnergy
```

只生成小幅建议，用户确认后从下一生活日起生效。

## 8.2 子类参数建议

只使用与具体活动绑定的直接反馈。

当前只规定不变量：

- 多条反馈
- 覆盖多个生活日
- 同方向明显占多数
- 单次小步建议
- 用户确认
- 不反转活动方向

具体阈值等待 MVP-A 数据后制定。
