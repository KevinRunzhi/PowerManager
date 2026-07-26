# PowerManager MVP-A 阶段 9：设置、导出与首次说明验收

## 0. 文档状态

- 阶段：9 / 设置、导出与首次说明
- 执行日期：2026-07-26
- 依据：《PowerManager MVP-A 分阶段开发计划 Spec v1》第 13 节
- 结果：通过

---

# 1. 个人基准线设置

新增独立设置页，展示：

- 当前个人基准线；
- 已排期的待生效值和生效生活日；
- 当前 `ruleVersion`；
- JSON 导出入口；
- 首次说明重看入口。

基准线输入只接受 60～140 的整数，应用层和界面层均校验。

保存流程：

```text
业务写入前 prepare
  → 取得当前生活日
  → 保持 baseEstimatedEnergy 不变
  → 写入 pendingBaseEstimatedEnergy
  → 生效日 = currentLifeDay.next
```

因此修改当天不重放、不改变当前估计，也不修改已结算历史。下一生活日首次
prepare 时由既有幂等逻辑应用一次并清空 pending 配对字段。

MVP-A 只展示当前规则版本，不提供规则编辑、迁移或自动能力建议入口。

---

# 2. JSON 数据导出

新增 `JsonExportService`，从七类核心仓库读取：

1. `app_settings`
2. `rule_config_versions`
3. `morning_check_ins`
4. `activity_records`
5. `energy_observations`
6. `daily_summaries`
7. `prompt_receipts`

导出顶层元数据：

- `schemaVersion`
- `exportedAt`（UTC ISO 8601）
- `appVersion`

活动读取使用 `listAllForExport()`，因此逻辑删除记录及 `deletedAt` 仍在备份中。
导出不包含 SQLite `rowid`、DAO 临时字段、设备标识、路径或本地秘密。

JSON 编码放入 Dart isolate，避免较大数据集的格式化工作阻塞 UI。文件名使用稳定
UTC 格式：

```text
powermanager-YYYYMMDD-HHMMSSZ.json
```

---

# 3. Android 保存 / 分享方案

采用：

- `path_provider 2.1.6` 获取应用临时目录；
- `share_plus 13.3.0` 调用 Android 系统分享面板；
- `package_info_plus 10.2.1` 读取真实应用版本。

流程：

```text
读取并编码 JSON
  → 写入应用临时目录
  → 以 application/json 分享
  → 用户选择文件管理器、云盘或其他目标保存
```

该方案符合 Android scoped storage，不要求读写整个外部存储，也不新增无关设备
信息。临时文件只作为分享源，长期保存位置由用户在系统面板中决定。

---

# 4. 精简首次说明

首次说明只解释三个 MVP-A 核心边界：

1. 系统估计和用户实际状态分开保存；
2. 100 是默认尺度，不是上限或健康分数；
3. 当前生活日可以补记、编辑、删除，结算历史只读。

当 `onboardingCompleted == false` 时，首页自动展示一次不可误关的说明。用户点击
“我知道了”后，通过幂等设置服务写入完成状态。后续启动不再自动弹出。

设置页始终保留“重新查看首次说明”，重看不会重置完成状态。

---

# 5. 自动化验收

新增覆盖：

1. 60 和 140 均可排期；
2. 59 和 141 在持久化前拒绝；
3. 保存后当前基准线仍为 100；
4. 待生效日严格为下一生活日；
5. onboarding 完成写入幂等；
6. JSON 可重新解析；
7. JSON 包含 schema、导出时间和应用版本；
8. JSON 包含规则版本；
9. JSON 包含逻辑删除活动；
10. JSON 不含数据库内部字段或设备标识；
11. 设置页输入错误可见；
12. 首次说明自动出现一次且设置页可重开。

全量结果：

```text
dart format --output=none --set-exit-if-changed lib test
通过

flutter analyze
通过，0 issue

flutter test
通过，105 tests

flutter build apk --debug --split-per-abi
通过
```

---

# 6. Android 模拟器验收

环境：Pixel_7 / Android 14 / API 34 / x86_64 Debug APK。

实测：

- APK 更新安装成功；
- 首次说明自动出现，三段说明与确认按钮完整可见；
- 确认后回到首页，再次刷新未自动出现；
- 首页显示 `MVP-A · Stage 9 · 设置与导出`；
- 设置页显示当前基准线 100；
- 当前规则版本显示 `energy-rules-v2-mvp-a`；
- 导出、首次说明重看入口均可见；
- 点击导出后系统分享界面收到带 `powermanager-...json` 文件名的文件；
- 无 `FATAL EXCEPTION`、`E/flutter` 或准备服务错误。

---

# 7. 验收结论

| 验收项 | 结果 |
|---|---|
| 60～140 双层校验 | 通过 |
| 当天不生效 | 通过 |
| 下一生活日生效 | 通过 |
| pending 只应用一次 | 通过（既有回归测试） |
| 当前 ruleVersion 可见 | 通过 |
| 无规则编辑入口 | 通过 |
| 七类数据可备份 | 通过 |
| 逻辑删除记录保留 | 通过 |
| 元数据和版本完整 | 通过 |
| Android scoped storage 兼容 | 通过 |
| 首次说明只自动一次 | 通过 |
| 设置页可重新查看 | 通过 |

阶段 9 验收通过。下一阶段进入能量球连续滑动记录手势原型与真机任务验证。
