# TASK-2026-0611-001-H5 HTTP 请求观测第一阶段

## 状态

verified

## 目标

落地 H5 HTTP 请求观测第一阶段：在 H5 -> BFF -> 后端链路中透传 `requestId`、客户端上下文 header，并为后端调用日志提供结构化字段，方便线上按请求、App 版本、系统版本和设备型号定位问题。

## 背景

H5 后续会逐步接入 Apifox 中的真实 APP 接口。当前后端接口仍不完整，如果只做页面直连或散落式请求，后续联调和线上排障会很困难。

已形成设计说明：

- `.ai-workspace/plans/h5-http-observability-architecture.md`

已保存 Apifox 清单：

- `.ai-workspace/contracts/api/apifox-app-interface-inventory-2026-06-11.md`

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 为 H5 browser client 增加客户端上下文 header 构造能力。
- 为 backend client 增加客户端上下文透传能力。
- 为 backend client 增加结构化 backend call log hook。
- 更新 H5 API 文档和 BFF 鉴权契约中的 header 约定。
- 补充单元测试验证 header 和日志行为。

不包含：

- 不修改 Java 后端。
- 不修改 Python 后端。
- 不接入 OpenTelemetry。
- 不实现真实业务接口替换。
- 不实现页面错误 UI 展示 requestId。

## 责任边界

`hybird-meumall`：

- 生成或透传 `x-request-id`。
- 透传 App / 设备 / 系统 / WebView 上下文。
- BFF 调后端时带上安全上下文 header。
- 提供后端调用日志 hook。

后端：

- 本任务不改后端代码。
- 后续任务中需要接收、记录、透传和返回 `x-request-id`，并在入口日志记录客户端上下文。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-bff-http-auth-contract.md`
- 是否向后兼容：是，新增 header 均为可选字段。
- 是否需要迁移：否。
- 是否需要灰度：否。

## 对接说明

- 是否需要对接说明：暂不新增独立 brief，本阶段仅 H5 侧基础设施。
- 对接说明路径：无。
- 需要确认的角色：后端 / 原生 App。
- 当前确认状态：待确认。

## 对方责任

后端：

- 后续确认是否接收并记录 `x-request-id` 和客户端上下文 header。

原生 App：

- 后续确认 H5 可获得的 App 名称、App 版本、build 号、系统版本、设备型号和 WebView 版本来源。

管理后台：

- 无。

CI 或发布：

- 无。

## Mock 和联调方式

- Mock 数据位置：无新增。
- 测试接口环境：本阶段使用单元测试注入 fetcher。
- App 测试包版本：后续联调确认。
- 管理后台测试入口：无。
- 联调步骤：后续用 H5 BFF 请求检查 Java/Python 入口日志是否包含 `requestId` 和客户端上下文。
- H5 fallback：header 缺失时不阻断请求。

## 实现计划

1. 增加客户端上下文类型和 header 构造函数。
2. 更新 H5 client，在请求 BFF 时注入可选上下文 header。
3. 更新 backend client，在请求 Java/Python 时透传上下文 header，并输出结构化日志 hook。
4. 更新示例 BFF route，透传浏览器请求中的上下文到 backend client。
5. 更新文档和契约。
6. 运行单元测试和类型检查。

## 验收标准

- [x] H5 client 请求 BFF 时继续携带 `credentials: "include"` 和 `x-request-id`。
- [x] H5 client 可携带 `x-page-session-id`、`x-app-version`、`x-platform`、`x-os-version`、`x-device-model` 等上下文 header。
- [x] H5 client 不手动设置浏览器禁止的 `User-Agent` header。
- [x] backend client 请求 Java/Python 时可携带原始 `user-agent` 和客户端上下文 header。
- [x] backend client 成功和失败时可通过 logger hook 输出 requestId、backend、path、status、duration、错误码和客户端上下文。
- [x] token 缺失时仍不请求后端。
- [x] 文档说明新增 header 均为可选、向后兼容且不得包含敏感信息。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/lib/http/h5-client.test.ts src/server/http/backend-client.test.ts
pnpm typecheck
```

## 发布影响

- 是否需要发布：后续随 H5 版本发布。
- 发布项目：`hybird-meumall`
- 是否需要灰度：建议跟随 H5 常规灰度。
- 回滚目标：上一版 H5 active manifest。
- smoke check：访问 H5 页面并检查 BFF 请求仍正常返回。

## 风险和阻塞

- 原生 App 侧设备上下文字段来源仍需确认。
- Java/Python 尚未适配时，链路只能在 H5 BFF 侧完整记录，后端内部日志无法按 requestId 精确查询。
- 浏览器端不能可靠手动设置 `User-Agent`，H5 到 BFF 使用浏览器自动 UA；BFF 到后端再透传。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | ready | 创建 H5 HTTP 请求观测第一阶段任务。 |
| 2026-06-11 | verified | 已完成 H5 client、backend client、示例 BFF route、契约和文档更新；聚焦测试与类型检查通过。 |

## 验证记录

```bash
cd hybird-meumall
pnpm test src/lib/http/h5-client.test.ts src/server/http/backend-client.test.ts src/server/http/bff-response.test.ts
pnpm typecheck
pnpm lint
cd ..
pnpm run check
```

结果：

- `pnpm test ...`：通过，3 files / 9 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- 根目录 `pnpm run check`：通过。
