# PowerManager MVP-B 阶段 B0-3：正确观测与活动反馈合同实现与验收记录

## 0. 结论

- 日期：2026-08-15
- 实现起点：`e7648d9`（B0-2 阶段提交）
- 阶段结论：**通过自动化与 Pixel_7 模拟器工程门，可以进入 B1-0**
- App：`0.1.3+10011`
- 数据库：保持 schema v2
- 学习能力：只采集和判断资格；没有 learning run、个人模型、候选激活或参数变化
- 真机与最终 APK：按设备策略延期到 MVP-B 总体验收

本记录只保存匿名聚合、合同结论和工程证据。模拟器数据库、JSON 业务正文、UI dump 和安装临时
产物均未加入 Git；冻结时钟生成的数据只用于工程验收，不冒充自然使用证据。

## 1. 实现内容

### 1.1 可比较的 observation contract v1

- `ObservationComparisonService` 使用稳定五档 ordinal 和整数边界比较，返回 lower / aligned /
  higher，不把主观状态换算成伪精确点数；非法 initial estimate 明确失败；
- `currentMoment` 在共享串行事务内重新 prepare，冻结 estimate、initial、base、rule、活动计数、
  coverage、比较档位和模型哨兵；跨 04:00 的旧 Sheet 以 `staleSheet` 回滚；
- `previousLifeDayEnd` 只读取昨日不可变 summary，提交时间与参考生活日分开，同日已有观测后只读；
- UI 先让用户选择实际状态和 coverage，成功保存后才揭示系统估计与方向；失败保留选择，可重试；
- 同一 currentMoment 业务记录更新整组快照，不产生重复业务观测。

### 1.2 统一资格与模型口径

- `LearningEligibilityService` 统一输出八种稳定排序 reason code，校验合同形状、estimate ordinal、
  coverage、晨间确认、结算状态、模型口径和数据完整性；
- `model-regime-sha256-v1` 对六字段 canonical JSON 做 SHA-256；currentMoment 与
  previousLifeDayEnd 不会混组；
- B0 / B1 使用固定 MVP-A personalization、fingerprint 和 epoch 哨兵；
- Data Health 直接聚合同一资格服务，分开显示两个 reference type、当前口径 eligible 数、日期
  跨度、未结算进度和排除原因，不展示私人正文、记录 ID 或证据哈希。

### 1.3 活动绑定反馈与事务一致性

- 当前未结算生活日的 active 活动可主动进入四档反馈 Sheet；反馈保存完整活动、规则、影响方向和
  `activityUpdatedAt` 快照，不弹窗、不修改估计或参数；
- 重复评价更新同一 active feedback；打开后活动变化以 `staleActivity` 拒绝；
- 活动实质编辑、删除、完成时间变化或晨间重放导致 applied delta 变化时，在同一事务将反馈置为
  invalidated；完全相同的编辑保持 updatedAt 和反馈不变，恢复活动不复活旧反馈；
- Wellbeing、Activity 与 ActivityFeedback 共用 `BusinessWriteCoordinator`，失败不会毒化后续写入；
- 所有新记录 ID 使用时间戳、进程内序号和安全随机熵，不依赖墙钟唯一。这个加固来自模拟器冻结
  时钟验收捕获的主键冲突，修复后同一固定时刻连续保存已通过。

### 1.4 UI、备份与工程时钟

- 首页活动卡提供“评价影响 / 已评价”，小屏与 200% 字号下保持可操作；
- Data Health 增加新合同、资格、排除原因及反馈 active / invalidated 聚合，并明确最低数量只表示
  可以进入影子审计；
- schema v2 备份严格重算 observation ordinal 与 canonical model regime key，篡改在写库前拒绝；
- 非 release 构建可用显式 `POWER_MANAGER_FIXED_NOW` 完成跨生活日工程验证；非法值立即失败，
  release 构建始终忽略该覆盖，最终普通模拟器构建不携带覆盖值。

## 2. 自动化验收

在 `app/` 执行：

- `dart format --output=none --set-exit-if-changed lib test`：通过；
- `dart run build_runner build --delete-conflicting-outputs`：通过，无非预期生成差异；
- `flutter analyze`：通过，0 个问题；
- `flutter test --coverage -r compact`：282 项通过，0 失败；
- 行覆盖：6539 / 9409（69.50%）；
- `git diff --check`：通过，仅有 Git 的 CRLF 归一化提示，无 whitespace error。

关键覆盖包括：全部比较边界、八种资格原因及稳定顺序、canonical regime key、同日 insert / update、
跨 04:00 拒绝、昨日不可变 summary、未结算到结算资格转换、共享写队列顺序和失败恢复、反馈保存 /
替换 / stale / 编辑 / 删除 / 重放失效、no-op 保留、事务失败回滚、备份 ordinal / key 防篡改、先选后
揭示、失败重试、四档反馈、取消、屏幕阅读器语义、小屏和 200% 字号。

## 3. Pixel_7 模拟器验收

设备：`emulator-5554`，Android 14 / API 34。设备列表只发现该模拟器，所有 ADB 和 Flutter 命令
均显式指定它；物理手机未连接、未操作。

### 3.1 非破坏性覆盖与第一参考日

- 通过 profile 构建覆盖安装 `0.1.3+10011`，未卸载、未清数据；`firstInstallTime` 保持
  2026-07-26 07:16:04；
- 以非 release 工程时钟 `2026-08-13T12:00:00Z` 验证：晨间确认、创建活动、主动选择
  strongerImpact、显示“已评价”，再把活动 30 分钟改为 45 分钟；首页立即恢复“评价影响”；
- 保存 2026-08-12 previousLifeDayEnd：summary estimate 84、actual okay、coverage uncertain；
- 保存 2026-08-13 currentMoment：estimate 90、initial 106、estimated ordinal 4、actual low、活动数 1、
  coverage confirmed；保存前无系统答案，保存后才显示 lower；
- 冻结时钟下第一次 currentMoment 保存暴露旧时间戳 ID 与昨日观测冲突。统一 ID 策略后重新安装并
  原路径重试成功，既有数据未丢失。

### 3.2 跨日结算、资格与重启

- 切换到 `2026-08-14T05:00:00Z` 后，2026-08-13 自动结算为不可变昨日总结；
- Data Health：schema v2 完整重放 0 异常；currentMoment 1、previousLifeDayEnd 1、当前模型口径
  eligible 1、日期跨度 2026-08-13 至 2026-08-13、尚未结算 0；
- 排除原因准确显示旧合同 1、活动覆盖不确定 1、缺少晨间确认 1；uncertain 和 legacy 没有获得
  资格；
- 强制停止并重新启动后，昨日总结、资格聚合和备份 readiness 均保持不变；再次完整重放仍为
  0 异常；
- base 仍为 100，active rule 仍为 `energy-rules-v2-mvp-a`，没有 pending、学习运行或模型激活。

### 3.3 普通时间构建与最终模拟器备份

- 最后用不含固定时间覆盖的普通 profile 构建再次覆盖安装；版本仍为 `0.1.3+10011`，历史数据和
  首次安装时间保持；
- 重新生成并验证 latest：UI 37.4 KiB、schema v2、App `0.1.3+10011`，readiness 与当前业务摘要
  一致；
- 严格回读聚合：设置 1、规则 1、晨间 9、活动 30、观测 4、新合同 2、反馈 1、总结 11、回执 5；
- 两条新合同按 reference type 各 1，coverage confirmed / uncertain 各 1，两个 model regime key
  均匹配 `model-regime-sha256-v1:<64 lowercase hex>`；
- 活动反馈为 invalidated 1，原因为 activityEdited，没有错误 active；
- 全流程日志无 Flutter fatal、SQLite / Drift、FileSystemException、未处理异常、Crash 或 ANR。

## 4. 产物与设备边界

- 本阶段未操作物理手机，也未构建、交付或安装最终 APK；
- `flutter run` 只为 Pixel_7 模拟器生成临时 profile 安装产物，验收后从工作区精确删除；
- 模拟器固定时间数据是合同和生命周期 fixture，不能用于发布生产阈值；
- 连续自然使用的负担、理解和学习效果仍为 `inconclusive`，统一在 MVP-B 总验收安装手机后复验；
- B1-0 只允许写不可变影子 learning run，仍不得改动 base、pending、rule 或活动影响参数。

## 5. 放行决定

B0-3 的停止条件均未命中。正确参考时刻、先选后揭示、覆盖分流、结算资格、模型口径、活动反馈
失效、备份回读和重启均通过；冻结时钟发现的 ID 冲突已修复并回归验证。允许提交本阶段并进入
B1-0。最终 APK、物理手机迁移和自然产品结论继续延期，生产学习与自动应用门保持关闭。
