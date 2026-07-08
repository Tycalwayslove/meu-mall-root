# H5 订单与售后完整迁移接口契约

## 通用

- H5 通过 BFF 调 Java。
- Java 请求必须携带 `source: 1` 请求头，表示 App 来源。当前由 `hybird-meumall/src/server/http/backend-client.ts` 统一注入。
- 鉴权使用 App 传入的 Java token，BFF 通过 `createBffRequestContext(request).getAuthToken("java")` 读取。

## 订单

### 订单列表

- H5 BFF：`GET /api/bff/orders`
- Java：`GET /p/myOrder/myOrder`
- 参数：
  - `current`：页码，来自页面分页状态。
  - `size`：每页数量，H5 默认 `10`。
  - `status`：订单状态，H5 映射为 Java 状态：全部 `0`、待付款 `1`、待发货 `2`、待收货 `3`、已完成 `5`。
  - `prodName`：搜索商品名，来自页面搜索框。

### 订单详情

- H5 BFF：`GET /api/bff/orders/detail`
- Java：
  - `GET /p/myOrder/orderDetail?orderNumber=...`
  - `GET /p/myDelivery/orderInfo/{orderNumber}`
- 参数：
  - `orderNumber`：订单号，来自路由。
- 用途：
  - 渲染订单状态、地址、商品、费用、订单信息。
  - 构造退款上下文。
  - 渲染物流摘要。

### 订单操作

- 取消订单：`PUT /p/myOrder/cancel/{orderNumber}`
- 确认收货：`PUT /p/myOrder/receipt/{orderNumber}`
- 删除订单：`DELETE /p/myOrder/{orderNumber}`
- 商家留言：`POST /p/myOrder/submitMessage`
  - `orderNumber`
  - `messageContent`
  - `userMobile`
- 继续付款前校验：`GET /p/order/getOrderPayInfoByOrderNumber`
  - `orderNumbers`
  - 返回 `endTime`，H5 判断未过期后进入 `/pay-way`。

## 物流

### 订单物流详情

- H5 BFF：`GET /api/bff/orders/logistics`
- Java：
  - `GET /p/myDelivery/orderInfo/{orderNumber}`
  - `GET /p/myOrder/orderDetail?orderNumber=...`
  - 切换包裹时：`GET /p/myDelivery/deliveryOrder/{orderDeliveryId}`
- 参数：
  - `orderNumber`：订单号。
  - `orderDeliveryId`：包裹 ID，切换包裹时使用。

## 售后

### 售后列表

- H5 BFF：`GET /api/bff/orders/refunds`
- Java：`GET /p/orderRefund/list`
- 参数：
  - `current`
  - `size`
  - `startTime`：当前默认空字符串。
  - `endTime`：当前默认空字符串。

### 售后详情

- H5 BFF：`GET /api/bff/orders/refund-detail`
- Java：`GET /p/orderRefund/info`
- 参数：
  - `refundSn`：退款编号。
- 用途：
  - 渲染退款状态流转、平台介入、退款商品、买家原因/说明、凭证、退货地址、退货物流。

### 退款申请

- H5 BFF：`POST /api/bff/orders/refund-apply`
- Java：
  - 新申请：`POST /p/orderRefund/apply`
  - 修改申请：`PUT /p/orderRefund/update_refund`
- 参数：
  - `refundId`：修改申请时传。
  - `orderId`
  - `orderNumber`
  - `applyType`：`1` 仅退款，`2` 退货退款。
  - `isReceiver`：`0` 未收到货，`1` 已收到货。
  - `buyerReason`
  - `goodsNum`
  - `refundAmount`
  - `buyerMobile`
  - `buyerDesc`
  - `photoFiles`
  - `refundType`：`1` 整单退款，`2` 单品退款。
  - `orderItemId`：单品退款时传。
  - `giveawayItemIds`

### 售后动作

- 撤销退款申请：`PUT /p/orderRefund/cancel`
  - body：`refundSn` 字符串。
- 修改退款金额：`PUT /p/orderRefund/updateRefundAmount`
  - `refundSn`
  - `refundAmount`
- 撤销平台介入：`PUT /p/orderRefund/cancel_platform_intervention`
  - `refundSn`
  - `refundId`
  - `orderNumber`
- 申请平台介入：`PUT /p/orderRefund/apply_platform_intervention`
  - `refundId`
  - `orderNumber`
  - `sysType: 0`
  - `refundSts`
  - `voucherDesc`
  - `imgUrls`
- 补充平台凭证：`POST /p/orderRefundIntervention/saveInterventionVoucher`
  - 参数同申请平台介入。

### 退货物流

- 物流公司列表：`GET /p/delivery/list`
- 填写退货物流：`POST /p/orderRefund/submitExpress`
- 修改退货物流：`PUT /p/orderRefund/reSubmitExpress`
- 参数：
  - `expressId`
  - `expressName`
  - `expressNo`
  - `imgs`
  - `mobile`
  - `refundSn`
  - `senderRemarks`

## H5 本地上下文

旧 uni-app 通过 `bbcRefundItem` 本地缓存将订单详情页生成的退款上下文传给退款申请页。Next 迁移后使用 `sessionStorage`：

- key：`meumall_refund_context`
- 写入方：订单详情页、退款详情页“修改申请”入口。
- 读取方：选择退款方式页、退款申请页。
- 内容：当前订单号、退款类型、申请方式、订单状态、商品项、费用字段、可退金额、买家手机号、修改申请的 `refundId/refundSn/orderId`。
