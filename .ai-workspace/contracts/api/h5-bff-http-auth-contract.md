# H5 BFF HTTP 鉴权契约

## 基本信息

- 契约编号：API-H5-BFF-AUTH-001
- 状态：draft
- 提供方：`hybird-meumall` BFF / Python 后端 / Java 后端 / 原生 App
- 消费方：`hybird-meumall` 页面与业务模块
- 适用环境：test / prod
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0603-006-h5-bff-http-auth.md`
- 关联对接说明：无，当前先以本契约承接

## 背景

MeuMall 登录在原生 App 中完成。H5 WebView 打开时，原生 App 通过 Cookie 将登录态传给 H5。Python 和 Java 后端现阶段都只支持 `Authorization` header 鉴权，不支持 Cookie 鉴权。其中 Python 使用 `Authorization: Bearer <token>`，Java / mall 使用 `Authorization: <token>`，不拼接 `Bearer`。

本契约定义：Cookie 只作为 App 到 H5 服务端的登录态传递方式；H5 服务端调用后端时必须转换为 Authorization header。

## 参与方责任

| 参与方 | 责任 |
| --- | --- |
| 原生 App | 登录成功后在 H5 域名写入 Cookie；登出或 token 失效时清理 Cookie。 |
| H5 浏览器端 | 不读取 token；只请求 H5 BFF；请求携带 `credentials: "include"`。 |
| H5 Next SSR / BFF | 从 Cookie 读取 token；调用后端时写入 Authorization；归一化错误。 |
| Python / Java 后端 | 继续按 Authorization 鉴权；返回明确 401/403。 |

## Cookie 约定

| Cookie | 说明 | 敏感 | JS 可读 | 建议属性 |
| --- | --- | --- | --- | --- |
| `pythonToken` | Python 服务 token | 是 | 否 | `HttpOnly; Secure; Path=/; SameSite=Lax` |
| `mallToken` | Java / mall 服务 token | 是 | 否 | `HttpOnly; Secure; Path=/; SameSite=Lax` |
| `statusHeight` | 手机顶部状态栏高度，H5 按 px 处理 | 否 | 可按需 | `Secure; Path=/; SameSite=Lax` |
| `meu_page_config` | 可选页面启动配置 JSON | 否，禁止放敏感信息 | 可按需 | `Secure; Path=/; SameSite=Lax` |

如果 WebView、跨站跳转或后续域名策略导致 Cookie 不随请求发送，可将 `SameSite` 调整为 `None; Secure`，但必须由原生 App 和 H5 联调确认。

## H5 到 BFF 请求规则

- 浏览器端只请求当前 H5 域名下的 `/api/bff/**`。
- 请求必须携带 `credentials: "include"`。
- 浏览器端不得读取、拼接、打印或持久化 token。
- H5 client 必须自动处理 H5 basePath，例如 `/h5-v/v1.0.3/api/bff/user/profile`。
- H5 首页可以通过 `/api/bff/runtime/context` 展示原生传参调试信息。当前内部联调阶段允许展示完整 Cookie 值；正式业务上线前必须删除或关闭该面板。

## BFF 到后端请求规则

- H5 BFF 从 Cookie 读取 `pythonToken` 和 `mallToken`。
- 调 Python 后端时使用 `pythonToken`，header 为 `Authorization: Bearer <pythonToken>`。
- 调 Java / mall 后端时使用 `mallToken`，header 为 `Authorization: <mallToken>`，不拼接 `Bearer`。
- 调 Java / mall 后端时必须额外注入 `source: 1`。Java 来源枚举为 `1-app`、`2-小程序`、`3-h5`；当前 H5 运行在 App WebView 内，因此按 App 来源传 `1`。
- `statusHeight` 不参与鉴权，只用于 H5 顶部安全区和调试展示。
- 本地开发允许 `APP_ENV=local` 时使用工作区根目录 `.env.local` 或 `hybird-meumall/.env.local` 中的 `H5_LOCAL_PYTHON_TOKEN` / `H5_LOCAL_JAVA_TOKEN` 作为 Cookie 缺失时的临时兜底；测试和正式环境必须忽略该兜底。
- 当接口需要登录态但 Cookie 缺失时，BFF 不请求后端，直接返回 `TOKEN_MISSING`。
- BFF 调用 Python 后端时注入：

```http
Authorization: Bearer <pythonToken>
x-request-id: <request-id>
x-h5-version: <h5-version>
x-app-env: <test|prod>
x-route: <h5-route>
```

BFF 调用 Java / mall 后端时注入：

```http
Authorization: <mallToken>
source: 1
x-request-id: <request-id>
x-h5-version: <h5-version>
x-app-env: <test|prod>
x-route: <h5-route>
```

## 客户端上下文 Header

为了定位线上问题是否和 App 版本、系统版本、设备型号或 WebView 容器有关，H5 请求链路需要透传客户端上下文。

浏览器请求 H5 BFF 时，`User-Agent` 由 WebView 自动携带，H5 client 不手动设置。H5 client 可额外传递以下可选 header：

| Header | 说明 | 是否敏感 |
| --- | --- | --- |
| `x-page-session-id` | 单次页面访问会话 ID。 | 否 |
| `x-h5-version` | H5 版本。 | 否 |
| `x-h5-route` | 当前 H5 页面路由。 | 否 |
| `x-app-name` | App 名称。 | 否 |
| `x-app-version` | App 版本号。 | 否 |
| `x-app-build` | App build 号。 | 否 |
| `x-platform` | `ios` / `android` / `web`。 | 否 |
| `x-os-version` | 系统版本。 | 否 |
| `x-device-model` | 设备型号。 | 否 |
| `x-webview-version` | WebView / WebKit 版本。 | 否 |

BFF 调 Java / Python 后端时，除 `Authorization` 外，还应透传：

```http
user-agent: <WebView 原始 User-Agent>
x-request-id: <request-id>
x-page-session-id: <page-session-id>
x-h5-version: <h5-version>
x-h5-route: <h5-route>
x-app-name: <app-name>
x-app-version: <app-version>
x-app-build: <app-build>
x-platform: <ios|android|web>
x-os-version: <os-version>
x-device-model: <device-model>
x-webview-version: <webview-version>
```

新增 header 均为可选字段，后端缺失时不得拒绝请求。正式环境日志不得记录 token、完整 Cookie、手机号、用户姓名、定位、完整地址或支付敏感信息。

Java / Python 后端第一阶段建议做到：

```text
接收 x-request-id 和客户端上下文 header。
入口日志打印 x-request-id、App 版本、系统版本和设备型号。
调用下游时继续透传 x-request-id。
响应 header 返回 x-request-id。
```

## 环境变量

| 变量 | 是否公开到浏览器 | 说明 |
| --- | --- | --- |
| `APP_ENV` | 否 | 当前运行环境，建议 `test` 或 `prod`。 |
| `JAVA_API_BASE_URL` | 否 | Java 后端 base URL。 |
| `PYTHON_API_BASE_URL` | 否 | Python 后端 base URL。 |
| `H5_LOCAL_JAVA_TOKEN` | 否 | 本地开发可选，仅 `APP_ENV=local` 且 `mallToken` Cookie 缺失时使用。 |
| `H5_LOCAL_PYTHON_TOKEN` | 否 | 本地开发可选，仅 `APP_ENV=local` 且 `pythonToken` Cookie 缺失时使用。 |
| `H5_BFF_LOG_BACKEND_RESPONSE` | 否 | 是否打印 Java / Python 后端响应 body 快照，`1/true` 打开，正式环境默认关闭。 |
| `H5_BFF_BACKEND_RESPONSE_LOG_LIMIT` | 否 | 后端响应 body 日志长度上限，默认 `30000`。 |
| `H5_VERSION` | 否 | 当前 H5 版本。 |
| `NEXT_PUBLIC_H5_BASE_PATH` | 是 | 可选，浏览器端 BFF 路径辅助；缺省时从 location 推导。 |

当前联调域名：

| 后端 | 当前测试 base URL |
| --- | --- |
| Java | `https://test.aigcpop.com/mini_h5` |
| Python | `https://test.aigcpop.com/api` |

`hybird-meumall/config/env/h5.prod.env` 当前只是正式环境配置占位；在正式服务器和域名完成前，它仍按要求指向上述测试域名。

## BFF 响应结构

```ts
type H5BffResult<T> =
  | {
      success: true;
      data: T;
      requestId: string;
    }
  | {
      success: false;
      code: string;
      message: string;
      requestId?: string;
      recoverable: boolean;
    };
```

## 原生传参调试展示规则

`/api/bff/runtime/context` 用于联调阶段观察 App 传给 H5 的信息。

允许展示：

- token 是否存在。
- token 完整值。
- token 长度。
- `statusHeight` 完整值。
- `meu_page_config` 配置。
- Cookie 完整值。
- URL 启动参数。
- H5 当前环境和版本。

限制：

- 该能力仅限内部开发和联调环境。
- 后续正式业务上线前必须删除面板，或增加服务端开关禁止外部环境访问。
- Cookie 完整值不得进入日志、埋点和长期文档截图。

## BFF 后端调用日志

H5 BFF 后端调用日志使用 `[h5-bff-backend-call]`。本地和测试环境可以开启 `H5_BFF_LOG_BACKEND_RESPONSE=1`，同一条日志会包含：

- `requestUrl`、`requestHeaders`、`requestBody`：BFF 发给后端的请求快照。
- `responseBody`、`responseBodySize`、`responseBodyTruncated`：后端原始响应快照。
- `backendBusinessCode`、`backendBusinessMessage`、`backendBusinessSuccess`：从 Java / Python envelope 中提取的业务状态。

`Authorization`、Cookie、token、secret、mobile、phone、address 等字段必须掩码。正式环境默认关闭 `responseBody` 日志；如需短期排查，必须控制采集范围和保留时长。

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `TOKEN_MISSING` | 401 | Cookie 中没有 token。 | 通知原生登录态缺失或过期。 |
| `AUTH_FAILED` | 401 / 403 | 后端认证失败。 | 触发 `token_expired` / logout 联调事件。 |
| `NETWORK_ERROR` | 502 | 后端网络异常。 | 展示可恢复错误并允许重试。 |
| `TIMEOUT` | 504 | 后端请求超时。 | 展示可恢复错误并允许重试。 |
| `HTTP_ERROR` | 原始状态或 502 | 后端非鉴权错误。 | 根据业务场景展示错误。 |
| `PARSE_ERROR` | 502 | 后端响应无法解析。 | 展示系统错误。 |

## SSR / BFF / CSR 调用边界

| 场景 | 推荐方式 | 说明 |
| --- | --- | --- |
| 首屏关键数据 | SSR / Server Component 直接调用 server service | 减少白屏，token 不进入浏览器 JS。 |
| 浏览器交互 | Client Component 调 H5 BFF | 收藏、翻页、提交等操作。 |
| 高敏感数据 | BFF / Server Action | 不把 token 暴露给浏览器。 |
| 无需登录公共数据 | SSR 或 CSR 均可 | 可按缓存和性能决定。 |

## 测试方式

- H5 单元测试：Cookie auth、backend registry、backend client、browser h5 client。
- H5 构建验证：`pnpm typecheck && pnpm build`。
- 联调验证：原生 App 写 Cookie 后打开 H5，BFF 请求后端时能看到 Authorization header。

## 变更流程

1. 更新本契约。
2. 原生 App 确认 Cookie 写入属性。
3. 后端确认 base URL、Authorization 格式和错误语义。
4. H5 更新 BFF / server service。
5. 三方联调验证。
6. 更新任务和测试报告。

## 回滚方式

如果 BFF 体系上线后出现问题，可通过 manifest 回滚到上一 H5 active 版本。后端不需要变更鉴权模式。
