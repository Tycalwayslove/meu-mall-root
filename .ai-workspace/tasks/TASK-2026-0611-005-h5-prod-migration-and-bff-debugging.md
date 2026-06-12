# TASK-2026-0611-005-H5 正式迁移说明与 BFF 排错补齐

## 状态

verified

## 目标

补齐 H5 正式环境迁移说明、修正首页旧 active config 请求路径问题，并明确 BFF 层日志查看和 requestId 排查方式。

## 背景

三套环境 profile 已建立后，还需要让团队清楚正式迁移时到底改配置还是改代码。同时，首页旧模块配置接口 `/api/h5/home/config/active` 在线上返回 404，当前首页真实数据已经改为 BFF，不应继续请求旧接口。

## 涉及项目

- `hybird-meumall`
- 根级契约文档

## 范围

包含：

- 首页停止请求旧 `GET /api/h5/home/config/active?environment=prod`。
- 清理首页旧远程配置 fetch helper，避免后续误用错路径。
- 首页 BFF route 异常时输出 `[h5-bff-route-error]`。
- API 规范补充正式环境迁移清单和 BFF 日志排查方式。
- 发布规范补充正式迁移分层说明。

不包含：

- 不修改 Java / Python 后端。
- 不实现新的首页配置中心。
- 不发布线上版本。

## 责任边界

H5：

- 首页业务数据走 `/api/bff/home`。
- 当前 H5 active 版本走 `/api/h5/manifest/active?environment=prod`。
- BFF 日志输出 requestId、后端路径、状态码、错误码和耗时。

server-meumall / 发布平台：

- 提供 active manifest。
- 后续如重新启用首页配置中心，需要重新确认契约和可访问路径。

## 契约影响

- 是否影响跨项目契约：是，明确旧首页配置接口不再作为当前版本或首页数据入口。
- 契约文档路径：`.ai-workspace/contracts/homepage-config-contract.md`
- 是否向后兼容：是，H5 停止消费旧接口。
- 是否需要迁移：否。
- 是否需要灰度：随 H5 后续版本灰度。

## 对接说明

- 对接说明路径：无新增。
- 需要确认角色：测试、发布、后端。
- 当前确认状态：H5 当前使用 manifest active + 首页 BFF。

## 对方责任

- 测试按 `/api/bff/home` 验证首页真实数据。
- 发布按 `/api/h5/manifest/active?environment=prod` 验证 active 版本。
- 后端日志后续按 `x-request-id` 与 H5 BFF 日志串联。

## Mock 和联调方式

- 首页模块配置继续使用本地 `defaultHomeConfig`。
- 首页真实数据接口失败时继续 fallback 到本地 `homeExperienceData`。

## 验收标准

- [x] 首页运行路径不再调用旧首页配置接口。
- [x] 源码中不再保留旧首页配置 fetch helper。
- [x] 文档明确正式迁移改哪些 profile 和哪些发布项。
- [x] 文档明确 BFF 日志前缀、字段和排查方式。
- [x] 目标测试、类型检查、lint 和根级工作流检查通过。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/features/home/home.test.tsx src/features/home/home-real-api.test.ts src/server/http/bff-context.test.ts
pnpm typecheck
pnpm lint
cd ..
pnpm run check
```

## 发布影响

- 是否需要发布：需要随 H5 后续版本发布。
- 发布项目：`hybird-meumall`
- 是否影响 manifest：否。
- 是否需要灰度：建议随 H5 常规灰度。
- 回滚目标：上一版 H5 active manifest。
- smoke check：访问首页，确认不再请求 `/api/h5/home/config/active`，首页数据请求为 `/api/bff/home`。

## 风险和阻塞

- 如果后续产品重新需要“首页模块远程配置”，需要重新确认 server-meumall 真实路径和契约，不要复用旧路径。
- 线上日志平台尚未正式接入，当前说明先按 Node SSR 容器日志 / 平台日志系统承接。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | verified | 已移除旧首页配置请求、补充 BFF route 错误日志、完善迁移和排错文档，并完成验证。 |

## 验证记录

- `pnpm test src/features/home/home.test.tsx src/features/home/home-real-api.test.ts src/server/http/bff-context.test.ts`：通过，3 files / 16 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- 根目录 `pnpm run check`：通过。
