# TASK-2026-0611-002-H5 HTTP 请求架构补齐

## 状态

verified

## 目标

在第一阶段请求观测能力基础上，补齐 H5 HTTP 请求架构的固定分层：浏览器端请求诊断、BFF 请求上下文封装、feature API adapter 示例和现有 Runtime 调用迁移，让后续真实接口接入时可以按同一套路径推进。

## 背景

后端 APP 接口仍在补齐。如果现在每个页面各自拼 BFF path、各自处理上下文和 requestId，后续接口数量上来后会很难联调，也很难定位线上问题。

本任务承接：

- `.ai-workspace/tasks/TASK-2026-0611-001-h5-http-observability.md`
- `.ai-workspace/plans/h5-http-observability-architecture.md`

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 新增 H5 浏览器端请求诊断工具，维护 `pageSessionId`、最近请求记录和诊断快照。
- 将 `createH5Client()` 接入浏览器默认上下文和请求诊断记录。
- 新增 `createBffRequestContext()`，统一 BFF route 的 Cookie auth、客户端上下文、backend client 和 logger 创建。
- 将 `/api/bff/user/profile` 示例 route 迁移到 BFF context。
- 新增 `features/home/runtime-api.ts` 并迁移首页 Runtime 面板，避免组件直接拼 BFF path。
- 新增 `features/promotion/api.ts`，集中维护推广模块现有 BFF mock 路径。
- 更新文档和验证记录。

不包含：

- 不接真实 Java / Python 业务接口。
- 不改 Java / Python 后端。
- 不接真实 Sentry、OpenTelemetry 或客服反馈入口。
- 不移除内部 Runtime 调试面板。

## 验收标准

- [x] H5 client 请求成功、业务失败和网络异常时，会记录最近请求诊断。
- [x] H5 client 在浏览器环境下自动带上页面会话和当前路由上下文。
- [x] BFF route 可以通过 `createBffRequestContext()` 获取 auth、clientContext、backendClient 和后端 token。
- [x] BFF backend call logger 输出安全结构，不包含 token。
- [x] 首页 Runtime 面板不再直接拼 `/api/bff/runtime/context`。
- [x] 推广模块现有 BFF path 有集中 adapter，便于后续真实接口迁移。
- [x] 完整验证命令通过并记录结果。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/lib/http/h5-client.test.ts src/lib/http/request-diagnostics.test.ts src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/server/http/bff-response.test.ts src/features/home/runtime-api.test.ts src/features/home/home.test.tsx src/features/promotion/api.test.ts src/features/promotion/promotion-service.test.ts
pnpm typecheck
pnpm lint
cd ..
pnpm run check
```

## 风险和后续

- requestId 端到端检索还依赖 Java / Python 后端记录同一批 header。
- 原生 App 仍需确认 App 名称、版本、build、系统版本、设备型号和 WebView 版本如何提供给 H5。
- 后续真实业务接口接入时，需要为每个 feature 增加 server service 和 mapper，避免页面直接消费后端原始结构。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | implemented | 已完成请求诊断、BFF context、Runtime adapter、Promotion adapter 和文档更新，等待完整验证。 |
| 2026-06-11 | verified | 目标测试、类型检查、lint 和根目录 workflow check 已通过。 |

## 验证记录

```bash
cd hybird-meumall
pnpm test src/lib/http/h5-client.test.ts src/lib/http/request-diagnostics.test.ts src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/server/http/bff-response.test.ts src/features/home/runtime-api.test.ts src/features/home/home.test.tsx src/features/promotion/api.test.ts src/features/promotion/promotion-service.test.ts
pnpm typecheck
pnpm lint
cd ..
pnpm run check
```

结果：

- `pnpm test ...`：通过，9 files / 44 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- 根目录 `pnpm run check`：通过，所有 MeuMall workflow checks passed。
