# 对接说明：H5 收银台真实支付链路

## 基本信息

- 编号：BRIEF-2026-0629-006
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0629-006-h5-payment-real-flow.md`
- 状态：in_progress
- H5 负责人：H5
- 后端负责人：Java 交易后端
- 原生 App 负责人：iOS / Android
- 管理后台负责人：无
- 目标联调时间：2026-06-29 起
- 目标上线环境：test -> prod 灰度

## 需求背景

H5 商品详情和订单确认已能创建待支付订单。测试环境已启用通联 `paySettlementType=1`，收银台需要同时支持普通 App 支付契约、通联支付宝 URL 支付和通联微信小程序收银台。

## H5 侧目标

用户在 `/pay-way` 选择支付宝或微信后，H5 调 BFF 申请支付参数，再通过 Native Bridge 交给 App 调 SDK、打开通联外部 URL 或拉起通联微信小程序收银台。订单确认进入收银台、收银台进入支付结果页均使用 `replace`，确保 App 返回或手势返回时跳过中间页；支付结果页按订单号回查最终支付状态。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 收银台 | `/pay-way` | H5 | 展示金额、倒计时、支付方式并发起支付。 |
| 支付结果 | `/pay-result` | H5 | 自动按订单号查询是否已支付，支持手动查看支付状态和查看订单。 |

## 数据流

```text
用户点击确定支付
-> H5 /api/bff/order-pay
-> Java /p/order/pay
-> 普通支付 Native SDK / 通联支付宝 URL / 通联微信小程序收银台
-> H5 replace 到 /pay-result
-> H5 回查 /api/bff/order-is-paid?payEntry=0&orderNumbers=<orderNumbers>
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 否 | 复用旧 Java 接口，H5 新增 BFF 包装。 | `.ai-workspace/contracts/api/h5-payment-real-flow-contract.md` |
| 调整接口 | 否 | 通联微信使用 `/p/order/pay` 返回的 `chnlFrontParamInfo` 小程序支付字段，H5 解析后连同完整 `data` 传给 App。 | 同上 |
| 鉴权 | 是 | H5 BFF 从 Cookie 读取 `mallToken`，Java 请求头 `source: 1`。 | 同上 |
| 缓存策略 | 否 | 支付状态和发起支付不缓存。 | 同上 |
| 错误码 | 是 | BFF 归一化 Java 业务错误。 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 是 | 新增 `paymentStartAlipay`、`paymentStartWechat` RPC；旧 `paymentStartCashier` 保留 fallback；`payment.openUrl` 保留历史 URL 打开能力。 | `.ai-workspace/contracts/native-bridge/h5-payment-bridge-contract.md` |
| 原生页面跳转 | 否 | 只需 SDK、通联小程序收银台或通联支付宝 URL，不打开独立原生页面。 | 同上 |
| 登录态 | 否 | 支付接口仍由 H5 BFF 使用 `mallToken`。 | 同上 |
| 最低 App 版本 | 是 | 需 App 方给出支持支付 Bridge 的版本。 | 同上 |
| fallback | 是 | Bridge 不可用时 H5 禁止伪造成功，展示升级/重试提示。 | 同上 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 否 | 支付开关来自 Java `/sys/config/info/getSysPaySwitch`。 | 无 |
| 素材管理 | 否 | 无新增素材。 | 无 |
| 上下线开关 | 否 | 无新增后台配置。 | 无 |
| 排序规则 | 否 | 支付方式按开关顺序展示。 | 无 |
| 灰度规则 | 否 | 跟随 H5/App 发布灰度。 | 无 |

## H5 侧责任

- [x] 页面结构和状态。
- [x] API client 和 Bridge adapter 调用。
- [x] loading、error、处理中、失败状态。
- [x] Mock 数据仅用于单测。
- [ ] 联调验证。

## 对方责任

### 后端

- [ ] 确认 `/p/order/pay` 在 `paySettlementType=1 + payType=7` 的返回包含 `bizOrderNo` 和 `miniprogramPayInfo_VSP`。
- [ ] 确认 `/p/allinpay/order/getAliAppPayUrl` 参数 `json/schemeUrl/page` 和返回 URL。
- [ ] 保持 `/p/order/pay` 在 `paySettlementType=1 + payType=8` 且受理成功时返回 `result=0` 和 `chnlFrontParamInfo`；H5 会解析 `chnlFrontParamInfo` 并透传给 App 直开通联小程序收银台。
- [ ] 确认 `/p/order/isPay/{payEntry}/{orderNumbers}` 返回 `data=true/false`，H5 固定传 `payEntry=0`。

### 原生 App

- [ ] 实现 `rpc/paymentStartAlipay`：普通支付宝调支付宝 SDK；通联支付宝在 `paymentMode=allinpay-url` 时使用 `paymentUrl` 打开通联支付 URL。
- [ ] 实现 `rpc/paymentStartWechat`：普通微信调微信 SDK；通联微信在 `provider=allinpay`、`paymentMode=allinpay-mini-program-bridge` 时按完整 `sdkPayload/chnlFrontParamInfo` 直接打开通联小程序收银台。
- [ ] 保留旧 `rpc/paymentStartCashier` 一个版本周期作为 H5 fallback。
- [ ] 返回清晰状态，不直接决定订单成功，H5 会回查。

### 管理后台

- [x] 无。

## Mock 和联调方式

- Mock 数据位置：H5 Vitest fake backend；App debug receiver。
- Mock 使用阶段：仅限单测和 App Bridge handler 未替换前。
- 测试接口环境：`https://test.aigcpop.com/mini_h5`。
- App 测试包版本：待定。
- 联调阶段是否已移除页面 mock 兜底：是，支付页面不使用 mock 业务数据兜底。

## H5 兜底策略

- Bridge 不可用：展示“当前 App 版本暂不支持支付”，不调用外部 fake 成功。
- `/p/order/pay` 失败：保留在收银台，展示后端错误并允许重试。
- 通联外部 URL 打开后状态未知：进入处理中或提示用户返回后刷新。
- 通联微信小程序支付桥打开后状态未知：App 返回 `unknown`，H5 携带 `bizOrderNo` 进入支付结果页并回查。
- 回查订单仍待支付：展示处理中或失败，不伪造成功。

## 验收标准

- [ ] H5 页面成功状态可用。
- [ ] H5 页面 loading、error、处理中状态可用。
- [ ] API/Bridge 契约与文档一致。
- [ ] 对方交付事项已确认或风险已记录。
- [ ] 联调环境验证通过。
- [ ] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 需求需要 App 接入两个 Bridge：
1. rpc/paymentStartAlipay：普通支付宝调支付宝 SDK；通联支付宝支付在 `paymentMode=allinpay-url` 时使用 `paymentUrl` 打开通联支付 URL，`sdkPayload` 固定透传 `/p/order/pay` 完整 `data`。
2. rpc/paymentStartWechat：普通微信调微信 SDK；通联微信支付在 `provider=allinpay`、`paymentMode=allinpay-mini-program-bridge` 时按完整 `sdkPayload/chnlFrontParamInfo` 直接打开通联小程序收银台。
3. rpc/paymentStartCashier：旧 App fallback，新 App 不应再作为主入口。

契约文档：
- .ai-workspace/contracts/api/h5-payment-real-flow-contract.md
- .ai-workspace/contracts/native-bridge/h5-payment-bridge-contract.md
- .ai-workspace/integration-briefs/BRIEF-2026-0630-002-h5-allinpay-wechat-native-bridge.md

联调方式：
创建待支付订单进入 /pay-way，点击支付宝/微信，H5 发起 BFF 支付申请。支付宝通联分支通过 paymentStartAlipay 传 `paymentUrl + sdkPayload` 给 App；微信通联分支通过 paymentStartWechat 传 `sdkPayload/chnlFrontParamInfo` 给 App 直开通联小程序收银台；H5 发起后立即 replace 到 /pay-result，并通过 /api/bff/order-is-paid 查询最终状态。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-29 | 业务/H5 | 已确认 | 先跑通普通 App 支付；测试环境通联为主链路。 |
| 2026-06-29 | H5/文档 | 已同步 | 飞书页面清单 revision 40；H5 与原生 App 对接说明 revision 89；H5 BFF/API 对接说明 revision 11。 |
| 2026-06-30 | H5/文档 | 已同步 | 明确通联微信通过 `payment.pay` 的 `paymentMode=wechat-mini-program` 交给 App 使用微信 OpenSDK 打开小程序收银台；飞书原生对接说明 revision 90，BFF/API 对接说明 revision 13，页面清单 revision 42。 |
| 2026-06-30 | H5/文档 | 已同步 | 按原生联调要求明确 `payment.pay.sdkPayload` 透传 `/p/order/pay` 完整 `data`；飞书原生对接说明 revision 93，BFF/API 对接说明 revision 14，页面清单 revision 43。 |
| 2026-07-01 | H5/文档 | 已同步 | 按真实返回结构补充 `result=0 + chnlFrontParamInfo` 解析传参；飞书原生对接说明 revision 99，BFF/API 对接说明 revision 15，页面清单 revision 44。 |
| 2026-07-01 | H5/文档 | 已同步 | 支付 RPC action 从 `payment.pay` 改为无点命名 `paymentStartCashier`；通联微信链路修正为 App 打开喵呜小程序支付桥页，桥页再打开通联收银台；飞书原生对接说明 revision 119，BFF/API 对接说明 revision 16，页面清单 revision 45。 |
| 2026-07-02 | H5/文档 | 已同步 | 订单确认到收银台、收银台到支付结果页改为 `replace`；通联微信发起 Bridge 后 H5 立即进入支付结果页；新增 `/api/bff/order-is-paid` 对接 Java `/p/order/isPay/{payEntry}/{orderNumbers}`，支付结果页固定 `payEntry=0` 按订单号查询并展示“查看支付状态 / 查看订单”；飞书原生对接说明 revision 123，BFF/API 对接说明 revision 27，页面清单 revision 67。 |
| 2026-07-03 | H5/文档 | 已同步 | 支付 Bridge 按渠道拆分为 `paymentStartAlipay/paymentStartWechat`；旧 `paymentStartCashier` 保留 fallback；通联支付宝改为 `paymentStartAlipay` 透传完整 `sdkPayload` 并携带 `paymentUrl`；飞书原生对接说明 revision 132，BFF/API 对接说明 revision 28，页面清单 revision 68。 |
