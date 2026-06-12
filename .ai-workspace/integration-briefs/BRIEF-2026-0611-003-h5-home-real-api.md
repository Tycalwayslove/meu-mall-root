# BRIEF-2026-0611-003-H5 首页真实接口对接

## 背景

H5 首页当前使用本地静态数据展示。现在开始接入 Apifox `喵呜商城/APP接口/喵呜达人首页接口` 模块中的真实接口，先让首页首屏看到真实 banner、分类、秒杀和推荐商品，并补齐首页“为您推荐”更多页。

## H5 页面行为

- 首页加载后先展示现有骨架屏。
- H5 浏览器端请求自身 BFF：
  - `/api/bff/home`：首页聚合数据。
  - `/api/bff/home/recommend-products?current=1&size=10`：首页推荐商品分页。
- BFF 请求 Java 后端：
  - `GET /p/app/home/index`
  - `GET /p/app/home/recommendProds?current=1&size=10`
- BFF 将后端数据转换成 H5 首页展示模型。
- 请求失败或字段异常时，首页回落到现有静态数据，不白屏。
- 用户点击首页“为您推荐”右侧“更多”后进入 H5 新页面 `/home/recommend-products`。
- 新页面标题为“相似推荐商品”，布局参考 `/search`：顶部导航、搜索栏、筛选条件和商品列表。
- 新页面请求 `/api/bff/home/for-you-products?current=1&size=10`，BFF 再请求 Java `GET /p/app/home/forYouProds?current=1&size=10`。

## H5 需要后端确认

- 测试环境 `JAVA_API_BASE_URL=https://test.aigcpop.com/mini_h5`。
- 这两个接口已在测试环境验证需要 `mallToken` 鉴权：无 token 时返回 `A00004 Unauthorized`。
- `code` 成功值是否固定为 `00000`，以及失败时 `msg` 的语义。
- banner `jumpType`：
  - `1`：H5 URL。
  - `2`：商品详情。
  - `3`：活动页。
  - `4`：激励活动。
  - `5`：带货排行榜。
- `recommendProds` 作为首页“为您推荐”首屏商品源。
- `forYouProds` 作为“相似推荐商品”更多页商品源。

## 对方交付完成口径

- 测试环境接口可访问。
- 响应字段与 Apifox released 契约一致。
- 空 banner、空分类、空秒杀、空首页推荐商品、空相似推荐商品时返回结构稳定。
- 后端日志能根据 `x-request-id` 查询本次请求。

## Mock 和联调方式

- 当前 H5 保留本地 `homeExperienceData` 作为 fallback。
- H5 BFF 通过 `JAVA_API_BASE_URL` 访问后端。
- H5 不在浏览器端持有后端 token；BFF 从 `mallToken` Cookie 转成 `Authorization`。

## 验收口径

- 正常接口：首页展示真实商品标题、图片、价格、销量和活动标签。
- 首页“为您推荐”更多入口能跳转 `/home/recommend-products`。
- “相似推荐商品”页面能展示搜索栏、筛选条件和商品列表，并通过 `/p/app/home/forYouProds` 获取数据。
- 接口失败：首页仍展示静态 fallback。
- 无推荐商品：推荐区可展示空列表或 fallback 商品，不导致崩溃。
- 请求链路：BFF 日志能看到 requestId、backend path、状态码和耗时。

## 当前状态

- Apifox 模块和 schema 已读取。
- H5 侧开始实现。
- 后端测试 base URL 已按最新联调口径更新为：`https://test.aigcpop.com/mini_h5`。
- 鉴权已按 `mallToken` 处理，仍需 App 联调写入 Cookie 后验证真实数据。
- 接口分工已按最新联调口径修正：首页商品区用 `/p/app/home/recommendProds`，新页面 `/home/recommend-products` 用 `/p/app/home/forYouProds`。
