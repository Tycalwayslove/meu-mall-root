# TASK-2026-0611-007-BFF 后端业务码日志增强

## 状态

verified

## 目标

增强 H5 BFF 后端调用日志，避免 Java / Python 后端 HTTP 200 但业务响应失败时，被误判为请求成功。

## 背景

首页 BFF 日志显示 Java HTTP `backendStatus=200`，但浏览器收到 `401 AUTH_FAILED`。原因是 Java 后端以 HTTP 200 返回业务错误 `success:false / code:A00004 / msg:Unauthorized`，H5 service 再将其转换为 BFF 的 `AUTH_FAILED`。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- `[h5-bff-backend-call]` 日志补充后端业务响应字段。
- API 文档补充 HTTP 状态和业务状态的区别。
- 增加回归测试。

不包含：

- 不改变后端接口。
- 不改变 `A00004` 到 `AUTH_FAILED` 的映射。
- 不记录 token 或敏感数据。

## 责任边界

H5：

- 记录 HTTP 状态和业务状态。
- 将后端业务鉴权失败转换成前端统一 `AUTH_FAILED`。

Java / Python 后端：

- 负责返回业务 code / msg / success。

## 契约影响

- 是否影响跨项目契约：否，仅增强 H5 BFF 日志。
- 是否向后兼容：是。
- 是否需要迁移：否。
- 是否需要灰度：否。

## 对接说明

- 对接说明路径：无新增。
- 需要确认角色：H5、测试。
- 当前确认状态：已实现。

## 对方责任

- 测试排查时同时看 `backendStatus` 和 `backendBusinessCode`。

## Mock 和联调方式

- 使用 mock 后端返回 `{ code: "A00004", msg: "Unauthorized", success: false }` 验证日志字段。

## 验收标准

- [x] HTTP 200 + 业务失败时，日志包含 `backendBusinessCode`。
- [x] 日志不输出 token。
- [x] API 文档说明 HTTP 状态与业务状态差异。
- [x] 目标测试、类型检查、lint 和根级工作流检查通过。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/features/home/home-real-api.test.ts
pnpm typecheck
pnpm lint
cd ..
pnpm run check
```

## 发布影响

- 是否需要发布：需要随 H5 后续版本发布。
- 发布项目：`hybird-meumall`
- 是否影响 manifest：否。
- 是否需要灰度：否。
- 回滚目标：回退日志字段增强。
- smoke check：触发 `/api/bff/home`，确认日志包含 `backendBusinessCode`。

## 风险和阻塞

- 当前只提取通用 envelope 字段：`code`、`msg/message`、`success`。若后端返回其他结构，需要按接口再补映射。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | verified | 已补充 backend business code 日志和文档说明。 |
| 2026-06-11 | verified | 追加 BFF 后端出站请求快照日志：`requestUrl`、`requestQuery`、`requestBody`、`requestHeaders`，敏感字段掩码输出。 |
| 2026-06-11 | verified | 按 Java 联调结果修正 Authorization 格式：Java / mall 使用裸 token，Python 继续使用 Bearer。 |
| 2026-06-11 | verified | 整合 Java `ResponseEnum` 启用码表，补充 `A00004 -> AUTH_FAILED`、`A00005 -> HTTP_ERROR` 映射。 |
| 2026-06-11 | verified | 增加可开关的后端响应 body 快照日志，用于本地/测试查看 Java 原始响应并区分后端数据问题和 H5 mapper 问题。 |

## 验证记录

- `pnpm test src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/features/home/home-real-api.test.ts`：通过，3 files / 12 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- 根目录 `pnpm run check`：通过。
- 追加验证：`pnpm test src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/features/home/home-real-api.test.ts`：通过，3 files / 14 tests。
- 追加验证：`pnpm typecheck`：通过。
- 追加验证：`pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- Java Authorization 格式追加验证：`pnpm test src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/features/home/home-real-api.test.ts`：通过，3 files / 15 tests。
- Java ResponseEnum 追加验证：`pnpm test src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/server/http/java-response-codes.test.ts src/features/home/home-real-api.test.ts`：通过，4 files / 18 tests。
- 后端响应快照追加验证：`pnpm test src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/server/http/java-response-codes.test.ts src/features/home/home-real-api.test.ts`：通过，4 files / 23 tests。
