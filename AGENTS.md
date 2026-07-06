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

如果任务涉及接口、manifest、release 或 CI，还必须读取：

1. `.ai-workspace/CROSS_PROJECT_CONTRACTS.md`
2. `.ai-workspace/RELEASE_GOVERNANCE.md`
3. `hybird-meumall/AGENTS.md`

如果任务涉及 H5 需求开发、Java 接口联调、H5 发布或线上验证，还必须读取：

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
- 当前仓库只维护 `hybird-meumall` H5 C 端；后续需求、修改和验证默认只考虑 H5。
- 旧 `server-meumall`、`admin-meumall`、`app-meumall` 已退役/外部化，并已从当前工作区物理移除；不要为了 H5 需求恢复这些目录。
- Java 后端、Java 管理台和 iOS App 都是外部系统；本仓库只记录 H5 侧消费契约、环境配置和联调结论。
- H5 调用 Java 接口必须有契约或明确记录联调口径。
- 页面进度、页面清单、端归属、H5 路由或页面状态发生变更时，必须先更新仓库事实源，再同步到公司飞书知识库对应页面。
- 涉及外部 App/WebView/Bridge 的内容，仅记录 H5 侧调用假设和 fallback；不得把 iOS 实现作为本仓库交付项。
- 飞书知识库同步默认遵循 `.ai-workspace/H5_FEISHU_KNOWLEDGE_SYNC_WORKFLOW.md`，公司知识库默认目标为 `新款app开发资料 / 前端知识库`；同步完成后必须记录飞书链接、revision 或验证结果。
- 没有 `ready` 状态，不开始正式实现。
- 没有验证记录，不声称完成。

## 当前项目边界

- `hybird-meumall`：唯一当前维护项目，承载 H5 商城 C 端页面、BFF、H5 发布和 H5 侧 AI 状态。
- 根级 `.ai-workspace`、`scripts/deploy`、`deploy/nginx`：只服务 H5 工作流、H5 发布和 H5 文档同步。
- Java：外部系统，提供 H5 版本管理、active manifest、release 注册/切 active、业务 API 和管理后台能力。
- `server-meumall` / `admin-meumall` / `app-meumall` / `meumall-ci`：已从当前工作区移除，不再作为后续需求实现范围。

## 语言

中文是本工作区的主要协作语言。长期文档、任务说明、验收标准和汇报默认使用中文。必要的命令、路径、状态枚举、接口字段和代码标识可以保留英文。
