# TASK-2026-0627-004-h5-order-list-detail-real-api

## 状态

implemented，待 App token 联调验证

## 目标

将旧 uni-app 项目的订单列表、退货退款列表、普通快递订单详情和订单操作迁移到 `hybird-meumall`，让我的页订单入口从本地 mock 升级为真实 Java 接口链路。

## 背景

当前 H5 我的页已包含订单入口。用户要求迁移旧项目“全部订单 / 待付款 / 待发货 / 待收货 / 已完成 / 退货退款”以及对应详情页面，并先梳理接口、传参和逻辑流程，形成文档后再实施。

旧项目关键来源：

- `/Users/mac/company_code/mall4uni-bbc/src/package-user/pages/order-list/order-list.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-user/pages/order-detail/order-detail.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/after-sales/after-sales.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/details-of-refund/details-of-refund.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/apply-refund/apply-refund.vue`

## 涉及项目

- `hybird-meumall`
- `.ai-workspace`

## 范围

包含：

- `/orders` 从 mock 迁移为真实订单列表。
- 我的页订单入口状态映射：
  - 全部订单：`/orders?status=all` -> Java `status=0`
  - 待付款：`/orders?status=pending-payment` -> Java `status=1`
  - 待发货：`/orders?status=pending-shipment` -> Java `status=2`
  - 待收货：`/orders?status=pending-receipt` -> Java `status=3`
  - 已完成：`/orders?status=completed` -> Java `status=5`
  - 退货退款：`/refunds` -> Java `/p/orderRefund/list`
- 新增普通快递订单详情页，建议路由 `/orders/[orderNumber]`。
- 新增售后退款详情页，路由 `/refunds/[refundSn]`，作为退货退款列表详情承接页；旧 `/orders/refunds/[refundSn]` 仅保留兼容重定向。
- 迁移普通订单列表的搜索、分页、状态展示、退款状态展示、售后标签、商品行、金额汇总和按钮逻辑。
- 迁移普通快递订单详情的状态头、物流摘要、收货地址、商品、费用明细、订单信息和底部按钮逻辑。
- 迁移首批可操作动作：取消订单、继续付款、确认收货、删除订单、查看物流、联系商家留言。
- 继续支付复用已存在 `/pay-way` 和 `/api/bff/order-pay-info`。
- 所有 Java 请求继续由 H5 BFF 发起，继承 `mallToken` 鉴权和 `source: 1` header。

不包含：

- 不迁移自提订单详情页、虚拟商品核销页、秒杀/拼团专属详情。
- 不迁移真实支付确认 `/p/order/pay`。
- 不迁移发票申请/发票详情页面，仅保留按钮后置。
- 不迁移评价发布页，仅保留按钮后置。
- 不迁移完整退款申请表单首期提交；首期可以展示退款入口和退款详情，退款申请流程可拆后续任务。
- 不迁移店铺主页跳转；联系商家优先保留留言弹窗或后续 IM。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-order-list-detail-real-api-contract.md`
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0627-004-h5-order-list-detail-real-api.md`
- H5 项目实施文档：`hybird-meumall/docs/10_ORDER_LIST_DETAIL_MIGRATION_PLAN.md`
- 是否向后兼容：新增 H5 BFF 和页面路由，不改变现有商品详情、订单确认、收银台接口。
- 是否需要灰度：建议随 H5 candidate 发布，在 App WebView 内用真实 `mallToken` 验证后再切 active。

## 已新增 BFF

| BFF | 方法 | 用途 | Java 依赖 |
| --- | --- | --- | --- |
| `/api/bff/orders` | GET | 普通订单列表 | `/p/myOrder/myOrder` |
| `/api/bff/orders/refunds` | GET | 退货退款列表 | `/p/orderRefund/list` |
| `/api/bff/orders/detail` | GET | 普通订单详情 | `/p/myOrder/orderDetail`、`/p/myDelivery/orderInfo/{orderNumber}` |
| `/api/bff/orders/cancel` | PUT | 取消订单 | `/p/myOrder/cancel/{orderNumber}` |
| `/api/bff/orders/receipt` | PUT | 确认收货 | `/p/myOrder/receipt/{orderNumber}` |
| `/api/bff/orders/delete` | DELETE | 删除订单 | `/p/myOrder/{orderNumber}` |
| `/api/bff/orders/contact-message` | POST | 联系商家留言 | `/p/myOrder/submitMessage` |
| `/api/bff/orders/refund-detail` | GET | 退款详情 | `/p/orderRefund/info` |

## 验收标准

- [x] `/orders` 首屏不再渲染本地 mock 订单；真实接口成功后展示 Java 返回订单。
- [x] 全部、待付款、待发货、待收货、已完成状态切换参数与旧 uni-app `sts` 一致。
- [x] 退货退款入口请求 `/p/orderRefund/list`，不错误映射为 `/p/myOrder/myOrder status=refund`。
- [x] 列表搜索传 `prodName`，分页传 `current/size`。
- [x] 普通订单详情请求 `/p/myOrder/orderDetail?orderNumber=...`，普通快递物流摘要请求 `/p/myDelivery/orderInfo/{orderNumber}`。
- [x] 待付款订单“继续付款”先请求 `/p/order/getOrderPayInfoByOrderNumber` 校验未过期，再跳 `/pay-way`。
- [x] 取消订单、确认收货、删除订单、联系商家留言参数与旧项目一致。
- [x] 接口失败、token 缺失、空列表均展示 H5 业务态，不回退 mock。
- [x] 自提、虚拟、拼团等非本期订单类型有明确后置提示或兼容跳转，不误渲染普通快递详情。
- [x] 补充 mapper/unit tests，覆盖状态映射、按钮映射、退款状态文案和 BFF 参数。
- [ ] 使用 App WebView 注入的真实 `mallToken` 完成列表、详情和订单操作联调。

## 验证命令

实施阶段建议：

```bash
cd hybird-meumall
pnpm exec vitest run src/features/mine-secondary/orders-*.test.ts src/features/mine-secondary/order-detail-*.test.ts
pnpm typecheck
```

## 风险和阻塞

- 退货退款是独立售后列表，不是普通订单 `status` 枚举；实现时必须拆 BFF。
- 旧项目自提、虚拟、拼团订单会进入专属详情页，本任务首期只覆盖普通快递订单。
- 发票、评价、退款申请、IM/店铺主页属于长尾动作，首期按钮需要后置或降级。
- 订单状态、退款状态、平台介入状态字段较多，必须以旧项目 mapper 为准，不要在 UI 中重新猜状态。
- 需在真实 App WebView 中验证 `mallToken`、`source: 1`、分页、操作按钮和支付跳转。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-27 | draft | 已从旧 uni-app 梳理订单列表、订单详情、退货退款列表和退款详情接口，待确认后进入实施。 |
| 2026-06-27 | implemented | 已新增订单列表、退货退款列表、普通订单详情、退款详情和订单操作 BFF/页面；待 App WebView 真实 token 联调验证。 |
