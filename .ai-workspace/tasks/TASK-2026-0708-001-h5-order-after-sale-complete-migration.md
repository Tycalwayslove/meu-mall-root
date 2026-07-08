# TASK-2026-0708-001 H5 订单与售后完整迁移

## 状态

ready

## 背景

当前 H5 已有订单列表、订单详情、退货退款列表、退款详情首期实现，但首期只覆盖普通查询与少量订单操作。用户反馈新项目中订单列表、订单详情、售后退款逻辑仍未完整完成，需要参考旧 uni-app 项目，将主要页面和真实接口逻辑迁移到 Next 技术栈，并尽量高保真还原旧页面信息结构。

旧项目参考目录：

- `/Users/mac/company_code/mall4uni-bbc/src/package-user/pages/order-list/order-list.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-user/pages/order-detail/order-detail.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-user/pages/logistics-info/logistics-info.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-user/pages/write-return-logistics/write-return-logistics.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/after-sales/after-sales.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/details-of-refund/details-of-refund.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/choose-refund-way/choose-refund-way.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/apply-refund/apply-refund.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-refund/pages/plat-intervene/plat-intervene.vue`

## 目标

1. 订单列表迁移旧项目的分页、搜索、状态标签、退款状态、售后标签、物流摘要和订单操作按钮。
2. 订单详情迁移旧项目的状态头、物流/地址、商品明细、费用明细、订单信息、整单退款/单品退款/查看退款入口。
3. 售后列表和售后详情迁移旧项目的申请类型、平台介入状态、退款状态流转、凭证、物流和底部操作。
4. 新增退款申请、选择退款方式、平台介入/补充凭证、填写/修改退货物流页面。
5. 所有 Java 请求保持 `source: 1` 请求头，由现有 backend client 统一注入。

## 范围

本期实现：

- `/orders`
- `/orders/[orderNumber]`
- `/orders/logistics/[orderNumber]`
- `/refunds`
- `/refunds/[refundSn]`
- `/refunds/choose-way`
- `/refunds/apply`
- `/refunds/platform-intervention`
- `/refunds/return-logistics`
- 对应 BFF：订单、物流、售后查询和售后动作接口。

降级处理：

- 发票、评价、拼团详情、店铺首页、IM 聊天：保留入口或提示，暂不迁移完整专属业务页。
- 自提、虚拟商品专属详情：仍沿用现有 H5 能力边界，不在本期强行恢复旧 uni 专属页。

## 验收

- 订单列表可加载多页，切换全部/待付款/待发货/待收货/已完成时状态正确。
- 待付款订单点击继续付款前先调用 `/p/order/getOrderPayInfoByOrderNumber` 校验未过期，再进入 H5 收银台。
- 订单详情可对可售后商品发起整单退款或单品退款，退款上下文来自当前订单详情并写入 H5 `sessionStorage`。
- 退款申请提交时按旧项目参数调用 `/p/orderRefund/apply` 或 `/p/orderRefund/update_refund`。
- 退款详情可撤销退款、撤销平台介入、修改退款金额、跳转填写/修改退货物流。
- 平台介入页面按旧项目参数调用 `/p/orderRefund/apply_platform_intervention` 或 `/p/orderRefundIntervention/saveInterventionVoucher`。
- 退货物流页面按旧项目参数调用 `/p/orderRefund/submitExpress` 或 `/p/orderRefund/reSubmitExpress`。
- `npm run typecheck` 通过。

## 关联文档

- `.ai-workspace/contracts/api/h5-order-after-sale-complete-migration-contract.md`
- `.ai-workspace/integration-briefs/BRIEF-2026-0708-001-h5-order-after-sale-complete-migration.md`
- `hybird-meumall/docs/11_ORDER_AFTER_SALE_COMPLETE_MIGRATION_PLAN.md`
