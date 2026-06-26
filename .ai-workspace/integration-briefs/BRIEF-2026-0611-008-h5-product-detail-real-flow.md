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

商品详情是喵呜购买链路核心页面。当前 H5 已有静态高保真页面和购买弹窗，但没有接真实商品、SKU、库存、订单确认校验和订单创建。本次基于旧 uni-app 商品详情与普通下单接口，把普通商品快递购买流程迁移到 Next.js H5。

## H5 侧目标

H5 需要完成：

```text
商品详情 -> 选择 SKU / 数量 -> 立即购买 -> 订单确认实时校验
  -> 提交普通快递订单 -> 返回待支付订单号 -> 收银台展示支付信息
```

本期只做普通商品、快递、SKU、立即购买、创建待支付订单和收银台支付信息展示。秒杀、拼团、自提、同城、购物车、真正确认付款、支付 Bridge、支付结果、收藏和分享后置。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 商品详情 | `/product/[id]` | H5 | 使用真实商品详情接口渲染普通商品和 SKU。 |
| 订单确认 | `/order-confirm` | H5 | 根据购买参数和默认/选中收货地址重新校验 SKU、价格、库存和配送，并提交普通快递订单。 |
| 收银台 | `/pay-way` | H5 | 读取订单支付信息并展示金额、倒计时和支付方式；确认付款按钮本期只提示“已发起支付”。 |
| 收货地址 | `/address`、`/address/edit` | H5 | 地址列表、详情、新增、编辑、设默认和删除通过 H5 BFF 接入旧 Java 地址接口。 |

## 数据流

```text
用户进入商品详情
  -> H5 /product/[id]
  -> H5 BFF /api/bff/product-detail
  -> App Bridge rpc/address.getDefault 获取默认地址（可用时）
  -> Java /prod/prodInfo
  -> H5 渲染商品、SKU、库存
  -> 用户选择 SKU 和数量
  -> H5 /order-confirm
  -> H5 BFF /api/bff/order-confirm
  -> App Bridge rpc/address.getDefault 获取默认地址（URL 未带 addressId 时）
  -> Java /p/address/addrInfo/{addrId|0} 解析默认/选中收货地址
  -> Java /prod/prodInfo 实时校验
  -> Java /p/order/confirm 生成后端确认上下文
  -> Java /p/score/scoreInfo 获取会员积分信息（失败不阻断）
  -> H5 渲染订单确认（普通快递不因 confirm.submitOrder=0 置灰）
  -> 用户点击提交订单
  -> H5 客户端生成 orderFlowLogParam（uuid/uuidSession/step/systemType/prevPageId）
  -> H5 BFF /api/bff/order-submit
  -> Java /p/address/addrInfo/{addrId|0} 再解析收货地址
  -> Java /prod/prodInfo 再校验
  -> Java /p/order/confirm
  -> Java /p/order/submit（透传 orderFlowLogParam）
  -> H5 /pay-way
  -> H5 BFF /api/bff/order-pay-info
  -> Java /p/order/getOrderPayInfoByOrderNumber
  -> Java /sys/config/info/getSysPaySwitch
  -> H5 展示收银台金额、倒计时和支付方式
  -> 用户点击确定支付
  -> H5 本地提示“已发起支付”（本期不调用 /p/order/pay）
```
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 否 | 使用旧 Java 商品、地址和普通订单接口。 | `.ai-workspace/contracts/api/h5-product-detail-real-flow-contract.md`、`.ai-workspace/contracts/api/h5-address-module-contract.md` |
| 调整接口 | 否 | H5 新增 BFF，不要求后端改造。 | 同上 |
| 鉴权 | 是 | App/H5 Cookie 中的 `mallToken` 由 BFF 转为 Java `Authorization`。 | 同上 |
| 缓存策略 | 是 | 商品基础信息可短缓存；价格、库存和订单确认不可缓存。 | 同上 |
| 错误码 | 是 | 沿用 Java envelope 和 H5 BFF 错误归一。 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 是 | 地址能力优先通过 `rpc/address.*` 获取和管理；收银台本期不接支付 Bridge，确认付款按钮只做本地提示。 | `.ai-workspace/contracts/native-bridge/meumall-bridge-protocol.md`、`.ai-workspace/contracts/api/h5-address-module-contract.md` |
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
- [x] 普通快递订单提交 BFF 和订单确认页提交状态。
- [x] 自动化测试和构建验证。
- [ ] App WebView 注入真实 `mallToken` 后的端上联调验证。

## 对方责任

### 后端

- [ ] 确认测试环境 `/prod/prodInfo` 支持普通商品快递和 SKU 字段。
- [ ] 确认测试环境 `/p/order/confirm`、`/p/order/submit` 支持旧 uni-app 普通商品快递下单参数。
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
  5. 检查订单确认页重新请求商品接口并校验 SKU、价格、库存，并调用 `/p/order/confirm` 生成确认上下文。
  6. 检查确认成功后调用 `/p/score/scoreInfo`，该接口异常时不阻断提交页。
  7. 点击提交订单，检查 BFF 日志依次出现 `/p/address/addrInfo/{addrId}`、`/prod/prodInfo`、`/p/order/confirm`、`/p/order/submit`，且 `/p/order/submit` 请求体包含完整 `orderFlowLogParam`。
  8. 成功时订单确认页跳转 `/pay-way?orderNumbers=<orderNumbers>&dvyType=1&isPurePoints=0&orderType=0&ordermold=0`。
  9. 收银台检查 BFF 日志出现 `/p/order/getOrderPayInfoByOrderNumber` 和 `/sys/config/info/getSysPaySwitch`。
  10. 点击“确定支付”只展示“已发起支付”，不应出现 `/p/order/pay` 出站请求。

## H5 兜底策略

- 接口失败：展示可恢复错误，不白屏。
- 商品不存在：展示商品不可见状态。
- SKU 缺失：禁用立即购买，提示暂无可购买规格。
- 库存不足：禁用确认或把数量压到库存范围内。
- 普通快递订单确认返回 `submitOrder=0`：对齐旧 uni-app，不作为 H5 置灰或提交拦截条件；最终以 `/p/order/submit` 返回为准。
- 订单提交接口失败：展示错误文案，用户可重试，不进入收银台。
- 收银台支付信息失败：展示错误文案，用户可返回订单列表或稍后重试。
- 确认付款：本期不调用支付接口，只在 H5 本地提示“已发起支付”。
- 用户未登录/token 无效：展示鉴权失败，引导回 App 登录能力；本期不新增登录 Bridge。

## 验收标准

- [x] H5 页面成功状态可用。
- [x] H5 页面 loading、error、empty 状态可用。
- [x] BFF 契约与文档一致。
- [x] 后端旧接口路径和鉴权方式已通过 BFF 契约与测试覆盖；真实成功态仍需有效 `mallToken` 端上联调。
- [x] 订单确认页不信任 URL 价格，必须重新请求商品接口。
- [x] 订单确认和提交页不直接信任 URL 参数，BFF 先用 `/p/address/addrInfo/{addrId|0}` 解析收货地址，再校验 SKU、库存和数量。
- [x] 无法解析收货地址时 H5 禁止提交订单；订单提交 BFF 返回 409，不创建后端订单。
- [x] 创建订单成功后进入 `/pay-way` 并展示订单支付信息；真正确认付款能力不在本期承诺内。
- [x] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 商品详情真实接口迁移需要确认/配合：
1. 后端继续提供 Java /prod/prodInfo、/p/address/* 和普通订单接口，H5 本期只消费普通商品 + 快递 + SKU。
2. 原生 App 确保 WebView H5 域名下有 mallToken Cookie。
3. H5 通过 /api/bff/product-detail、/api/bff/order-confirm 和 /api/bff/order-submit 转发，不让浏览器直接请求 Java 后端。
4. 商品详情、订单确认和地址管理页优先使用 App Bridge `rpc/address.*` 获取/管理地址；Bridge 不可用时回退 H5 BFF。
5. 订单确认/提交前会解析默认或选中收货地址；无地址时 H5 禁止提交。
6. 订单确认页加载阶段也会调用 Java `/p/order/confirm`；普通快递 DTO 已按旧 uni-app 补齐 `dvyTypes[].lat/lng/stationId`、`orderItem`、积分和优惠券默认值；普通快递链路不因确认响应 `submitOrder=0` 在 H5 层置灰或提前拦截。
7. H5 客户端按旧 uni-app 规则持久化 `bbcUuid`、`bbcUuidSession`、`bbcStep`、`bbcSessionTimeStamp` 和 `bbcFlowAnalysisLogDto`，点击提交时生成并透传 `/p/order/submit.orderFlowLogParam`。
8. 本期创建待支付订单后会进入 H5 收银台，收银台只读取 `/p/order/getOrderPayInfoByOrderNumber` 和支付开关展示信息；点击确认付款仅提示“已发起支付”，不调用 `/p/order/pay`。

契约文档：
.ai-workspace/contracts/api/h5-product-detail-real-flow-contract.md

联调方式：
打开 /product/1000054，选择 SKU 后进入 /order-confirm，检查 H5 BFF 日志和页面状态。

验收口径：
商品详情和订单确认都能使用真实商品接口，SKU/库存/价格校验通过；默认/选中地址可被解析；普通快递订单能返回 orderNumbers 并进入收银台；收银台能展示订单金额、倒计时和支付方式；点击确认付款只提示已发起支付；无地址、无 token 或接口失败时 H5 不白屏且不伪造订单。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-11 | 产品/H5 | 已确认 | 使用旧接口，本期只做普通商品、快递、SKU、立即购买和订单确认。 |
| 2026-06-12 | H5 | 已更新 | 根据“不能下订单”反馈补接普通快递订单创建，新增 `/api/bff/order-submit`；支付仍后置。 |
| 2026-06-12 | H5 | 已更新 | 订单确认和提交链路新增地址解析前置：使用 Java `/p/address/addrInfo/{addrId}`，地址缺失时禁止提交。 |
| 2026-06-12 | H5 | 已更新 | 地址管理页新增真实 BFF，接入旧 Java 地址列表、详情、新增、编辑、设默认和删除接口。 |
| 2026-06-24 | H5/App | 已更新 | 地址来源升级为 App Bridge 优先：新增 `rpc/address.*`，商品详情配送行和订单确认默认地址先取 Bridge，BFF 保留兜底和服务端校验。 |
| 2026-06-25 | H5 | 已更新 | 修复订单确认下单链路：确认页加载阶段补调 `/p/order/confirm`，`dvyTypes` 补齐旧 uni-app DTO 的 `lat/lng/stationId`，提交体补 `orderFlowLogParam` 并优先用确认返回的 `shopCartOrders` 生成 `orderShopParams`。 |
| 2026-06-26 | H5 | 已更新 | 对齐旧 uni-app 下单接口顺序和参数：订单确认成功后补调 `/p/score/scoreInfo`；确认体补 `couponParams: []`；`orderFlowLogParam` 改为客户端持久化并透传完整 `uuid/uuidSession/step/systemType/prevPageId`。 |
| 2026-06-26 | H5 | 已修复 | 修复订单确认页提交按钮置灰：普通快递链路不再用 `/p/order/confirm.submitOrder=0` 作为 H5 置灰或提交阻断条件，保持旧 uni-app 行为，最终提交结果以 `/p/order/submit` 为准。 |
| 2026-06-26 | H5 | 已更新 | 新增 `/pay-way` 收银台和 `/api/bff/order-pay-info`，订单创建成功后跳收银台；收银台仅展示支付信息，确认付款按钮本期只提示“已发起支付”，不调用 `/p/order/pay`。 |
