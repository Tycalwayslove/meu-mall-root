# MeuMall H5 AI 交付体系

本目录定义 MeuMall H5 C 端工作区的统一 AI 开发机制。当前仓库只维护 `hybird-meumall`；旧 `server-meumall`、`admin-meumall`、`app-meumall` 和 `meumall-ci` 已从当前工作区移除，后续 Codex 会话不得恢复或依赖它们。

## 读取顺序

任何跨项目或正式业务任务开始前，先按顺序读取：

1. `.ai-workspace/AI_OPERATING_MODEL.md`
2. `.ai-workspace/PROJECT_MAP.md`
3. `.ai-workspace/TASK_SCHEMA.md`
4. `.ai-workspace/STATE_FLOW.md`
5. `.ai-workspace/ACCEPTANCE_STANDARD.md`
6. `.ai-workspace/MEMORY_PROTOCOL.md`
7. `.ai-workspace/H5_DEMAND_INTEGRATION_WORKFLOW.md`，当任务涉及 H5 需求、跨端对接或页面开发时读取
8. 当前任务文件
9. 相关对接说明
10. `hybird-meumall/AGENTS.md`
11. `hybird-meumall/.ai/PROJECT_STATE.md`

## 目录职责

- `AI_OPERATING_MODEL.md`：AI 参与开发的总规则。
- `PROJECT_MAP.md`：多项目职责和依赖地图。
- `TASK_SCHEMA.md`：统一工作项结构。
- `STATE_FLOW.md`：统一状态流转。
- `ACCEPTANCE_STANDARD.md`：统一验收标准。
- `MEMORY_PROTOCOL.md`：跨会话记忆协议。
- `CROSS_PROJECT_CONTRACTS.md`：H5 与外部 Java/API/运行环境契约治理。
- `RELEASE_GOVERNANCE.md`：发布、灰度和回滚治理。
- `H5_DEMAND_INTEGRATION_WORKFLOW.md`：H5 需求开发和外部 Java/API 对接工作流。
- `H5_PAGE_DEVELOPMENT_WORKFLOW.md`：H5 页面开发前的路由、渲染、BFF mock、资产和验收工作流。
- `H5_FEISHU_KNOWLEDGE_SYNC_WORKFLOW.md`：将仓库事实源同步到飞书知识库的协作工作流。
- `H5_FEISHU_BASE_SCHEDULE_WORKFLOW.md`：将 H5 页面、后端接口、原生对接和测试验收同步到飞书多维表格的排期协作工作流。
- `H5_FEISHU_RELEASE_NOTIFICATION_WORKFLOW.md`：H5 发版后的飞书审核、正式群通报和排期同步工作流。
- `H5_RELEASE_RUNBOOK.md`：H5 多版本容器发版、Jenkins 发版、active 切换和回滚操作手册。
- `GLOSSARY.md`：统一术语。
- `templates/TASK.md`：工作项模板。
- `templates/INTEGRATION_BRIEF.md`：跨团队对接说明模板。
- `templates/API_CONTRACT.md`：H5 与 Java/API 契约模板。
- `templates/NATIVE_BRIDGE_CONTRACT.md`：H5 与外部运行环境 Bridge 契约模板。
- `templates/ADMIN_CONFIG_CONTRACT.md`：H5 与 Java 配置平台契约模板。
- `templates/COUNTERPART_HANDOFF.md`：给 Java/API、外部运行环境、Java 配置平台、测试/发布的对外输出包模板。
- `templates/FEISHU_KNOWLEDGE_PAGE.md`：飞书知识库页面模板。
- `templates/FEISHU_BASE_H5_DEMAND_SCHEDULE_SCHEMA.md`：H5 需求排期飞书 Base 表结构模板。
- `skills/`：本项目推荐使用的本地 Codex skill 说明。
- `contracts/`：跨项目契约文档入口。
- `integration-briefs/`：H5 需求对接说明入口。
- `domain/`：业务领域模型文档入口。
- `product/`：页面盘点、产品范围和端归属讨论入口。
- `tasks/`：根级或跨项目工作项入口。
- `plans/`：业务排期、飞书 Base 种子数据和阶段计划入口。

## 基本原则

- 没有工作项，不进入正式业务开发。
- 没有 `ready` 状态，不开始实现。
- 没有验收记录，不声称完成。
- 没有发布影响说明，不进入上线或灰度。
- 当前工作区只实现 `hybird-meumall` H5 C 端。
- H5 调用 Java 后端、Java H5 版本管理或外部运行环境能力时，先写契约或联调口径，再进入联调。
- H5 只负责消费、渲染和兜底，不把 Java 后端、Java 管理台或 iOS App 职责写入 H5 实现。
- 旧 `server-meumall`、`admin-meumall`、`app-meumall` 和 `meumall-ci` 已物理移除；后续需求不得恢复这些目录或把它们作为实现范围。

## 已纳入的业务治理规则

- `contracts/hybrid-h5-runtime-contract.md`：Hybrid H5 运行时、WebView 复用、构建产物边界和发布顺序。
- `contracts/h5-cache-contract.md`：H5 静态资源、HTML、Service Worker、API 和登录态缓存边界。
- `contracts/native-bridge-lifecycle-contract.md`：Native 与 H5 的生命周期事件、能力检测和安全边界。
- `contracts/api/`：H5 与后端业务 API 契约。
- `contracts/native-bridge/`：历史 H5 与 Native Bridge 具体能力契约；新需求默认不再把 iOS 实现纳入本仓库。
- `contracts/admin-config/`：历史管理后台配置契约；当前管理后台能力已外部化到 Java。
- `domain/ecommerce-data-consistency.md`：电商数据的一致性等级、缓存位置和交易限制。
- `tasks/hybrid-h5-cache-runtime-backlog.md`：后续可拆分执行的缓存与运行时任务候选池。
- `product/product-decisions.md`：已确认的喵呜产品决策记录。
- `product/page-inventory.md`：基于 Figma 的页面盘点和端归属草案。

## 根级命令

根目录 `package.json` 只作为 H5 工作区命令入口，不把旧项目合并为同一个 workspace。

- `pnpm dev`：启动 `hybird-meumall` 本地开发服务。
- `pnpm run dev:h5`：启动 `hybird-meumall`，默认端口 `3109`，basePath 为 `/hybird`。
- `pnpm run check`：运行 H5 工作流检查。
- `pnpm run deploy`：执行 H5 版本部署脚本。
- `pnpm run jenkins:sync-h5`：创建或更新唯一 H5 发版 Jenkins Pipeline job。
