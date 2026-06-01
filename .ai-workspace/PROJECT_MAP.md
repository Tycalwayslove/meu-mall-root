# 项目地图

## 总览

```text
admin-meumall -> server-meumall -> active manifest
app-meumall   -> server-meumall -> active manifest -> hybird-meumall
meumall-ci    -> hybird-meumall build -> server-meumall release API
```

## 项目职责

### hybird-meumall

H5 商城前台。负责 WebView 内的用户体验、页面路由、H5 runtime、API client、主题、telemetry 和 Native Bridge 消费边界。

不负责：

- manifest 服务端存储。
- iOS WebView 容器实现。
- release 管理台。
- CI 部署平台。

### server-meumall

FastAPI 配置服务。负责 manifest config、release 记录、active manifest、灰度、提升和回滚 API。

不负责：

- 渲染 H5 页面。
- 实现原生容器行为。
- 管理后台 UI。
- 前端构建产物。

如果未来加入业务 API，必须先明确它是临时本地服务、正式业务服务，还是需要拆出新服务。

### app-meumall

SwiftUI 原生壳。负责 App 启动、`WKWebView`、manifest 拉取、原生 tab、URL 拼接、本地 fallback 和原生调试入口。

不负责：

- H5 业务页面。
- 商品、订单、支付等 Web 业务。
- release API 语义。

### admin-meumall

发布与配置管理台。负责展示和操作 server-meumall 提供的配置、release、灰度和回滚能力。

不负责：

- 构建 H5。
- 部署 SSR 服务。
- 保存业务用户数据。
- 实现原生能力。

### meumall-ci

本地 CI 和部署脚手架。负责拉取 H5、测试、构建、部署 standalone 产物、注册 release 和运行 smoke check。

不负责：

- 业务逻辑。
- API 契约定义。
- 页面 UI 行为。

## 跨项目变更规则

- H5 调用后端：先更新 API 契约，再分别实现 server 和 H5。
- H5 调用原生：先更新 Native Bridge 契约，再分别实现 app 和 H5。
- 发布流程变化：先更新 release 契约，再实现 server、admin、CI。
- manifest schema 变化：必须同时评估 H5、server、app、admin 和 CI。
