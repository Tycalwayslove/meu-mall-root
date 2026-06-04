# TASK-2026-0604-001-native-cookie-runtime-context

## 状态

released

## 目标

将原生 App 传给 H5 的 Cookie 契约从单一 `meu_access_token` 调整为 `pythonToken`、`mallToken`、`statusHeight` 三个值，并让 H5 BFF 和首页调试面板按新字段读取。

## 背景

原生 App 与 H5 联调过程中，Cookie 写入字段发生变化：

- `pythonToken`：后续调用 Python 服务使用。
- `mallToken`：后续调用 Java / mall 服务使用。
- `statusHeight`：手机顶部状态栏高度，H5 用于顶部安全区处理。

## 涉及项目

- `hybird-meumall`
- `app-meumall`
- 根目录 `.ai-workspace`

## 范围

包含：

- 更新 H5 服务端 Cookie 读取逻辑。
- Java BFF 示例改用 `mallToken`。
- 预留 Python BFF 使用 `pythonToken` 的统一 helper。
- 首页原生传参调试面板展示两个 token 和 `statusHeight`。
- 将 `statusHeight` 写入 CSS 变量，供后续页面顶部安全区使用。
- 更新 API 鉴权契约和 H5 API 文档。
- 更新相关测试。

不包含：

- 不实现真实 Python / Java 业务接口。
- 不实现原生 App Cookie 写入代码。
- 不发布线上版本。
- 不改支付、分享或其他 Bridge 能力。

## 责任边界

`hybird-meumall`：

- 读取 Cookie 并在 BFF 调后端时选择正确 token。
- 展示调试信息并提供 CSS 变量。
- 不负责原生 Cookie 写入。

`app-meumall`：

- 在打开 H5 WebView 前写入 `pythonToken`、`mallToken`、`statusHeight`。
- token 失效或登出时清理 Cookie。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-bff-http-auth-contract.md`
- 变更类型：不兼容字段替换。
- 是否需要迁移：当前线上仅内部联调，按新字段直接切换。
- 是否需要灰度：后续发布到测试环境时通过 H5 版本切换验证。

## 对接说明

- 是否需要对接说明：本次先更新契约和调试面板。
- 当前确认状态：用户已确认 Cookie 新字段。

## 对方责任

原生 App：

- 写入 `pythonToken`、`mallToken`、`statusHeight`。
- 确认 Cookie Domain、Path、Secure、HttpOnly、SameSite。

## Mock 和联调方式

- 本地测试通过构造 Cookie header 验证。
- 真机联调时打开首页，查看原生传参面板是否展示三个字段。
- Java BFF 调用时必须使用 `mallToken`。
- Python BFF 调用时必须使用 `pythonToken`。

## 验收标准

- [x] `readCookieAuthFromHeader` 能读取 `pythonToken`、`mallToken` 和 `statusHeight`。
- [x] Java BFF 示例使用 `mallToken`。
- [x] `statusHeight` 能进入 runtime context，并写入 CSS 变量。
- [x] 首页调试面板展示 Python Token、Mall Token、状态栏高度。
- [x] 契约和 H5 API 文档同步更新。
- [x] 相关测试通过。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/server/auth/cookie-auth.test.ts src/server/runtime/native-context.test.ts src/server/http/backend-client.test.ts
pnpm typecheck
pnpm test
pnpm build
```

## 发布影响

- 是否需要发布：已发布并切 active。
- 发布项目：`hybird-meumall`。
- 版本：`v1.0.5`。
- Git commit：`4832c9a3570b4ee9c927ae0b9931314a197fc9fe`。
- Git tag：`h5/v1.0.5`。
- release id：`ce2d6dc0-51df-41c9-a0e6-b63e34384620`。
- active manifest：`stableVersion=v1.0.5`，`configVersion=config-v1.0.5`，`basePath=/h5-v/v1.0.5`。
- 回滚目标：`v1.0.4`。
- smoke check：`/api/health`、首页、active manifest、`/api/bff/runtime/context` 均已通过公网验证。

## 验证结果

- `pnpm test src/server/auth/cookie-auth.test.ts src/server/runtime/native-context.test.ts src/server/http/backend-client.test.ts`：通过，3 files / 9 tests。
- `pnpm test`：通过，19 files / 89 tests。
- `pnpm typecheck`：通过。
- `pnpm build`：通过。

## 风险和阻塞

- `statusHeight` 单位默认按 px 处理，需要原生 App 确认是否已转换为 CSS px。
- `pythonToken` / `mallToken` 是否设置 `HttpOnly` 需要原生 App 联调确认。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-04 | in_progress | 用户确认 Cookie 新字段，开始修改 H5 读取逻辑和文档。 |
| 2026-06-04 | verified | 完成 `pythonToken` / `mallToken` / `statusHeight` 读取、展示、CSS 变量和文档同步；专项测试、全量测试、类型检查和构建通过。 |
| 2026-06-04 | released | H5 `v1.0.5` 发布并切为 active；回滚目标 `v1.0.4`；公网 smoke 验证通过。 |
