# 工作项目录

本目录存放根级或跨项目工作项。正式业务开发、跨项目接口、缓存、发布、原生-H5 协作等任务应从这里建立任务文件，再进入实现。

## 当前候选任务

候选任务先放在 `hybrid-h5-cache-runtime-backlog.md`。进入开发前，应按 `.ai-workspace/templates/TASK.md` 拆成独立工作项，并将状态推进到 `ready`。

## H5 跨端需求任务

如果任务以 `hybird-meumall` 为主，但需要后端、原生 App、管理后台或 CI/发布配合，必须同时建立：

```text
.ai-workspace/tasks/TASK-YYYY-MMDD-NNN-xxx.md
.ai-workspace/integration-briefs/BRIEF-YYYY-MMDD-NNN-xxx.md
```

并按影响范围补充契约：

```text
.ai-workspace/contracts/api/xxx-api.md
.ai-workspace/contracts/native-bridge/xxx-bridge.md
.ai-workspace/contracts/admin-config/xxx-config.md
```

任务文件回答“我们要做什么、做到什么算完成”；对接说明回答“其他团队需要确认或交付什么”；契约回答“接口、Bridge 或配置结构具体长什么样”。
