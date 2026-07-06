# H5 注册公开固定入口契约

## 状态

active

## 背景

运营注册二维码需要长期稳定。H5 实际页面随版本发布运行在 `/h5-v/<version>/register`，但二维码不能绑定具体版本路径。

## 提供方

- Node register resolver（随 H5 Jenkins 发版部署）
- Java H5 版本管理接口提供 active manifest：`GET /platform/h5Release/active`

## 消费方

- 运营二维码。
- 外部用户浏览器。
- `hybird-meumall` 版本容器作为跳转目标。

## 固定入口

### `GET /register`

用途：公开注册入口 resolver。Nginx 精确代理公网 `/register` 到 Node resolver，resolver 再读取 Java active manifest 后返回 302。

请求 query：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| 其它字段 | string | 否 | 运营渠道、邀请码等参数，原样转发到 H5 注册页 |

说明：测试和正式环境通过域名与部署实例区分，`GET /register` 不接收 `environment` query。

resolver 读取 Java active manifest：

```text
GET {JAVA_H5_RELEASE_API_BASE_URL}/platform/h5Release/active
```

`JAVA_H5_RELEASE_API_BASE_URL` 必须来自当前 H5 环境配置或 Jenkins 环境变量，例如 `hybird-meumall/config/env/h5.test.env`。Java active manifest endpoint 不再拼接 `environment` query。

成功响应：

```http
HTTP/1.1 302 Found
Location: https://hybird.aigcpop.com/h5-v/v1.0.28/register?utm=qr
```

目标 URL 生成规则：

```text
activeManifest.assets.serviceBaseUrl
+ activeManifest.assets.basePath
+ activeManifest.routes["/register"].path
+ forwardedQuery
```

## 错误行为

| 场景 | 状态码 | detail |
| --- | --- | --- |
| 当前部署实例不存在 active manifest 或 Java 返回非 2xx | 502 | `Active manifest request failed` |
| active manifest 未声明 `/register` route | 404 | `Public entry route /register is not available in active manifest` |
| active manifest 缺少 `assets.serviceBaseUrl` | 502 | `Active manifest assets.serviceBaseUrl is missing` |
| active manifest 缺少 `assets.basePath` | 502 | `Active manifest assets.basePath is missing` |

## 发布要求

- H5 注册页发版时，manifest routes 必须包含 `/register`。
- Jenkins 必须同步 `scripts/register-resolver` 并启动 `meu-mall-register-resolver` 容器，默认监听 `127.0.0.1:4110`。
- 运维/Nginx 必须将公网 `https://hybird.aigcpop.com/register` 转发到 Node resolver。
- `/h5-v/<version>/` 继续由 H5 版本容器承载。
- 运营二维码固定使用 `/register`，不得投放 `/h5-v/<version>/register`。

## 回滚

回滚只需要将 active manifest 指向上一稳定版本。`/register` resolver 会自动指向回滚版本的注册页。

## 产品边界

本契约不改变“App 内只有登录、没有注册”的产品事实。该入口是运营投放的外部注册 H5 例外入口，不作为 App 登录页内注册链路。
