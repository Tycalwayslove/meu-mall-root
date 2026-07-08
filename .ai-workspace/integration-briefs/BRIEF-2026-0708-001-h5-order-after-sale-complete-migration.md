# BRIEF-2026-0708-001 H5 订单与售后完整迁移

## 需求概述

参考旧 uni-app 项目，将订单列表、订单详情、退货退款列表、退款详情、退款申请、平台介入、退货物流等核心流程迁移到当前 `hybird-meumall` Next 项目。页面需要尽量还原旧项目的信息结构和交互逻辑，接口继续沿用 Java 旧接口。

## 本期页面

- `/orders`
- `/orders/[orderNumber]`
- `/orders/logistics/[orderNumber]`
- `/refunds`
- `/refunds/[refundSn]`
- `/refunds/choose-way`
- `/refunds/apply`
- `/refunds/platform-intervention`
- `/refunds/return-logistics`

## 关键流程

```mermaid
flowchart TD
  A["我的页面订单入口"] --> B["订单列表 /orders"]
  B --> C["订单详情 /orders/{orderNumber}"]
  B --> D["继续付款：先查 getOrderPayInfoByOrderNumber"]
  D --> E["未过期进入 /pay-way"]
  C --> F["整单退款或单品退款"]
  F --> G["写入 meumall_refund_context"]
  G --> H{"订单是否待发货"}
  H -- 是 --> I["退款申请 /refunds/apply?type=1"]
  H -- 否 --> J["选择退款方式 /refunds/choose-way"]
  J --> I
  I --> K["提交 /p/orderRefund/apply 或 update_refund"]
  K --> L["售后列表 /refunds 或退款详情 /refunds/{refundSn}"]
  L --> M["撤销/改金额/平台介入/退货物流"]
```

## 接口重点

- 订单列表和详情沿用 `/p/myOrder/*`。
- 物流详情沿用 `/p/myDelivery/*`。
- 售后列表、详情、申请、撤销、修改金额、平台介入、退货物流沿用 `/p/orderRefund/*` 和 `/p/orderRefundIntervention/*`。
- Java 请求头 `source` 继续传 `1`。

## 联调风险

- 售后图片上传旧项目依赖 `util.saveAttachFileToPlat`，当前 H5 本期先接收已上传 URL 或图片路径文本，不在本期实现原生文件上传链路。
- 自提、虚拟商品、积分、拼团、秒杀、发票、评价、IM 不作为本期完整业务迁移目标，仅做入口降级。
- 部分售后字段依赖后端返回完整对象，H5 mapper 需保留 `modules.raw` 便于调试。
