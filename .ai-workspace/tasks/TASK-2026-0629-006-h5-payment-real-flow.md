# TASK-2026-0629-006-h5-payment-real-flow

## 状态

implemented

## 目标

将 H5 收银台从“仅展示支付信息”升级为真实支付发起链路：普通 App 内支付宝/微信支付走 Native Bridge，测试环境已启用的通联支付走通联申请、支付宝外部 URL 打开、微信小程序收银台和订单状态回查。

## 背景

当前 `/pay-way` 已读取 Java `/p/order/getOrderPayInfoByOrderNumber` 和 `/sys/config/info/getSysPaySwitch` 展示订单金额、倒计时和支付方式，但点击“确定支付”只提示“已发起支付”。旧 uni-app 项目在初始化时读取支付开关和 `paySettlementType`，收银台点击支付后调用 `/p/order/pay`，再根据普通支付或通联支付分支唤起 SDK、外部 URL 或通联状态查询。

## 涉及项目

- `hybird-meumall`
- `app-meumall`

## 范围

包含：

- `/pay-way` 发起真实普通订单支付。
- H5 BFF 新增 `/api/bff/order-pay` 和 `/api/bff/allinpay-order-status`。
- `/api/bff/order-pay-info` 聚合 `paySettlementType`。
- H5 Native Bridge 新增 `rpc/payment.pay` 和 `rpc/payment.openUrl` 类型。
- App 调试 Bridge receiver 支持支付 RPC 占位和外部 URL 打开命令。
- 新增 `/pay-result` 支付结果页，支持成功、失败、处理中和重新支付。
- 同步 API、Bridge、页面盘点和对接文档。

不包含：

- 余额支付、支付密码、通联实名认证/绑卡。
- 会员购买、余额充值。
- PayPal。
- 其它小程序 `hyMiniPayParams` 跳转。
- 纯浏览器 H5 外部支付完整适配。
- 自提提货码支付成功页。

## 责任边界

`hybird-meumall`：

- 读取订单支付信息、支付开关和通联结算模式。
- 调 Java 申请支付参数并归一化给页面。
- 调 Native Bridge 唤起 App SDK 或外部 URL。
- 支付后回查订单状态并展示结果页。

`app-meumall`：

- 接收 `payment.pay` 和 `payment.openUrl` RPC。
- 调试阶段返回可测结果；真实 App 后续替换为支付宝/微信 SDK 和系统 openURL。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：
  - `.ai-workspace/contracts/api/h5-payment-real-flow-contract.md`
  - `.ai-workspace/contracts/native-bridge/h5-payment-bridge-contract.md`
- 是否向后兼容：新增接口和新增 Bridge action，向后兼容；旧 App 不支持 Bridge 时 H5 展示可恢复错误。
- 是否需要迁移：需要从“本地提示”迁移到真实支付。
- 是否需要灰度：需要，建议跟随 H5 版本灰度和 App 测试包联调。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0629-006-h5-payment-real-flow.md`
- 需要确认的角色：后端 / 原生 App / QA 发布
- 当前确认状态：用户已确认 H5 先按普通 App 支付 + 通联测试环境主链路推进；通联微信已按 `paymentMode=wechat-mini-program` 生成给 App 的 Bridge payload，真实微信 OpenSDK 和订单回查仍需联调。

## 对方责任

后端：

- 保持 `/p/order/pay`、`/sys/config/paySettlementType`、`/p/allinpay/order/getAliAppPayUrl`、`/p/allinpay/order/getOrderStatus` 可用。
- 保持 `paySettlementType=1 + payType=8` 返回通联小程序支付字段，例如 `miniprogramPayInfo_VSP`。

原生 App：

- 实现 `rpc/payment.pay` 调支付宝/微信 SDK；通联微信分支按 `miniProgram.originalId/path` 打开微信小程序收银台。
- 实现 `rpc/payment.openUrl` 打开通联或支付宝 URL。
- 返回 `success/cancelled/failed/unknown`，H5 再回查订单状态。

管理后台：

- 无新增配置。

CI 或发布：

- H5 需要发版；App 真实 SDK handler 需要 App 测试包。

## Mock 和联调方式

- Mock 数据位置：H5 Vitest fake backend；App `HybridBridgeReceiver` debug RPC。
- 测试接口环境：`https://test.aigcpop.com/mini_h5`。
- App 测试包版本：待 App 方提供。
- 联调步骤：
  1. 创建普通快递待支付订单进入 `/pay-way`。
  2. 验证 `/api/bff/order-pay-info` 返回 `paySettlementType=1`。
  3. 支付宝点击支付后调用 `/p/order/pay` 和 `/p/allinpay/order/getAliAppPayUrl`，H5 通过 `payment.openUrl` 交给 App。
  4. 回到 H5 后通过 `/api/bff/allinpay-order-status` 或 `/api/bff/order-pay-info` 回查。
  5. 微信点击支付后，H5 应发出 `payment.pay`，payload 包含 `provider=allinpay`、`settlementProvider=allinpay`、`paymentMode=wechat-mini-program`、`miniProgram.originalId=gh_e64a1a89a0ad` 和 `miniProgram.path`。
- H5 fallback：Bridge 不可用或超时时展示错误，不伪造支付成功。

## 实现计划

1. 更新根级任务、对接说明、API 契约和 Native Bridge 契约。
2. 扩展 H5 payment service、API adapter 和 BFF route。
3. 改造 `/pay-way` 支付按钮和新增 `/pay-result`。
4. 扩展 H5 typed Bridge 和 App debug receiver。
5. 更新项目文档、测试记录和飞书知识库事实源。
6. 运行 H5 Vitest/typecheck 和 App workflow/Swift 测试。

## 验收标准

- [x] `/pay-way` 加载时读取订单支付信息、支付开关和 `paySettlementType`。
- [x] 支付宝普通/通联分支都通过 `/api/bff/order-pay` 归一化为 Native SDK 或 openURL 执行动作。
- [x] 微信支付分支可根据后端返回字段走普通 Native SDK；测试环境通联微信分支已归一化为 `wechat-mini-program` Bridge payload，并保留 debugRaw 便于联调。
- [x] Bridge 不可用、支付取消、支付失败、支付处理中都有明确 UI。
- [x] `/pay-result` 可展示成功、失败、处理中，并支持重新支付和查看订单。
- [x] API 和 Native Bridge 契约与实现一致。
- [x] 验证命令有记录。

## 验证命令

```bash
pnpm exec vitest run src/features/payment/cashier-real-flow.test.tsx src/lib/bridge/protocol-bridge.test.ts
pnpm typecheck
pnpm exec eslint src/features/payment src/app/pay-way/page.tsx src/app/pay-result/page.tsx src/app/api/bff/order-pay/route.ts src/app/api/bff/allinpay-order-status/route.ts src/app/api/bff/order-pay-info/route.ts src/lib/bridge/protocol-bridge.ts
bash scripts/ai/check-workflow.sh
```

App 侧：

```bash
bash scripts/ai/check-workflow.sh
plutil -lint meumall/Info.plist
xcodebuild build-for-testing -project meumall.xcodeproj -scheme meumall -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:meumallTests
xcodebuild test -project meumall.xcodeproj -scheme meumall -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:meumallTests/meumallTests/bridgeReceiverSupportsPaymentRpcDebugActions
```

## 发布影响

- 是否需要发布：是。
- 发布项目：`hybird-meumall`；真实 SDK handler 需要 `app-meumall` 测试包。
- 是否需要灰度：建议灰度。
- 回滚目标：回滚到上一版仅展示收银台的 H5 版本；App 侧支付 Bridge 可保持兼容。
- smoke check：创建待支付订单、进入收银台、发起支付、回查结果页。

## 风险和阻塞

- App 真正调用支付宝/微信 SDK 需要原生依赖和平台配置，本任务先补 Bridge 契约和 debug receiver。
- 通联微信 App 需要实现微信 OpenSDK 拉起小程序收银台，并在真机确认 launch/cancel/fail/unknown 回调口径。
- 支付结果最终以订单状态回查为准，不能只信任 Native SDK 回调。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-29 | in_progress | 用户确认按普通 App 支付 + 测试环境通联主链路推进。 |
| 2026-06-29 | implemented | H5 BFF、收银台、支付结果页、支付 Bridge 类型、App debug receiver、契约和验证记录已完成；真实 App SDK 和真实订单联调待后续。 |
| 2026-06-29 | synced | 已同步飞书：页面清单 revision 40；H5 与原生 App 对接说明 revision 89；H5 BFF/API 对接说明 revision 11。 |
| 2026-06-30 | implemented | H5 将通联微信 `/p/order/pay` 返回字段归一化为 `payment.pay` 的 `wechat-mini-program` payload，交给 App 使用微信 OpenSDK 打开通联小程序收银台。 |
| 2026-06-30 | synced | 已同步飞书：H5 与原生 App 对接说明 revision 90；H5 BFF/API 对接说明 revision 13；页面清单 revision 42。 |
