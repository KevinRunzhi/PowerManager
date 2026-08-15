# PowerManager

精力值管理产品文档仓库。

`Docs/` 是正式文档的唯一来源。根目录和 `docs_review/` 中被 Git 忽略的同名文件或讨论稿仅用于历史追溯，不作为开发依据。

## 当前代码基线：v2 / MVP-A

- `精力值管理产品_PRD_v2_MVP-A.md`
- `精力值规则配置_v2_MVP-A.md`
- `精力值算法规则_v2_MVP-A.md`
- `精力值管理产品_MVP-A_Backlog_v2.md`
- `精力值管理产品_技术方案_v2_MVP-A.md`
- `MVP-A_规则与实现追踪矩阵_v2.md`
- `精力值管理产品_二次方案修订计划.md`
- `PowerManager_MVP-A_分阶段开发计划_Spec_v1.md`
- `精力值管理产品_外观设计规格_v1_MVP-A.md`
- `PowerManager_MVP-A_阶段0_环境与仓库基线验收.md`
- `PowerManager_MVP-A_阶段1_Flutter工程骨架验收.md`
- `PowerManager_MVP-A_阶段2_领域规则与纯算法验收.md`
- `PowerManager_MVP-A_阶段3_Drift数据层验收.md`

上述 v2 文档是现有 MVP-A Flutter 实现与维护的唯一规则来源。

当前用户功能仍以 MVP-A Stage 19 为基线。MVP-B 工程已完成 B0-2：数据库升级到 schema v2，
具备新观测合同与活动反馈的存储 / 备份基础；B0-3 用户流程和全部自动学习尚未实现。MVP-A 文档
继续作为现有 App 行为和历史数据的正式依据。

## 当前实施基线：v3 / MVP-B

- `PowerManager_MVP-B_文档基线与决策索引_v1.md`
- `精力值管理产品_PRD_v3_MVP-B.md`
- `精力值规则配置_v3_MVP-B.md`
- `精力值算法规则_v3_MVP-B.md`
- `精力值管理产品_技术方案_v3_MVP-B.md`
- `精力值管理产品_MVP-B_Backlog_v1.md`
- `PowerManager_MVP-B_分阶段开发计划_Spec_v1.md`
- `MVP-B_规则与实现追踪矩阵_v1.md`
- `PowerManager_MVP-B_阶段B0-0_文档与开工门禁_Spec_v1.md`
- `PowerManager_MVP-B_阶段B0-1_迁移准备版_Spec_v1.md`
- `PowerManager_MVP-B_阶段B0-2_SchemaV2与备份兼容_Spec_v1.md`
- `PowerManager_MVP-B_阶段B0-3_正确观测与活动反馈合同_Spec_v1.md`
- `PowerManager_MVP-B_阶段B1-0_自动影子学习器_Spec_v1.md`
- `PowerManager_MVP-B_阶段B1-1_真实影子观察与生产决策_Spec_v1.md`
- `PowerManager_MVP-B_阶段B2-0_SchemaV4与模型生命周期_Spec_v1.md`
- `PowerManager_MVP-B_阶段B2-1_基准线自动学习与安全激活_Spec_v1.md`
- `PowerManager_MVP-B_阶段B2-2_基准线调整后监测_Spec_v1.md`
- `PowerManager_MVP-B_阶段B3-0_活动影响生产参数门_Spec_v1.md`
- `PowerManager_MVP-B_阶段B3-1_SchemaV5与活动影响学习器_Spec_v1.md`
- `PowerManager_MVP-B_阶段B3-2_活动影响安全激活与监测_Spec_v1.md`
- `PowerManager_MVP-B_总体验收_Spec_v1.md`

这些文档是 MVP-B 的实施基线，定义自动学习目标、P0 数据合同、迁移安全、逐阶段过程与
验收门禁。它们授权按 B0 → B1 → B2 → B3 顺序开发，但不授权在当前 App 中运行生产自动
学习。MVP-B 的目标是从合格“估计—实际”配对和无选择偏差的活动抽样反馈中持续学习基准线
与活动影响，并通过不可变模型版本安全生效。当前活动规则仍为
`energy-rules-v2-mvp-a`，所有学习与自动应用门保持关闭；必须先实施 B0 数据基础，再进入
B1 自动影子学习，用真实数据决定 B2 / B3 的生产参数。

## 开发环境

- `Flutter环境布置_Spec_v1.md`
- Flutter SDK：`E:\develop\PowerManagerFlutter\flutter`
- Android SDK：`E:\develop\SDK`
- 当前验证模拟器：`Pixel_7`（Android 14 / API 34）

## 设计参考原型

- `prototypes/PowerManager_动效小样.html`
- 定位：Flutter 外观与动效实现的参考模板，不替代 PRD、算法规则、规则配置或技术方案。
- 使用边界详见 `prototypes/README.md` 和《精力值管理产品 外观设计规格 v1（MVP-A）》第 12 节。

## 历史文档

- `精力值管理产品_PRD_定稿.md`
- `精力值管理产品_MVP_Backlog_功能拆解.md`
- `精力值算法规则_初稿.md`
- `精力值规则配置_v1.md`
- `精力值管理产品_技术方案_初稿.md`
- `精力值管理产品_冲突审计与修订计划.md`

历史文档用于追溯第一轮方案，不再作为 MVP-A 实现依据。
