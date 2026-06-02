# AGENTS.md

本文件定义 AI Agent 在 MeuMall 多项目工作区根目录的工作入口。

## 必读规则

正式业务、跨项目协作、接口契约、发布、长期维护或上下文恢复任务开始前，必须先读取：

1. `.ai-workspace/README.md`
2. `.ai-workspace/AI_OPERATING_MODEL.md`
3. `.ai-workspace/PROJECT_MAP.md`
4. `.ai-workspace/TASK_SCHEMA.md`
5. `.ai-workspace/STATE_FLOW.md`
6. `.ai-workspace/ACCEPTANCE_STANDARD.md`
7. `.ai-workspace/MEMORY_PROTOCOL.md`

如果任务涉及接口、Native Bridge、manifest、release 或 CI，还必须读取：

1. `.ai-workspace/CROSS_PROJECT_CONTRACTS.md`
2. `.ai-workspace/RELEASE_GOVERNANCE.md`
3. 相关子项目的 `AGENTS.md`

如果任务涉及 H5 需求开发、跨端对接、后端接口申请、原生 App 能力、管理后台配置或联调，还必须读取：

1. `.ai-workspace/H5_DEMAND_INTEGRATION_WORKFLOW.md`
2. `.ai-workspace/templates/INTEGRATION_BRIEF.md`
3. 相关契约模板或契约文档

如果任务是把自然语言需求整理成 AI 可执行需求、工作项、对接说明或契约清单，优先使用本地 Codex skill：

1. `meumall-requirement-shaper`
2. 说明文档：`.ai-workspace/skills/meumall-requirement-shaper.md`

如果任务涉及产品页面、业务规则、端归属、登录、交易、推广、会员/达人或智能体，还必须读取：

1. `.ai-workspace/product/product-decisions.md`
2. `.ai-workspace/product/page-inventory.md`
3. `.ai-workspace/domain/meumall-business-model.md`

## 工作区原则

- 根目录负责统一 AI 工作机制，不承载具体业务实现。
- 子项目负责各自代码、项目状态、测试报告和项目内决策。
- 跨项目任务必须有工作项。
- 跨项目接口必须有契约。
- 跨端 H5 需求必须有对接说明。
- 没有 `ready` 状态，不开始正式实现。
- 没有验证记录，不声称完成。

## 子项目

- `hybird-meumall`：H5 商城前台。
- `server-meumall`：manifest、config 和 release 服务。
- `app-meumall`：SwiftUI WebView 原生壳。
- `admin-meumall`：配置和发版管理台。
- `meumall-ci`：本地 CI、部署和 release 注册脚手架。

## 语言

中文是本工作区的主要协作语言。长期文档、任务说明、验收标准和汇报默认使用中文。必要的命令、路径、状态枚举、接口字段和代码标识可以保留英文。
