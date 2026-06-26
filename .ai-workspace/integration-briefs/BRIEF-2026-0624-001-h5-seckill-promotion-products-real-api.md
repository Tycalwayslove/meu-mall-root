# BRIEF-2026-0624-001-H5 秒杀和推广商品真实接口联调

## 背景

首页活动区固定展示「限时秒杀」和「推广带货」。当前两个落地页 `/seckill`、`/promotion/products` 已有高保真静态页面，本次联调要把商品列表切到 Java 真实分页接口，并支持进入现有商品详情。

## H5 页面行为

- 首页点击「限时秒杀」进入 `/seckill`。
- `/seckill` 请求 H5 BFF `/api/bff/seckill/products`，BFF 调 Java `GET /p/app/home/seckillProds`。
- 秒杀商品卡和「秒杀」按钮点击 `/product/<prodId>`。
- 首页点击「推广带货」进入 `/promotion/products`。
- `/promotion/products` 请求 H5 BFF `/api/bff/promotion/products`，BFF 调 Java `GET /p/distribution/prod/productPage`。
- 推广商品卡点击 `/product/<prodId>`；推广按钮沿用 `event/share` Bridge，payload 使用真实 `prodId`。
- BFF 失败、接口空数据或字段异常时，页面展示空态或可恢复状态，不拼接本地 mock 商品。

## H5 需要后端确认

- `/p/app/home/seckillProds` 测试环境可用，返回当前可展示秒杀商品。
- `/p/distribution/prod/productPage` 测试环境可用，支持分页、商品名搜索和排序。
- 两个接口是否都使用 `mallToken` 鉴权。
- 秒杀商品点击普通商品详情 `/product/<prodId>` 是否满足当前联调阶段。
- 推广商品分类 ID 来源和排序枚举是否与 Apifox 一致。

## 对方交付完成口径

- 两个接口在测试环境可访问。
- 响应字段与 Apifox released 契约一致。
- 空列表时返回稳定分页结构。
- 后端日志可以通过 `x-request-id` 查询。

## 联调方式

- H5 链调阶段以 Java 返回为准；接口空列表展示空态，不拼接本地 mock。
- H5 浏览器端只请求自身 BFF，不直连 Java。
- H5 BFF 从 `mallToken` Cookie 转成 Java `Authorization`。
- 联调时用 App WebView 注入有效 `mallToken`，或独立 H5 调试页写入本地 token。

## 验收口径

- `/seckill` 能展示真实秒杀商品名称、价格、原价、销量、库存、限购和剩余时间。
- `/seckill` 商品卡/按钮进入 `/product/<prodId>`。
- `/promotion/products` 能展示真实商品名称、价格、销量和预计佣金。
- `/promotion/products` 推广按钮分享 payload 使用真实 `prodId`。
- 接口失败或空数据时两个页面不白屏，并且不拼接本地 mock 商品。

## 当前状态

- Apifox `main` 分支已查询到两个 released 接口。
- H5 侧已完成 BFF、mapper、页面接入和自动化验证。
- 仍需 App 注入有效 `mallToken` 后做真实环境人工联调。
