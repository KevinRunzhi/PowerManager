# PowerManager MVP-B 阶段 B0-2：Schema v2 与备份兼容实现与验收记录

## 0. 结论

- 日期：2026-08-15
- 实现起点：`c440bba`（B0-1 阶段提交）
- 阶段结论：**通过自动化与 Pixel_7 模拟器工程门，可以进入 B0-3**
- App：`0.1.2+10010`
- 数据库：schema v1 无损升级到 schema v2
- 备份：继续接受 schema v1，当前严格导出 schema v2
- 学习能力：未创建学习运行或个人模型表，未运行、未激活任何学习器
- 真机与最终 APK：按设备策略延期到 MVP-B 总体验收

本记录只保存匿名聚合、合同结论和工程证据。模拟器数据库、JSON 业务正文、UI dump 和安装临时
产物均未加入 Git。

## 1. 实现内容

### 1.1 可回滚 schema v1 → v2 迁移

- 使用实际启动过的 schema v1 SQLite 导出不可变 Drift DDL fixture，包含运行时 partial index 和
  保护触发器；schema v2 也保存对应快照，并生成版本化迁移测试辅助代码；
- `onUpgrade` 只接受精确的 `1 → 2`：关闭外键执行窗口、在显式事务中移除依赖对象、重命名旧
  observation 表、按最终定义建表、逐列复制七个旧字段、将十三个新字段写为 null、双向核对数量
  与 ID，再创建 feedback、索引和保护触发器；
- 提交前执行 `foreign_key_check`、`integrity_check` 和 schema object 自检，并禁止提前出现
  `learning_runs`、`personalization_versions`；
- 清理依赖对象后、复制期间和重建保护触发器前均可注入失败；每种失败都回滚为完整 schema v1，
  保留旧列、数据、索引、触发器和 `user_version = 1`，修复后可重试成功。

### 1.2 观测合同和活动反馈存储

- `energy_observations` 增加 observation contract v1 的完整 nullable 快照；组合 CHECK 区分 legacy、
  完整新合同和 MVP-A relative correction，迁移不反推任何历史值；
- legacy 行只允许新字段为 null 或 `coverageState = legacyUnknown`，不能伪装成可学习证据；
- 新增 `activity_feedback`、领域实体、枚举、converter、DAO 和 repository；固定四档反馈方向、三种
  影响符号、active / invalidated 状态、失效原因、规则与活动外键、符号约束和单活动唯一 active；
- 规则不可变触发器现在同时保护观测与反馈引用的规则快照；活动编辑、删除和恢复时的同步失效属于
  B0-3 业务事务，本阶段没有反馈生产写入口。

### 1.3 备份 v2 与数据体检

- 当前导出 schema v2：保留原七类数据，observation 明确输出全部 nullable 新键，并增加完整
  `activityFeedback` 数组；顺序和业务摘要保持确定；
- 解码器只接受 v1 / v2。v1 映射为 legacy 且反馈为空；v2 在写数据库前严格检查键完整性、枚举、
  组合合同、规则引用、活动引用、唯一 active、状态原因和活动快照一致性；
- 恢复按外键顺序事务替换，反馈失败注入会回滚原数据库和保护触发器，恢复后重新执行外键、完整性
  与逐表数量检查；
- Data Health 增加 schemaVersion、legacy / 新合同观测、反馈总数及 active / invalidated 聚合；
  设置页备份预览显示备份 schema 和反馈替换计数。

### 1.4 工具链决定

当前 Flutter SDK 固定的 analyzer / test_api 组合与较新的 `drift_dev` 版本无法同时求解，原有运行时
`drift 2.34.2` 与生成器 `drift_dev 2.34.0` 又会使 schema 工具编译失败。因此运行时和生成器均
精确锁定为兼容的 `2.34.0`。完整生成、静态分析、245 项测试、实际迁移 fixture 和模拟器升级均
通过，避免在高风险迁移阶段引入依赖覆盖或升级整套 Flutter 工具链。

## 2. 自动化验收

在 `app/` 执行：

- `dart format --output=none --set-exit-if-changed lib test`：通过；
- `dart run build_runner build`：通过，生成文件与 schema v2 一致；
- Drift schema dump / generate：从实际 v1、v2 SQLite 快照成功生成版本化 fixture；
- `flutter analyze`：通过，0 个问题；
- `flutter test`：245 项通过，0 失败；
- `flutter test --coverage -r compact`：245 项通过，行覆盖 6013 / 8822（68.16%）；
- `git diff --check`：通过，仅有 Git 的 CRLF 归一化提示，无 whitespace error。

关键新增覆盖包括：空库与全量 v1 迁移、原七表逐字段不变、三处失败回滚、迁移仅运行一次、最终
schema 精确验证、observation 组合 CHECK、feedback 外键 / 状态 / 符号 / 唯一约束、v1 导入后
合法 v2 再导出、v2 完整往返、invalidated feedback、缺键 / 坏引用 / 重复 active / 未知枚举拒绝、
feedback 恢复失败整库回滚、Data Health 聚合和 UI 回归。

## 3. Pixel_7 模拟器升级验收

设备：`emulator-5554`，Android 14 / API 34。`flutter devices` 和 `adb devices -l` 均只发现该
模拟器，所有设备命令均显式指定它。

### 3.1 升级前门禁

- 安装版本：`0.1.1+10009`，schema v1；首次安装时间仍为 2026-07-26；
- Data Health：完整重放通过、0 项异常；B0-1 latest 为 32977 字节，schema v1，备份摘要与当前
  摘要一致，readiness 为 passed；
- 设置 1、规则 1、晨间 8、活动 29（active 29 / 删除 0）、观测 2（每日 1 / 随时校正 1）、总结
  10（标准有效 5 / 弱有效 2）、提示回执 5；
- base 100、无 pending base、active rule 为 `energy-rules-v2-mvp-a`、无 pending rule；最近总结
  生活日为 2026-08-12。

### 3.2 不清数据覆盖升级

- 通过 `flutter run --profile -d emulator-5554` 覆盖运行 `0.1.2+10010`，未卸载、未清数据；
- `firstInstallTime` 保持 2026-07-26 07:16:04，`lastUpdateTime` 更新为 2026-08-15 06:43:34；
- 首次启动直接进入既有首页，当前估计 100、固定规则和最近总结保持不变；
- Data Health 显示 schema v2 完整重放通过、0 项异常；旧聚合逐项一致；
- 2 条旧观测全部仍为 Legacy，新合同观测 0，活动反馈 0（active 0 / invalidated 0），迁移没有
  补造观测、反馈或学习证据；
- schema v1 readiness 被正确判为旧证明不可用，没有错误沿用旧版本证明。

### 3.3 schema v2 备份、回读与重启

- 一键保存并验证后，latest 为 34047 字节（UI 33.2 KiB）、schema v2、App `0.1.2+10010`；
- 严格回读得到规则 1、晨间 8、活动 29、观测 2、反馈 0、总结 10、回执 5；
- 每条 legacy observation 均显式包含全部 v2 nullable 键且值为空；
- readiness 的 backup schema 为 2、完整性为 passed，备份摘要与当前摘要完全一致；
- 强制停止并重新启动后，首页、schema v2、全部聚合和“已准备”状态保持；再次 Data Health 仍为
  完整重放 0 异常；
- 首次迁移、设置、备份、Data Health、强制停止和重启日志均无 Flutter fatal、SQLite / Drift、
  FileSystemException、Crash 或 ANR。

## 4. 产物与设备边界

- 本阶段未操作物理手机，也未构建或交付最终 APK；
- `flutter run` 为模拟器安装临时生成的 `app-profile.apk` 与 `.sha1` 已在验证后从工作区精确删除；
- 既有 schema v1 外部备份继续作为最终真机升级的回退源，真机 v1 → v5 链、恢复和自然使用统一
  登记在 MVP-B 总体验收；
- B0-2 只建立证据存储和迁移安全，不采集新合同数据、不运行学习、不改变 base / rule / pending；
- baseline 与 activityImpact 的真实产品证据仍为 `inconclusive`，生产学习和自动应用门保持关闭。

## 5. 放行决定

B0-2 的停止条件均未命中。实际 v1 fixture、失败回滚、备份兼容、模拟器覆盖迁移、v2 回读和重启
均通过，允许提交本阶段并进入 B0-3。最终 APK 与真机门继续延期，不能用模拟器工程证据替代真实
自然数据或生产自动学习效果。
