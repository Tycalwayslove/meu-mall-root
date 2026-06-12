# 对接说明：H5 商品详情真实接口与立即购买链路

## 基本信息

- 编号：BRIEF-2026-0611-008
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0611-008-h5-product-detail-real-flow.md`
- 状态：verified
- H5 负责人：待定
- 后端负责人：待确认
- 原生 App 负责人：待确认
- 管理后台负责人：无
- 目标联调时间：待定
- 目标上线环境：H5 测试环境后随常规发版

## 需求背景

商品详情是喵呜购买链路核心页面。当前 H5 已有静态高保真页面和购买弹窗，但没有接真实商品、SKU、库存和订单确认校验。本次基于旧 uni-app 商品详情接口，把普通商品快递购买流程迁移到 Next.js H5。

## H5 侧目标

H5 需要完成：

```text
商品详情 -> 选择 SKU / 数量 -> 立即购买 -> 订单确认实时校验
```

本期只做普通商品、快递、SKU 和立即购买。秒杀、拼团、自提、同城、购物车、支付、收藏和分享后置。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 商品详情 | `/product/[id]` | H5 | 使用真实商品详情接口渲染普通商品和 SKU。 |
| 订单确认 | `/order-confirm` | H5 | 根据购买参数重新请求商品接口校验 SKU、价格和库存。 |

## 数据流

```text
用户进入商品详情
  -> H5 /product/[id]
  -> H5 BFF /api/bff/product-detail
  -> Java /prod/prodInfo
  -> H5 渲染商品、SKU、库存
  -> 用户选择 SKU 和数量
  -> H5 /order-confirm
  -> H5 BFF /api/bff/order-confirm
  -> Java /prod/prodInfo 实时校验
  -> H5 渲染订单确认或禁用提交
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 否 | 使用旧 Java 接口。 | `.ai-workspace/contracts/api/h5-product-detail-real-flow-contract.md` |
| 调整接口 | 否 | H5 新增 BFF，不要求后端改造。 | 同上 |
| 鉴权 | 是 | App/H5 Cookie 中的 `mallToken` 由 BFF 转为 Java `Authorization`。 | 同上 |
| 缓存策略 | 是 | 商品基础信息可短缓存；价格、库存和订单确认不可缓存。 | 同上 |
| 错误码 | 是 | 沿用 Java envelope 和 H5 BFF 错误归一。 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本期不新增 Bridge。 | 无 |
| 原生页面跳转 | 否 | 商品详情到订单确认是 H5 内部 push。 | `.ai-workspace/contracts/h5-native-route-contract.md` |
| 登录态 | 是 | WebView 打开 H5 时需要写入 `mallToken` Cookie。 | `.ai-workspace/contracts/api/h5-bff-http-auth-contract.md` |
| 最低 App 版本 | 否 | 沿用已有 WebView 和 Cookie 能力。 | 无 |
| fallback | 是 | 无 token 时 H5 展示鉴权失败/可恢复错误。 | 同上 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 否 | 本期不接后台配置。 | 无 |
| 素材管理 | 否 | 商品图由商品接口返回。 | 无 |
| 上下线开关 | 否 | 无。 | 无 |
| 排序规则 | 否 | 无。 | 无 |
| 灰度规则 | 否 | 随 H5 常规发版。 | 无 |

## H5 侧责任

- [x] 页面结构和状态。
- [x] BFF 到 Java 商品接口调用。
- [x] loading、error、empty、未登录和库存不足状态。
- [x] 商品/SKU/订单确认 mapper。
- [x] 自动化测试和构建验证。
- [ ] App WebView 注入真实 `mallToken` 后的端上联调验证。

## 对方责任

### 后端

- [ ] 确认测试环境 `/prod/prodInfo` 支持普通商品快递和 SKU 字段。
- [ ] 保持 Java `Authorization: <mallToken>` 鉴权方式。

### 原生 App

- [ ] 测试包 WebView 打开 H5 时写入有效 `mallToken` Cookie。

### 管理后台

- [ ] 无。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/product/mock/product-detail.ts`。
- 测试接口环境：`https://test.aigcpop.com/mini_h5`。
- App 测试包版本：待 App 同学确认。
- 管理后台测试入口：无。
- 联调步骤：
  1. 打开 `/product/1000054`。
  2. 检查 BFF 日志包含 Java `/prod/prodInfo` 出站请求。
  3. 选择 SKU 和数量。
  4. 点击确认进入 `/order-confirm`。
  5. 检查订单确认页重新请求商品接口并校验 SKU、价格、库存。

## H5 兜底策略

- 接口失败：展示可恢复错误，不白屏。
- 商品不存在：展示商品不可见状态。
- SKU 缺失：禁用立即购买，提示暂无可购买规格。
- 库存不足：禁用确认或把数量压到库存范围内。
- 用户未登录/token 无效：展示鉴权失败，引导回 App 登录能力；本期不新增登录 Bridge。

## 验收标准

- [x] H5 页面成功状态可用。
- [x] H5 页面 loading、error、empty 状态可用。
- [x] BFF 契约与文档一致。
- [x] 后端旧接口路径和鉴权方式已通过 BFF 契约与测试覆盖；真实成功态仍需有效 `mallToken` 端上联调。
- [x] 订单确认页不信任 URL 价格，必须重新请求商品接口。
- [x] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 商品详情真实接口迁移需要确认/配合：
1. 后端继续提供 Java /prod/prodInfo，H5 本期只消费普通商品 + 快递 + SKU。
2. 原生 App 确保 WebView H5 域名下有 mallToken Cookie。
3. H5 通过 /api/bff/product-detail 和 /api/bff/order-confirm 转发，不让浏览器直接请求 Java 后端。

契约文档：
.ai-workspace/contracts/api/h5-product-detail-real-flow-contract.md

联调方式：
打开 /product/1000054，选择 SKU 后进入 /order-confirm，检查 H5 BFF 日志和页面状态。

验收口径：
商品详情和订单确认都能使用真实商品接口，SKU/库存/价格校验通过；无 token 或接口失败时 H5 不白屏。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-11 | 产品/H5 | 已确认 | 使用旧接口，本期只做普通商品、快递、SKU、立即购买和订单确认。 |
