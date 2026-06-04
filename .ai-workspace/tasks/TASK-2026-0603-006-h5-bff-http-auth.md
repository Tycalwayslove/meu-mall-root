# TASK-2026-0603-006-H5 BFF 与 HTTP 鉴权体系

## 状态

released

## 目标

为 `hybird-meumall` 建立一套可长期复用的 HTTP 请求体系：原生 App 通过 Cookie 将登录态传给 H5，Next SSR / BFF 从 Cookie 读取 token，再以 `Authorization: Bearer <token>` 方式调用 Python / Java 后端。

## 背景

MeuMall 没有 H5 注册流程，登录在原生 App 内完成。当前 Python 和 Java 后端都只支持 `Authorization` 鉴权，暂不支持 Cookie 鉴权。为了避免 H5 浏览器端 JS 直接读取 token，需要让 Cookie 只作为 App 到 H5 服务端的安全传递通道，由 Next 服务端统一转换为后端要求的 Authorization header。

## 涉及项目

- `hybird-meumall`
- 原生 App
- Python 后端
- Java 后端

## 范围

包含：

- 建立 H5 BFF HTTP 鉴权契约。
- 新增 H5 服务端 Cookie auth 读取工具。
- 新增服务端后端 registry，支持 Java / Python base URL 按环境注入。
- 新增服务端 backend client，统一注入 Authorization、requestId、H5 版本、环境和路由信息。
- 新增浏览器端 H5 client，只请求自身 BFF，自动处理 basePath 和 `credentials: "include"`。
- 新增示例 BFF route，展示 Cookie token 转 Authorization 的调用链。
- 首页展示原生 App 传给 H5 的 Cookie 摘要、页面配置、URL 启动参数和 H5 环境信息。
- 更新 H5 API 文档、项目状态和测试报告。

不包含：

- 不实现真实登录、注册或 token 刷新。
- 不要求 Python / Java 后端支持 Cookie 鉴权。
- 不接真实用户、商品、订单业务接口。
- 不在浏览器 JS 中读取或持久化 token。
- 本阶段首页调试面板会展示完整 Cookie 值；该面板仅限内部联调，后续正式业务上线前必须删除或关闭。

## 责任边界

`hybird-meumall`：

- 从请求 Cookie 中读取原生写入的 H5 登录态。
- 在 SSR / BFF 中转换为 `Authorization` header。
- 封装浏览器端 BFF client 和服务端 backend client。
- 归一化请求错误和 401/403 处理。

原生 App：

- 完成登录。
- 在打开 WebView 前写入 H5 域名 Cookie。
- token 过期或登出时清理 Cookie，并可通过 Bridge 通知 H5。

Python / Java 后端：

- 继续按 `Authorization: Bearer <token>` 鉴权。
- 提供测试/正式环境 API base URL。
- 返回统一 401/403 语义。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-bff-http-auth-contract.md`
- 是否向后兼容：新增 H5 BFF 体系，不影响当前后端鉴权方式。
- 是否需要迁移：后续 H5 页面接口应逐步通过 BFF / server services 接入。
- 是否需要灰度：上线真实业务接口时需要按页面/版本灰度。

## 对接说明

- 是否需要对接说明：本阶段先用契约承接。
- 对接说明路径：无。
- 需要确认的角色：原生 App / 后端
- 当前确认状态：暂用 mock

## 对方责任

后端：

- 确认 Java / Python 测试和正式 base URL。
- 确认 Authorization 格式和 401/403 错误语义。

原生 App：

- 确认 Cookie name、Domain、Path、Secure、HttpOnly、SameSite。
- 确认 manifest 刷新后 WebView 是否能携带 Cookie 访问 H5。

管理后台：

- 本阶段无直接依赖。

CI 或发布：

- 后续部署真实环境时注入 `JAVA_API_BASE_URL`、`PYTHON_API_BASE_URL`、`APP_ENV`、`H5_VERSION` 等服务端环境变量。
- 已将包含首页原生传参调试面板的 H5 `v1.0.4` 发布并切为 active。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/server/**/__tests__` 和 `src/lib/http/**/__tests__`。
- 测试接口环境：先通过注入 `fetcher` 验证，不依赖真实后端。
- App 测试包版本：后续 Cookie 写入联调时确认。
- 管理后台测试入口：无。
- 联调步骤：App 写入 Cookie 后打开 H5；H5 BFF 读取 Cookie；服务端请求后端时携带 Authorization。
- H5 fallback：Cookie 缺失时返回 `TOKEN_MISSING`，浏览器端收到 401/鉴权失败后通知原生 token 失效。
- 首页调试展示：通过 `/api/bff/runtime/context` 读取服务端 Cookie 和 URL 参数，展示 token、`meu_page_config`、Cookie 明细和 URL 参数原始值，方便内部联调。

## 实现计划

1. 写失败测试，覆盖 Cookie auth、backend registry、backend client、browser h5 client。
2. 实现最小可用的服务端 auth/http 模块和浏览器端 h5 client。
3. 增加示例 BFF route，展示 Cookie token 到 Authorization 的转换。
4. 首页增加原生传参展示面板。
5. 更新 API 文档和项目状态。
6. 运行测试、类型检查和构建。

## 验收标准

- [x] Cookie token 能在服务端被读取，但不要求浏览器 JS 读取 token。注：2026-06-04 已通过 `TASK-2026-0604-001-native-cookie-runtime-context` 将单一 `meu_access_token` 升级为 `pythonToken` / `mallToken` / `statusHeight`。
- [x] 服务端 backend client 调用 Java / Python 后端时会注入 `Authorization: Bearer <token>`。
- [x] 后端 base URL 通过服务端环境变量区分测试和正式。
- [x] 浏览器端 H5 client 请求 BFF 时自动拼当前 H5 basePath，并带 `credentials: "include"`。
- [x] Cookie 缺失时不请求后端，返回 `TOKEN_MISSING`。
- [x] H5 文档记录 SSR、BFF、CSR 调用边界。
- [x] 首页可展示原生传参调试信息，包含完整 Cookie 值和页面配置。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/server/auth/cookie-auth.test.ts src/server/http/backend-registry.test.ts src/server/http/backend-client.test.ts src/lib/http/h5-client.test.ts
pnpm test src/server/runtime/native-context.test.ts
pnpm typecheck
pnpm build
pnpm test
pnpm run ai:check-workflow
```

## 发布影响

- 是否需要发布：已发布并切 active。
- 发布项目：`hybird-meumall`。
- 版本：`v1.0.4`。
- Git commit：`b2b63ac77f622e3438c9660f69d738b640ee2b7e`。
- Git tag：`h5/v1.0.4`。
- release id：`60381a7a-ab95-4344-b2ce-086092ce14ca`。
- active manifest：`stableVersion=v1.0.4`，`configVersion=config-v1.0.4`，`basePath=/h5-v/v1.0.4`。
- 是否需要灰度：本次按用户要求直接 active。
- 回滚目标：`v1.0.3`。
- smoke check：`/api/health`、首页、`/api/bff/runtime/context` 均已通过公网验证。

## 风险和阻塞

- 原生 Cookie 属性尚未最终确认。
- 后端真实 base URL、错误格式和 token 刷新策略尚未确认。
- WebView Cookie 写入和 SameSite 行为需要在 iOS / Android 真机验证。
- 首页调试面板会展示完整 Cookie 值，仅限当前内部开发环境；后续正式业务开放前必须删除或关闭。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-03 | in_progress | 创建 H5 BFF 与 HTTP 鉴权体系工作项，开始实现基础设施。 |
| 2026-06-03 | implemented | 完成 Cookie auth、backend registry、backend client、H5 client、BFF response 和示例 route；自动化验证通过。 |
| 2026-06-03 | implemented | 首页增加原生传参展示面板，通过 `/api/bff/runtime/context` 展示 Cookie、页面配置和 URL 参数原始值；该面板仅限内部调试。 |
| 2026-06-03 | released | H5 `v1.0.4` 发布并切为 active；验证 health、首页和 runtime context Cookie 调试接口均通过。 |
