# Drift schema snapshots

这些 JSON 是数据库迁移测试的不可变输入。它们来自对应版本实际启动后生成的 SQLite 数据库，
因此同时包含 Drift 声明的表和索引，以及 `onCreate` 创建的 partial index 与保护触发器。

- 已发布版本的 `drift_schema_vN.json` 禁止覆盖或回写；
- 当前不可变快照为 v1、v2、v3；v3 来自实际启动并完成 `onCreate` 的 SQLite 文件；
- 每次提升 `AppDatabase.schemaVersion`，先从实际创建的新版本数据库导出新的快照；
- 导出后运行：

  `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/`

- 迁移测试必须使用 `SchemaVerifier` 从旧快照建库，并开启 `validateDropped`；
- 仅对 Dart 数据库源文件执行 `schema dump` 会漏掉运行时创建的 extras，不能代替实际数据库快照。
