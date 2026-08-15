# PowerManager MVP-B 阶段 B0-2：Schema v2 与备份兼容 Spec v1

## 0. 文档状态

- 版本：1.0
- 日期：2026-08-15
- 状态：待 B0-1 通过后实现
- 数据库版本：schema v1 升级到 schema v2
- 备份版本：支持导入 1，当前导出 2
- 下一阶段：B0-3 正确观测与活动反馈合同

## 1. 阶段目标

以单次可回滚迁移增加 MVP-B 证据存储能力，同时保持现有七类数据、历史页面、结算结果和
固定规则语义不变。迁移后仍不运行任何学习器。

## 2. 前置门

只有同时满足下列条件才允许构建或安装 schema v2 版本：

- B0-1 真机最新备份可解析且恢复演练通过；
- 当前数据体检无 P0 一致性错误；
- latest 备份已导出到 App 沙箱外的用户可控位置；
- schema v1 fixture 和真实聚合基线已经记录；
- migration 测试可以从真实 v1 DDL 创建数据库，而不是从当前表定义伪造旧库。

## 3. Schema 变更

### 3.1 energy_observations

按技术方案增加 nullable 的 observation contract v1 快照列。legacy 行全部保持新增列为空或
legacyUnknown，禁止推算旧估计、模型、覆盖状态或档位。

通过表重建完成组合 CHECK：

- contractVersion 为空时允许 legacy 结构；
- contractVersion 为 mvp-b-observation-v1 时，全部必需快照字段完整；
- referenceType、coverageState、ordinal 和计数只能取受支持值；
- initialEstimateAtObservation 必须大于 0；
- existing dailyAbsolute 生活日唯一约束继续存在；
- relativeCorrection 的 MVP-A 约束不被新合同放宽。

重建必须显式复制所有旧列，重建索引和触发器，并在事务内核对行数。

### 3.2 activity_feedback

新增 B0 版表，字段和约束以技术方案 2.2 节为准：

- activityRecordId 外键 RESTRICT；
- direction、impactSign、status 使用 CHECK；
- active 反馈的 invalidationReason 为空；
- invalidated 反馈必须有 reason；
- 同一活动最多一个 active 反馈；
- observedAt 与活动快照时间使用 UTC；
- schema v2 所有反馈语义均为 userInitiated，不提前增加伪抽样字段。

### 3.3 索引与触发器

- observation 按 lifeDay、type 和 contractVersion 查询；
- feedback 按 activityRecordId、lifeDay、status 查询；
- 活动删除或实质编辑的同步失效由 B0-3 用例事务负责，B0-2 只建立必要约束；
- 原有日总结不可变、规则保护和 settings 单例触发器必须重建并验证。

## 4. 迁移算法

单个 Drift onUpgrade 事务执行：

1. 验证 oldVersion 恰为 1；
2. 关闭仅阻挡表重建的保护触发器；
3. 创建 v2 临时 observation 表；
4. 逐列复制 v1 observation，新增字段写 legacy 值；
5. 核对源表和临时表数量、主键、唯一键；
6. 替换旧表并重建索引；
7. 创建 activity_feedback；
8. 恢复全部保护触发器；
9. 执行 foreign_key_check、integrity_check 和 schema 自检；
10. 提交。

任一步失败必须回滚到完整 v1。禁止捕获异常后创建空 v2 数据库继续启动。

## 5. 备份合同 v2

### 5.1 导出

在 v1 顶层合同上增加：

- schemaVersion = 2；
- observation 的全部新 nullable 字段；
- activityFeedback 数组；
- 仍包含原七类数据和 appSettings。

导出顺序必须稳定，invalidated feedback 也必须导出。

### 5.2 导入

- v1：新增 observation 字段映射为 legacy，activityFeedback 为空；
- v2：严格验证新合同字段组合、外键、唯一 active feedback 和快照一致性；
- 大于 2：在替换数据库前拒绝；
- 损坏或未知枚举：在任何数据库写入前拒绝；
- 恢复采用安全快照、事务替换、完整性检查、内存状态重建的既有顺序。

恢复 v1 备份到 v2 App 后，重新导出必须是合法 v2，但不得让旧观测获得学习资格。

## 6. 实现边界

预计修改：

- Drift tables、database、migration；
- converters、entities、repositories 和 DAO；
- export DTO、codec、export、restore；
- Data Health 的 schema 与 legacy 统计；
- fixture 和数据库测试。

不实现每日新合同保存 UI，不实现活动反馈 UI，不注册学习协调器，不手改生成文件。

## 7. 自动化测试

### 7.1 Migration fixture

- 空 v1、最小 v1、全表 v1、包含逻辑删除、相对校正、pending base 和保护触发器的 v1；
- 原七表逐字段相等；
- 所有 v1 observation 为 legacy；
- ID、UTC 时间、枚举和 JSON 字段字节语义不变；
- 新 CHECK、唯一索引和外键有效；
- 清空后、复制中和重建触发器前的失败注入全部回滚；
- 重启升级只执行一次。

### 7.2 Backup

- v1 导入到 v2；
- v2 完整往返；
- invalidated feedback 往返；
- activityRecordId 缺失、重复 active、快照字段残缺、未知枚举被拒绝；
- 替换中途失败保留原数据库和触发器；
- 恢复后再导出通过严格解析。

### 7.3 回归

- MVP-A 结算、投影、历史、设置和提醒测试；
- schema 初始化与约束测试；
- format、analyze、全量 test、coverage、debug APK；
- git diff --check 和生成文件一致性。

## 8. 真机升级步骤

1. 确认 B0-1 已准备状态；
2. 记录七类聚合、当前生活日、当前 base、active rule 和 pending 设置；
3. 安装 v2 APK 覆盖升级，不卸载、不清数据；
4. 首次启动完成迁移后立即执行 Data Health；
5. 对比升级前后聚合、历史页、当前投影和设置；
6. 保存 v2 latest 备份并回读；
7. 重启 App 再次验证；
8. 不在本阶段创建新合同观测或反馈；
9. 将匿名化计数和结论写入验收记录。

## 9. 停止与回退

以下任一情况命中即停止：

- 迁移前备份不可用；
- 任一旧字段变化或历史摘要重算；
- legacy 行获得新合同资格；
- 外键、保护触发器或唯一约束缺失；
- App 迁移失败后进入空库；
- v1 备份不能在 v2 App 中恢复；
- 真机聚合不一致。

已成功升级的数据库不能直接安装 schema v1 App 降级。回退方式是保留 v2 原库和 v1 外部备份，
修复迁移版本后再覆盖安装；只有用户明确同意时才从已验证备份恢复。

## 10. 退出证据

- migration 与 backup 测试全部通过；
- debug APK 构建通过；
- 模拟器 v1 覆盖升级记录；
- 真机无损升级记录；
- schemaVersion 精确为 2；
- learning_runs 与 personalization_versions 均不存在；
- 所有生产学习路径仍不可达。
