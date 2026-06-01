# MeuMall AI 交付体系

本目录定义 MeuMall 多项目工作区的统一 AI 开发机制。它的目标是让新的 Codex 会话可以通过仓库内事实恢复上下文，并按同一套工作项、状态、契约、验收和发布规则推进业务开发。

## 读取顺序

任何跨项目或正式业务任务开始前，先按顺序读取：

1. `.ai-workspace/AI_OPERATING_MODEL.md`
2. `.ai-workspace/PROJECT_MAP.md`
3. `.ai-workspace/TASK_SCHEMA.md`
4. `.ai-workspace/STATE_FLOW.md`
5. `.ai-workspace/ACCEPTANCE_STANDARD.md`
6. `.ai-workspace/MEMORY_PROTOCOL.md`
7. 当前任务文件
8. 涉及项目的 `AGENTS.md`
9. 涉及项目的 `.ai/PROJECT_STATE.md`

## 目录职责

- `AI_OPERATING_MODEL.md`：AI 参与开发的总规则。
- `PROJECT_MAP.md`：多项目职责和依赖地图。
- `TASK_SCHEMA.md`：统一工作项结构。
- `STATE_FLOW.md`：统一状态流转。
- `ACCEPTANCE_STANDARD.md`：统一验收标准。
- `MEMORY_PROTOCOL.md`：跨会话记忆协议。
- `CROSS_PROJECT_CONTRACTS.md`：跨项目接口契约治理。
- `RELEASE_GOVERNANCE.md`：发布、灰度和回滚治理。
- `GLOSSARY.md`：统一术语。
- `templates/TASK.md`：工作项模板。
- `contracts/`：跨项目契约文档入口。
- `domain/`：业务领域模型文档入口。

## 基本原则

- 没有工作项，不进入正式业务开发。
- 没有 `ready` 状态，不开始实现。
- 没有验收记录，不声称完成。
- 没有发布影响说明，不进入上线或灰度。
- 跨项目变更先写契约，再写实现。

## 根级命令

根目录 `package.json` 只作为多项目命令入口，不把子项目合并为同一个 workspace。

- `pnpm dev`：同时启动 server、H5 和 admin 本地开发服务。
- `pnpm run dev:server`：启动 `server-meumall`，默认端口 `4100`。
- `pnpm run dev:h5`：启动 `hybird-meumall`，默认端口 `3109`，basePath 为 `/hybird`。
- `pnpm run dev:admin`：启动 `admin-meumall`，默认端口 `5173`。
- `pnpm run check`：运行四个子项目的轻量 AI 工作流检查。
- `pnpm run ci:start`：启动本地 Jenkins 和 Mac agent。
- `pnpm run ci:stop`：停止本地 Jenkins 和 Mac agent。
- `pnpm run deploy`：执行 H5 本地部署脚本。
