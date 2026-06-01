# Hybrid H5 运行时契约

## 契约名称

Hybrid H5 Runtime Contract

## 提供方

- `app-meumall`：原生容器、WebView 生命周期、tab 管理、原生兜底。
- `hybird-meumall`：H5 页面、路由、运行时状态、错误上报。
- `server-meumall`：active manifest 和 release 元数据。
- `meumall-ci`：H5 构建、部署、release 注册和 smoke check。

## 消费方

- `app-meumall`
- `hybird-meumall`
- `admin-meumall`
- `meumall-ci`

## 目标

统一 Hybrid H5 在 App 内运行时的职责、缓存边界、WebView 复用、弱网兜底和发布安全规则。

## WebView 生命周期规则

一级 tab 包括首页、分类、购物车和我的。原生容器应优先采用“每个一级 tab 一个可复用 WebView”的模式。

要求：

- 首次进入 tab 时懒创建 WebView。
- tab 切换时优先 show/hide，避免 destroy/recreate。
- 不应在每次 tab 点击时强制 reload 当前页面。
- 内存压力下可以回收非当前、非关键 WebView。
- 回收前应通知 H5 保存必要状态。
- 重新创建后，H5 可以基于本地快照恢复弱状态。

二级页面包括商品详情、搜索结果、活动详情、订单详情、支付和地址编辑。二级页面可以在当前 tab 内路由跳转，也可以由原生页面栈 push 新 WebView，但必须保持一级 tab 的滚动位置和状态。

## 页面渲染策略

H5 页面必须按业务性质选择渲染和缓存策略。

| 页面类型 | 推荐策略 | 缓存边界 |
| --- | --- | --- |
| 首页 | ISR、SSG 或公共 SSR | 可缓存公共 HTML 和公共数据 |
| 分类 | SSG 或 ISR | 可缓存分类结构 |
| 商品基础信息 | ISR 或公共 SSR | 可缓存标题、图片、描述、参数 |
| 商品价格和库存 | CSR + no-store API | 只能作为实时结果 |
| 购物车 | CSR 静态壳或 no-store SSR | 不缓存用户 HTML，可展示弱快照 |
| 我的 | CSR 静态壳或 no-store SSR | 不缓存用户 HTML，可展示弱摘要 |
| 订单和支付 | CSR 或 no-store SSR | 不离线承诺 |
| 帮助和协议 | SSG | 可长期缓存 |

## 构建产物边界

允许进入 CDN 或 App 本地静态资源包：

```text
.next/static/
public/offline.html
public/fallback-data/
必要图片和字体
manifest.json
```

禁止进入 App 本地静态资源包：

```text
.next/server/
.next/standalone/
.env*
server.js
node_modules/
服务端密钥
内部配置
```

## 弱网和无网规则

首次打开且无缓存：

- 展示原生或 H5 离线页。
- 不伪造业务数据。
- 提供重试、返回、客服或基础帮助入口。

曾经成功打开且有缓存：

- 可展示缓存快照。
- 必须标记“缓存数据”或“上次更新于”。
- 必须禁用交易类操作。
- 网络恢复后刷新。

弱网但非完全无网：

- 使用 network-first with timeout。
- 超时后可以展示缓存快照。
- 网络成功后更新缓存。
- 不因接口慢导致长时间白屏。

## H5 资源更新规则

如果未来实现 App 本地 H5 资源包，原生侧必须通过版本检查感知更新。

版本检查至少包含：

- H5 version 或 buildId。
- packageUrl。
- sha256。
- size。
- minAppVersion。
- maxAppVersion。
- 灰度命中结果。
- rollbackVersion。

下载和切换必须满足：

- 下载到临时目录。
- 校验 sha256。
- 解压到临时版本目录。
- 校验 manifest 和关键文件。
- 原子切换 current 指针。
- 保留上一个稳定版本。
- 失败时继续使用旧版本。
- 不直接覆盖正在使用的 H5 资源目录。

## 发布顺序

H5 发布必须保证静态资源先于新 HTML 或新 SSR 服务可用。

推荐顺序：

1. 构建 Next.js。
2. 生成 version 或 buildId。
3. 上传静态资源。
4. 上传 H5 资源包，若项目启用。
5. 部署 SSR 服务端产物。
6. 注册 release。
7. 更新 active manifest 或灰度规则。
8. 小流量灰度。
9. 观察指标。
10. 全量。

禁止先切换新 HTML 或 SSR 服务，再上传新 JS/CSS chunk。

## 观测字段

H5 错误和关键性能事件应尽量包含：

- `appVersion`
- `platform`
- `osVersion`
- `webViewType`
- `currentTab`
- `route`
- `h5BuildId`
- `h5ResourceVersion`
- `networkType`
- `isFromCache`
- `serviceWorkerState`
- `nativeResourceHit`
- `userLoginState`

不得包含 token、支付凭证、地址明文或其他敏感信息。

## 变更流程

修改 WebView 生命周期、资源包、发布顺序或页面渲染策略时，必须：

1. 创建工作项。
2. 声明影响项目。
3. 更新本契约。
4. 更新相关子项目文档。
5. 增加验证或人工检查记录。
