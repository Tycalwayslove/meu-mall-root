# Hybrid H5 缓存与运行时任务候选池

## 状态

draft

## 背景

本候选池来自 Hybrid H5 电商缓存、WebView 生命周期、离线兜底和发布安全规则的整理。它不是单个开发任务。进入实现前，必须拆分为独立工作项。

## 候选任务

### 1. 梳理页面和接口缓存分类表

涉及项目：

- `hybird-meumall`
- `server-meumall` 或未来业务服务

目标：

- 建立页面到 SSR、ISR、SSG、CSR 的分类表。
- 建立 API 到 public、semi-public、private、transactional 的分类表。
- 明确每类数据的缓存位置和 TTL。

验收：

- 分类表覆盖首页、分类、商品详情、推广、我的、订单确认、订单或购买记录、支付。
- 每类接口都有缓存和 no-store 规则。

### 2. 改造 iOS 一级 Tab WebView 复用策略

涉及项目：

- `app-meumall`
- `hybird-meumall`

目标：

- 评估当前 tab 切换是否重建 WebView。
- 设计每个一级 tab 一个可复用 WebView 的实现路径。
- 定义内存压力下的回收和 H5 状态保存机制。

验收：

- tab 切换不强制 reload。
- 首页、分类、推广、我的可以保留基本状态。
- WebView 回收前有状态保存事件或降级方案。

### 3. 定义 H5 离线兜底和缓存快照规则

涉及项目：

- `hybird-meumall`
- `app-meumall`

目标：

- 明确首次无网、弱网、有缓存三类体验。
- 设计离线页、快照标识、重试和禁用交易操作规则。

验收：

- 无网不展示伪造交易数据。
- 快照数据有“缓存数据”或“上次更新于”标识。
- 交易类操作无网不可继续。

### 4. 补齐 Native Bridge 生命周期事件

涉及项目：

- `app-meumall`
- `hybird-meumall`

目标：

- 定义 `tabVisible`、`tabHidden`、`networkChanged`、`loginStateChanged`、`memoryWarning` 等事件。
- 定义 H5 `ready`、`routeChanged`、`saveStateBeforeDestroy`、`reportError` 等事件。
- 补齐能力检测和旧 App fallback。

验收：

- H5 调用原生前做能力检测。
- 老 App 缺能力时页面可降级。
- 登录态变化能通知所有相关 WebView。

### 5. 为 H5 release 增加静态资源先行验证

涉及项目：

- `meumall-ci`
- `hybird-meumall`
- `server-meumall`

目标：

- 在部署或注册 release 前验证新 HTML 引用的 JS/CSS chunk 已可访问。
- 明确静态资源先于 SSR 或 manifest 切换可用。

验收：

- smoke check 覆盖至少一个页面 HTML 和关键 chunk。
- 发布失败不会更新 active manifest。
- 回滚目标明确。

### 6. 补齐白屏、chunk load error 和缓存命中观测

涉及项目：

- `hybird-meumall`
- `app-meumall`

目标：

- 统一错误上下文字段。
- 补齐白屏率、chunk load error、Tab 切换耗时、WebView 创建耗时、缓存命中来源等指标。

验收：

- H5 错误包含 route、h5BuildId、appVersion、networkType。
- 上报不包含敏感信息。
- WebView 和 H5 关键性能事件能关联。

### 7. 评估 Service Worker 是否适合当前 WebView

涉及项目：

- `hybird-meumall`
- `app-meumall`

目标：

- 检查目标 iOS WKWebView 和未来 Android WebView 对 Service Worker 的支持。
- 判断是否先采用 Native fallback + HTTP cache + IndexedDB 快照。

验收：

- 输出兼容性结论。
- 明确是否启用 Service Worker。
- 若启用，必须有灰度开关和回滚方案。
