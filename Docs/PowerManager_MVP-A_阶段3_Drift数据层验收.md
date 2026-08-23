# PowerManager MVP-A 阶段 3：Drift 数据层验收

## 0. 文档状态

- 阶段：3 / Drift 数据层
- 执行日期：2026-07-26
- 依据：《PowerManager MVP-A 分阶段开发计划 Spec v1》第 7 节
- 模型来源：《精力值管理产品 技术方案 v2（MVP-A）》第 2 节
- Schema 版本：1
- 结果：通过

---

# 1. 阶段边界

本阶段完成：

- 七张最小业务表；
- Schema v1 创建与初始化；
- `LifeDay` 和稳定枚举转换；
- SQLite CHECK、UNIQUE、FK、索引和不可变触发器；
- 每张表的 DAO 和 Repository；
- Repository Row → Domain Entity 映射；
- 内存数据库与文件数据库测试；
- JSON 导出 DTO。

本阶段不实现：

- 当前日派生应用编排；
- 结算服务；
- 活动、早间确认或观测的 UI；
- JSON 文件写出或导出 UI。

---

# 2. Schema v1

数据库只包含以下七张业务表：

```text
app_settings
rule_config_versions
morning_check_ins
activity_records
energy_observations
daily_summaries
prompt_receipts
```

自动化测试直接读取 `sqlite_master`，排除 SQLite 内部对象后确认数量恰好为 7，没有额外第八张业务表。

## 2.1 app_settings

- 固定主键 `id = 1`；
- 当前基准限制为 60～140；
- pending 基准与生效生活日必须同时为空或同时存在；
- active / pending ruleVersion 使用外键；
- 默认基准 100；
- 默认规则 `energy-rules-v2-mvp-a`；
- 默认 onboarding 未完成；
- 删除固定 settings 行由触发器拒绝。

## 2.2 rule_config_versions

- `version` 主键且不可为空；
- `valuesJson` 必须是合法 JSON；
- 默认 JSON 包含 24 × 6 活动规则、时长档、早间修正、短期修正、估计档位和有效日规则；
- 一旦被 settings、活动记录或每日摘要引用，任何 UPDATE 均由触发器拒绝；
- 外键阻止删除仍被引用的版本。

## 2.3 morning_check_ins

- `lifeDay` 唯一；
- 四项输入使用稳定枚举；
- `morningAdjustment` 必须和综合状态严格匹配：

```text
bad    -> -6
normal ->  0
good   -> +6
```

跳过不写 MorningCheckIn 行。

## 2.4 activity_records

- UTC 时间戳与 `LifeDay` 分列保存；
- 固定六档时长 CHECK；
- category / subcategory 组合 CHECK；
- ruleVersion 外键；
- status 只允许 `active / deleted`；
- `active` 必须没有 deletedAt；
- `deleted` 必须具有 deletedAt；
- `(lifeDay, completedAt, createdAt, id)` 排序索引；
- 默认业务查询只返回 active；
- 导出查询保留逻辑删除记录。

## 2.5 energy_observations

- dailyAbsolute 和 relativeCorrection 使用同一事件表；
- 部分唯一索引保证每个 lifeDay 最多一条 dailyAbsolute；
- relativeCorrection 可有多条；
- dailyAbsolute 必须保存绝对状态且不保存相对状态；
- relativeCorrection 必须保存相对状态和当时估计；
- 用户原始枚举不转换为伪精确实际数值。

## 2.6 daily_summaries

- `lifeDay` 主键；
- ruleVersion 外键；
- 分类汇总必须是合法 JSON；
- 消耗和恢复不能为负；
- 标准有效日与弱有效日不能同时为真；
- 重复插入使用 `insertOrGet` 幂等返回已有快照；
- UPDATE 和 DELETE 均由数据库触发器拒绝。

## 2.7 prompt_receipts

- `scopeKey` 非空；
- type 和 action 只允许正式枚举；
- `(type, scopeKey, action)` 唯一。

---

# 3. DAO 与 Repository

七张表分别具有 DAO：

```text
AppSettingsDao
RuleConfigVersionsDao
MorningCheckInsDao
ActivityRecordsDao
EnergyObservationsDao
DailySummariesDao
PromptReceiptsDao
```

同时具有七个 Domain Repository 接口和对应 Drift 实现。

Repository 的公开返回值是：

```text
AppSettings
RuleConfigVersion
MorningCheckIn
StoredEstimatedActivity
EnergyObservation
DailySummary
PromptReceipt
```

接口层不导入 Drift，调用方看不到 `*Row`、Companion 或 Drift 表类型。

所有 Repository 写入前把时间转换为 UTC；Drift 从 SQLite 读取时间后也统一恢复为 UTC。`LifeDay` 使用专用字符串转换器，不从 UTC 日期反推。

---

# 4. 初始化和连接边界

## 4.1 幂等种子

每次打开数据库都会在一个事务中执行 insert-or-ignore：

1. 插入 `energy-rules-v2-mvp-a`；
2. 插入唯一默认 settings 行。

首次创建、重复打开和文件关闭后重开均不会生成重复规则或 settings。

## 4.2 平台连接拆分

Schema、DAO 和 Repository 只依赖 Drift；Flutter 文件连接单独放在 `app_database_connection.dart`。

```text
AppDatabase.forExecutor(...)  -> 测试 / 可注入连接
openAppDatabase()             -> drift_flutter 平台文件连接
```

因此内存 SQLite 和文件重开测试可以使用纯 Dart 运行，不需要 Flutter Binding。

---

# 5. JSON 导出 DTO

`PowerManagerExportDto` 已定义以下元数据和七组数据：

```text
schemaVersion
exportedAt
appVersion
appSettings
ruleConfigVersions
morningCheckIns
activityRecords
energyObservations
dailySummaries
promptReceipts
```

DTO 明确保留逻辑删除活动，并且只包含产品数据，不包含设备秘密或无关系统信息。本阶段不读取全部 Repository、不写文件、不提供 UI。

---

# 6. 测试发现与修复

## 6.1 SQL 关键字导致约束解析警告

首次代码生成时，`prompt_receipts.action` 的 CHECK 约束触发 Drift 解析警告，因为 `action` 也是 SQL 语法关键字。

处理：

- 保留 Spec 定义的字段名；
- 在自定义 CHECK 中使用 SQLite 标识符引用 `"action"`；
- 重新生成后无警告。

## 6.2 数据库核心误依赖 Flutter UI 运行时

首轮纯 Dart 数据测试无法加载，原因是 `AppDatabase` 直接导入 `drift_flutter`，间接要求 `dart:ui`。

处理：

- `AppDatabase` 只接收 `QueryExecutor`；
- Flutter 平台连接器移动到独立文件；
- 内存和文件数据库测试改用 Drift Native；
- 数据测试恢复为纯 Dart，生产 Android 连接方式保持不变。

## 6.3 迁移 CLI 补丁版本约束

尝试生成额外 Schema JSON 快照时发现：

- 当前 Flutter SDK 把 `test_api` 固定在 0.7.11；
- `drift_dev >= 2.34.1+1` 需要 analyzer 13；
- analyzer 13 与当前 `test 1.31.0 / flutter_test` 组合不兼容。

本阶段没有使用 dependency override，也没有为非验收项降级 Drift 运行时。继续保留已经验证的：

```text
drift      2.34.2
drift_dev  2.34.0
```

Schema v1 的正式来源是手写表定义；`app_database.g.dart` 由 build_runner 生成，数据库结构由创建、约束和重开测试验证。Flutter SDK 未来升级后可重新评估 Drift 迁移 CLI 快照。

---

# 7. 验证证据

## 7.1 数据层专项测试

执行：

```text
dart test test/data
```

结果：

```text
20 / 20 passed
```

覆盖：

- Schema v1 和恰好七张表；
- `PRAGMA foreign_keys = 1`；
- `PRAGMA integrity_check = ok`；
- 自定义索引和触发器存在；
- 默认规则与 settings 初始化；
- 文件数据库关闭、重开和幂等种子；
- 七张表的数据访问路径；
- 唯一约束、CHECK 和 FK；
- 无效时长、分类组合、状态和观测组合；
- 逻辑删除过滤与导出保留；
- 不可变摘要和引用规则；
- 事务异常完整回滚；
- Repository 映射和 UTC；
- JSON DTO 七组数据。

## 7.2 纯 Dart 回归

```text
dart test test/domain test/data
```

结果：

```text
62 / 62 passed
```

## 7.3 全工程回归

```text
dart format --output=none --set-exit-if-changed .  通过，36 个文件无变化
dart run build_runner build                       通过，无警告
flutter analyze                                   通过，No issues found
flutter test                                      通过，65 / 65
flutter build apk --debug                         通过
```

---

# 8. 验收结论

| 验收项 | 结果 |
|---|---|
| Schema v1 可重复创建 | 通过 |
| 恰好七张业务表 | 通过 |
| 默认 settings 与规则初始化幂等 | 通过 |
| Drift 生成无警告 | 通过 |
| LifeDay 与 UTC 时间戳分离 | 通过 |
| 六档时长和分类组合约束 | 通过 |
| 所有正式唯一约束 | 通过 |
| 逻辑删除默认过滤 | 通过 |
| DailySummary 不可变和重复幂等 | 通过 |
| 已引用规则不可修改 | 通过 |
| 事务失败完整回滚 | 通过 |
| 关闭重开后数据保留 | 通过 |
| Repository 不泄漏 Drift Row | 通过 |
| JSON 导出 DTO 已定义 | 通过 |

阶段 3 已满足退出条件，可以进入阶段 4：当前日派生与生活日准备。
