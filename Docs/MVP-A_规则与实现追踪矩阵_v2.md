# MVP-A 规则与实现追踪矩阵 v2

| 能力 | PRD | 规则 / 算法 | Backlog | 技术落点 | 主要验证 |
|---|---|---|---|---|---|
| 双轨状态 | PRD 1、4.3、4.4 | 算法 1、6 | EPIC 5 | energy_observations、CurrentDayProjector | 实际状态不覆盖估计 |
| 个人基准线 | PRD 3.2 | 规则 3 | US-8.1 | app_settings、OperationPreparationService | 下一生活日生效 |
| 04:00 生活日 | PRD 3.3 | 算法 5 | US-2.1、2.3 | LifeDayCalculator、SettlementService | 三个边界时间、幂等 |
| 早间确认 | PRD 4.1 | 规则 3 | US-3.1 | morning_check_ins、SaveMorningCheckIn | 只有综合状态计分 |
| 活动规则 | PRD 5、6 | 规则 1、2 | US-4.1 | rule_config_versions、EnergyCalculator | 24 × 6 完整性 |
| 当天纠错 | PRD 6.2 | 算法 4 | US-4.2、4.3 | EditActivity、DeleteActivity | 编辑删除后完整重放 |
| 恢复上限 | PRD 7.2 | 规则 1、算法 3 | US-2.2 | EnergyCalculator | 顺序依赖和边界 |
| 短期修正 | PRD 7.1 | 规则 4 | US-2.2 | CurrentDayProjector | 空生活日中断 |
| 每日结算 | PRD 4.5 | 算法 5 | US-2.3 | daily_summaries、SettlementService | 快照唯一且不可变 |
| 今日概览 | PRD 7.4 | 规则 8 | US-6.1 | CurrentDayProjector | gross 排序、net 展示 |
| 提示回执 | PRD 7.3 | 规则 5 | US-6.2 | prompt_receipts | 同范围去重 |
| 滚动总结 | PRD 4.5、8 | 算法 7 | US-6.3、6.4 | daily_summaries + observations 查询 | 只描述、不建议 |
| 规则版本 | PRD 6.3 | 规则 9、算法 4 | US-8.2 | rule_config_versions、pendingRuleVersion | 未来生效、历史冻结 |
| JSON 导出 | PRD 8 | 规则版本元数据 | US-8.3 | ExportService | 七类数据和删除记录 |
| 能量球手势 | PRD 4.2、10 | 无业务新规则 | EPIC 7 | 单一 CreateActivity 用例 | 真机 18/20 且零错记 |
| MVP-B 门槛 | PRD 9 | 算法 8 | US-9.2 | MVP-A 不实现 | 至少 14 个真实观测日 |

## 复核结论

- 产品行为、参数、算法、用户故事和技术落点均有唯一来源。
- MVP-A 没有自动基准线调整、personalFactor 更新、CalibrationCycle 或规则迁移。
- `DailySummary` 只冻结系统计算结果；可在下一生活日补充的实际状态保存在独立观测表中。
- 当前生活日纠错只触发单日重放，不产生跨日级联。
