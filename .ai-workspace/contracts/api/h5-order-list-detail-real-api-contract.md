# API 契约：H5 订单列表、退货退款和订单详情

## 基本信息

- 契约编号：API-2026-0627-004
- 状态：implemented，待 App token 联调验证
- 提供方：Java 后端
- 消费方：`hybird-meumall`
- 来源：旧 uni-app 订单列表、订单详情和售后退款页面
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-004-h5-order-list-detail-real-api.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0627-004-h5-order-list-detail-real-api.md`

## 通用约定

- H5 浏览器端只调用 H5 BFF，不直接请求 Java。
- H5 BFF 请求 Java 时使用 `mallToken` 作为 `Authorization`。
- H5 BFF 请求 Java 时注入 `source: 1`，表示 App 来源。
- 私有交易数据默认 `no-store`。
- 接口失败、鉴权失败、空数组不回退本地 mock。

## H5 状态枚举

| H5 status | 展示 | Java 来源 |
| --- | --- | --- |
| `all` | 全部 | `/p/myOrder/myOrder status=0` |
| `pending-payment` | 待付款 | `/p/myOrder/myOrder status=1` |
| `pending-shipment` | 待发货 | `/p/myOrder/myOrder status=2` |
| `pending-receipt` | 待收货 | `/p/myOrder/myOrder status=3` |
| `completed` | 已完成 | `/p/myOrder/myOrder status=5` |

退货退款不是普通订单 `status`，页面路由为 `/refunds`，请求 `/api/bff/orders/refunds` -> Java `/p/orderRefund/list`。

## BFF 响应结构

当前统一为：

```ts
type OrderBffResponse<TView, TModules> = {
  view: TView;
  modules: TModules;
  debugRaw?: unknown;
};
```

`view` 只放页面需要的规整字段，`modules` 保留 Java 原始模块或半规整字段，`debugRaw` 仅 local/test 且 `debugRaw=1` 时返回。

## 普通订单列表

- H5 BFF：`GET /api/bff/orders`
- Java：`GET /p/myOrder/myOrder`
- 鉴权：需要 `mallToken`

### H5 query

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `status` | string | 否 | `all/pending-payment/pending-shipment/pending-receipt/completed`，默认 `all` |
| `keyword` | string | 否 | 商品名称搜索，映射 Java `prodName` |
| `current` | number | 否 | 页码，默认 `1` |
| `size` | number | 否 | 页大小，默认 `10` |
| `debugRaw` | `1` | 否 | local/test 返回原始数据 |

### Java query

| 参数 | 类型 | 来源 |
| --- | --- | --- |
| `current` | number | H5 `current` |
| `size` | number | H5 `size` |
| `status` | number | H5 status 映射：`all=0`、`pending-payment=1`、`pending-shipment=2`、`pending-receipt=3`、`completed=5` |
| `prodName` | string | H5 `keyword`，空字符串可不传或传空 |

### 关键 Java 字段

| 字段 | 说明 | H5 用途 |
| --- | --- | --- |
| `orderNumber` | 订单号 | 详情、操作、支付跳转 |
| `shopId/shopName` | 店铺 | 卡片标题；店铺跳转首期后置 |
| `status` | 订单状态 | 状态文案和按钮 |
| `orderType` | 订单类型 | 支付跳转和拼团分支 |
| `orderMold` | 订单模型 | 虚拟订单分支 |
| `dvyType` | 配送类型 | 普通快递/自提分支 |
| `actualTotal/userScore/total/transfee` | 金额/积分 | 汇总展示 |
| `returnMoneySts/refundStatus` | 退款状态 | 退款状态附加文案 |
| `deliveryCount/productNums/deliveryDto` | 发货/物流 | 部分发货、查看物流 |
| `orderItemDtos` | 商品项 | 商品行、评价和退款入口 |
| `orderInvoiceId` | 发票 | 发票按钮后置 |
| `afterSaleTel` | 售后电话 | 联系商家拨号兜底，H5 首期留言为主 |

## 退货退款列表

- H5 BFF：`GET /api/bff/orders/refunds`
- Java：`GET /p/orderRefund/list`
- 鉴权：需要 `mallToken`

### H5 query

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `current` | number | 否 | 页码，默认 `1` |
| `size` | number | 否 | 页大小，默认 `10` |
| `startTime` | string | 否 | 旧项目保留筛选，首期为空 |
| `endTime` | string | 否 | 旧项目保留筛选，首期为空 |

### Java query

| 参数 | 类型 | 来源 |
| --- | --- | --- |
| `current` | number | H5 `current` |
| `size` | number | H5 `size` |
| `startTime` | string | H5 `startTime`，首期空字符串 |
| `endTime` | string | H5 `endTime`，首期空字符串 |

## 普通订单详情

- H5 BFF：`GET /api/bff/orders/detail?orderNumber=<orderNumber>`
- Java 主数据：`GET /p/myOrder/orderDetail`
- Java 物流摘要：`GET /p/myDelivery/orderInfo/{orderNumber}`
- 鉴权：需要 `mallToken`

### Java 主数据参数

| 参数 | 类型 | 来源 |
| --- | --- | --- |
| `orderNumber` | string | H5 URL |

### 详情分支

| 条件 | 旧项目行为 | H5 首期 |
| --- | --- | --- |
| `orderMold === 1` | 跳虚拟/核销详情 | 暂不迁移，展示后置提示 |
| `dvyType === 2` | 跳自提订单详情 | 暂不迁移，展示后置提示 |
| 普通快递 | 展示订单详情 | 首期迁移 |

### 关键 Java 字段

| 字段 | 说明 |
| --- | --- |
| `status` | 订单状态：1 待付款、2 待发货、3 待收货、4 待评价、5 已完成、6 已取消、7 拼团中 |
| `userAddrDto` | 收货人、电话、省市区、详细地址 |
| `orderItemDtos` | 商品明细、退款单号、售后类型、赠品/套餐 |
| `actualTotal/orderScore/total/transfee/freeTransfee` | 实付、积分、商品总额、运费、运费减免 |
| `platformCouponAmount/scoreAmount/memberAmount/shopCouponMoney` | 优惠明细 |
| `createTime/payTime/dvyTime/finallyTime/cancelTime` | 订单时间线 |
| `canRefund/canAllRefund/canRefundAmount` | 退款入口判断 |
| `orderInvoiceId` | 发票状态 |
| `virtualRemark` | 虚拟商品留言，首期不覆盖 |

## 订单动作

### 取消订单

- H5 BFF：`PUT /api/bff/orders/cancel`
- Java：`PUT /p/myOrder/cancel/{orderNumber}`

```ts
type CancelOrderRequest = {
  orderNumber: string;
};
```

### 继续付款

- 已有 H5 BFF：`GET /api/bff/order-pay-info?orderNumbers=<orderNumber>&orderType=<orderType>&dvyType=<dvyType>`
- Java：`GET /p/order/getOrderPayInfoByOrderNumber?orderNumbers=<orderNumber>`
- H5 行为：若 `endTime` 未过期，跳 `/pay-way?orderNumbers=...&orderType=...&dvyType=...&isPurePoints=0&ordermold=0`；否则提示订单已过期。

### 确认收货

- H5 BFF：`PUT /api/bff/orders/receipt`
- Java：`PUT /p/myOrder/receipt/{orderNumber}`

```ts
type ReceiptOrderRequest = {
  orderNumber: string;
};
```

### 删除订单

- H5 BFF：`DELETE /api/bff/orders/delete?orderNumber=<orderNumber>`
- Java：`DELETE /p/myOrder/{orderNumber}`

### 联系商家留言

- H5 BFF：`POST /api/bff/orders/contact-message`
- Java：`POST /p/myOrder/submitMessage`

```ts
type ContactMessageRequest = {
  orderNumber: string;
  userMobile: string;
  messageContent: string;
};
```

校验建议与旧项目一致：

- `messageContent` 必填且长度至少 6。
- `userMobile` 必填，并支持手机号、座机、400/800、国际区号号码。

## 退款详情

- H5 BFF：`GET /api/bff/orders/refund-detail?refundSn=<refundSn>`
- Java：`GET /p/orderRefund/info`

| Java 参数 | 类型 | 来源 |
| --- | --- | --- |
| `refundSn` | string | 退款详情 URL |

首期展示退款详情、退款商品、退款金额、退款状态、凭证和卖家处理信息。撤销退款、平台介入、修改退款金额、填写物流信息可拆后续任务。

## 退款申请接口（后续）

旧项目退款申请依赖从订单详情写入本地缓存的 `bbcRefundItem`，H5 不建议照搬本地缓存，应改为 URL 参数 + BFF 重新查询订单详情生成申请上下文。

| Java 接口 | 方法 | 说明 |
| --- | --- | --- |
| `/p/orderRefund/apply` | POST | 新增退款申请 |
| `/p/orderRefund/update_refund` | PUT | 修改退款申请 |
| `/p/orderRefund/cancel` | PUT | 撤销退款申请 |
| `/p/orderRefund/cancel_platform_intervention` | PUT | 撤销平台介入 |
| `/p/orderRefund/updateRefundAmount` | PUT | 修改退款金额 |

## 按钮显示规则摘要

| 条件 | 按钮 |
| --- | --- |
| `status === 1` | 取消订单、继续付款、联系商家 |
| `status === 3 && refundStatus !== 1` | 确认收货 |
| `(status === 3 || status === 5) && (dvyType === 1 || dvyType === 0)` | 查看物流 |
| `status === 5` 且存在未评价且未退款成功商品 | 评价，后置 |
| `status === 5 || status === 6` 且退款已完成/关闭/无退款 | 删除订单 |
| 有 `orderInvoiceId` 且符合旧条件 | 查看发票，后置 |
| 无 `orderInvoiceId` 且符合旧条件 | 申请开票，后置 |
| 任意订单 | 联系商家 |

## 退款状态文案摘要

| 字段组合 | 文案 |
| --- | --- |
| `refundStatus === 1` | 退款中 |
| `returnMoneySts === 5 && refundStatus !== 3` | 退款完成 |
| `returnMoneySts === 5 && refundStatus === 3` | 部分退款完成 |
| `returnMoneySts === -1` | 退款关闭 |
| `status <= 2 && deliveryCount && productNums > deliveryCount` | 部分发货 |

实现时以旧项目条件顺序为准，避免重复展示或覆盖。

## 测试建议

- [x] 状态映射单元测试。
- [x] 普通订单列表 mapper 测试：商品数量合计、退款状态、按钮列表。
- [x] 退款列表 mapper 测试。
- [x] 订单详情 mapper 测试：普通快递、物流摘要、费用明细。
- [x] BFF 参数测试：`current/size/status/prodName`、`refundSn`、`orderNumber`。
- [x] 操作动作测试：取消、确认收货、删除、留言请求体。
- [ ] App WebView 真实 `mallToken` 联调测试。

## 实施记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-27 | implemented | H5 已新增 `/orders` 真实订单列表、`/orders/[orderNumber]` 普通订单详情、独立 `/refunds` 退货退款列表、`/refunds/[refundSn]` 退款详情，以及订单列表/详情/操作/退款详情 BFF；旧 `/orders/refunds/[refundSn]` 仅兼容重定向；待 App WebView 注入真实 token 后联调。 |
