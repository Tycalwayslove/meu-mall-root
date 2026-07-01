# Native Bridge 契约：H5 支付能力

## 基本信息

- 契约编号：BRIDGE-2026-0629-006
- 状态：in_progress
- 提供方：`app-meumall`
- 消费方：`hybird-meumall`
- 适用平台：iOS / Android
- 最低 App 版本：待 App 方确认
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0629-006-h5-payment-real-flow.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0629-006-h5-payment-real-flow.md`

## 背景

H5 运行在 App WebView 中，不能直接使用 uni-app 的 `uni.requestPayment`。H5 负责向 Java 申请支付参数，App 负责调支付宝/微信 SDK、打开通联支付宝外部 URL，或按通联微信支付参数打开喵呜小程序支付桥页；小程序桥页再原样透传参数进入通联收银台。

## Bridge 方法一：`paymentStartCashier`

- 调用方向：H5 -> Native
- 信封：`{ module: "rpc", action: "paymentStartCashier", payload, callbackId }`
- 是否需要登录：否，支付申请已由 H5 BFF 使用 `mallToken` 完成。
- 是否需要能力检测：是，H5 通过 `bridge.isAvailable()` 和 RPC 错误处理判断。
- 超时时间：建议 H5 侧 120 秒；当前 runtime 默认可按支付调用覆盖。

请求参数：

```json
{
  "provider": "alipay",
  "paymentMode": "app-sdk",
  "payType": 7,
  "orderNumbers": "O202606290001",
  "sdkPayload": {}
}
```

返回值：

```json
{
  "status": "success",
  "nativeCode": "0",
  "message": "支付完成"
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 | 兼容规则 |
| --- | --- | --- | --- | --- |
| `provider` | `"alipay" \| "wechat" \| "allinpay"` | 是 | 支付提供方。普通 SDK 为 `alipay/wechat`；通联微信小程序收银台为 `allinpay`。 | 新增 provider 需更新契约。 |
| `settlementProvider` | `"allinpay"` | 否 | 第三方结算提供方；通联链路传 `allinpay`。 | 可选新增字段，旧 App 可忽略但会无法处理通联微信。 |
| `paymentMode` | `"app-sdk" \| "allinpay-mini-program-bridge"` | 否 | 支付执行方式；缺省按 `app-sdk` 兼容。 | 新增模式需更新契约。 |
| `payType` | number | 是 | Java 支付类型，支付宝 App=7，微信 App=8。 | 兼容旧 Java 枚举。 |
| `orderNumbers` | string | 是 | 订单号。 | 不可为空。 |
| `bizOrderNo` | string | 否 | 通联业务订单号。 | 用于 H5 结果页回查。 |
| `sdkPayload` | unknown | 是 | Java `/p/order/pay` 返回的完整 `data`。H5 不再裁剪或重命名该对象。 | App 只读取所需字段；新增字段自然透传。 |
| `chnlFrontParamInfo` | object | 否 | `sdkPayload.chnlFrontParamInfo` 可解析时，H5 解析后的对象；对象内所有顶层参数原样传给原生。 | 通联微信 `result=0` 时优先提供。 |
| `miniProgram` | object | 否 | `paymentMode=allinpay-mini-program-bridge` 时必填，包含喵呜小程序 appId、桥页 path、`extraData.allinpayParams` 和业务上下文。 | 旧 App 不认识该字段时应返回 `unsupported`。 |
| `status` | string | 是 | `success/cancelled/failed/unknown`。 | H5 仍需回查订单。 |

### 通联微信小程序收银台

当测试环境 `paySettlementType=1` 且用户选择微信支付 `payType=8` 时，H5 会先调用 Java `/p/order/pay`，将完整返回 `data` 放入 `sdkPayload`；当 `data.result == 0` 且 `data.chnlFrontParamInfo` 可解析时，H5 会将该 JSON 字符串解析为 `chnlFrontParamInfo` 对象并把对象内所有顶层参数传给原生，同时派生用于打开喵呜小程序支付桥页的 `miniProgram`：

```json
{
  "provider": "allinpay",
  "settlementProvider": "allinpay",
  "paymentMode": "allinpay-mini-program-bridge",
  "payType": 8,
  "orderNumbers": "O202606300001",
  "bizOrderNo": "2606300000012651",
  "sdkPayload": {
    "result": "0",
    "reqTraceNum": "2606300000012651",
    "respTraceNum": "20260630173754208901021131",
    "chnlFrontParamInfo": "{\"appletPayParams\":\"{\\\"reqsn\\\":\\\"20260630173754208901021131\\\",\\\"cusid\\\":\\\"660584053996480\\\",\\\"trxamt\\\":\\\"1\\\"}\"}",
    "respCode": "66666",
    "respMsg": "业务已受理"
  },
  "chnlFrontParamInfo": {
    "appletPayParams": "{\"reqsn\":\"20260630173754208901021131\",\"cusid\":\"660584053996480\",\"trxamt\":\"1\"}"
  },
  "miniProgram": {
    "type": "wechat",
    "appId": "wx264f4850dc92b03d",
    "cashierAppId": "wxef277996acc166c3",
    "launchMode": "embedded-mini-program",
    "path": "package-pay/pages/allinpay-bridge/allinpay-bridge",
    "extraData": {
      "allinpayParams": {
      "appletPayParams": "{\"reqsn\":\"20260630173754208901021131\",\"cusid\":\"660584053996480\",\"trxamt\":\"1\"}"
      },
      "orderNumbers": "O202606300001",
      "bizOrderNo": "2606300000012651",
      "reqsn": "20260630173754208901021131",
      "returnToCaller": true
    }
  }
}
```

原生实现要求：

- `paymentMode=allinpay-mini-program-bridge` 时，App 不按普通微信支付 SDK 参数解析 `sdkPayload`，也不要直接打开通联收银台小程序。
- App 需要打开喵呜小程序支付桥页：`miniProgram.appId=wx264f4850dc92b03d`，`miniProgram.path=package-pay/pages/allinpay-bridge/allinpay-bridge`，`miniProgram.extraData.allinpayParams` 为通联“小程序收银台支付参数”完整对象。
- `sdkPayload` 是 Java `/p/order/pay` 返回的完整 `data`；`chnlFrontParamInfo` 是 H5 从 `sdkPayload.chnlFrontParamInfo` 解析出的对象；`miniProgram.extraData.allinpayParams` 与该对象保持一致。小程序桥页负责把 `allinpayParams` 原样透传给通联收银台 `wxef277996acc166c3`。
- 打开喵呜小程序支付桥页成功只表示已发起支付，不表示支付成功。若 App 无法确认最终支付结果，应 resolve `{ "status": "unknown", "message": "已打开喵呜支付桥" }`，H5 会进入 `/pay-result` 并回查。
- 用户取消、微信未安装、SDK 未注册或 payload 缺字段时，App 分别返回 `cancelled`、`failed` 或 `invalid_payload/unsupported`，H5 不伪造成功。
- 通联微信小程序收银台参考文档：<https://prodoc.allinpay.com/doc/732/>。

## Bridge 方法二：`payment.openUrl`

- 调用方向：H5 -> Native
- 信封：`{ module: "rpc", action: "payment.openUrl", payload, callbackId }`
- 用途：打开通联收银台、支付宝 scheme 或外部支付 URL。

请求参数：

```json
{
  "url": "alipays://platformapi/startapp?...",
  "orderNumbers": "O202606290001",
  "bizOrderNo": "TL202606290001",
  "provider": "allinpay"
}
```

返回值：

```json
{
  "opened": true,
  "status": "opened",
  "message": "已打开支付页面"
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 | 兼容规则 |
| --- | --- | --- | --- | --- |
| `url` | string | 是 | 外部 URL 或 scheme。 | App 应校验 scheme 白名单。 |
| `orderNumbers` | string | 是 | H5 订单号。 | 不可为空。 |
| `bizOrderNo` | string | 否 | 通联业务订单号。 | 用于 H5 回查。 |
| `provider` | string | 否 | `allinpay/alipay/wechat`。 | 新增值向后兼容。 |
| `opened` | boolean | 是 | 是否成功发起打开动作。 | 不代表支付成功。 |

## 错误码

| code | 说明 | H5 处理方式 |
| --- | --- | --- |
| `unsupported` | App 版本不支持。 | 提示升级或稍后重试。 |
| `invalid_payload` | 参数非法。 | 停留收银台并提示。 |
| `cancelled` | 用户取消。 | 回查订单，仍待支付则展示失败/待支付。 |
| `timeout` | App 未回调。 | 回查订单，展示处理中。 |
| `unknown` | 原生异常。 | 展示错误并允许重试。 |

## 能力检测

当前统一信封 runtime 没有独立 `canIUse` RPC。H5 通过以下方式兜底：

```ts
const bridge = createWindowProtocolBridge();
if (!bridge.isAvailable()) {
  // 禁止发起支付，展示 App 版本提示
}
```

调用 RPC 失败或返回 `unsupported` 时同样视为当前 App 不支持。

## H5 fallback

- `paymentStartCashier` 不可用：不调用 Java 支付成功逻辑，不伪造成功。
- `payment.openUrl` 不可用：Web 环境可尝试 `window.location.assign(url)`，App 环境展示错误。
- 支付完成与否必须由 H5 回查订单状态。

## 原生实现要求

- [ ] 方法名保持稳定。
- [ ] 校验 `provider/payType/orderNumbers/url`。
- [ ] `paymentStartCashier` 按 `paymentMode` 分流：`app-sdk` 拉起支付宝/微信 App SDK，`allinpay-mini-program-bridge` 打开喵呜小程序支付桥页。
- [ ] 支付 SDK 失败、取消、异常均返回明确状态。
- [ ] `payment.openUrl` 只允许安全 scheme 和支付 URL。
- [ ] 最低版本写入 App 发布说明。

## 测试方式

- H5 mock：Vitest 校验 Bridge envelope。
- App 测试包：用真实订单号点击 `/pay-way`。
- 联调步骤：H5 发起支付 -> App 执行 -> H5 回查 -> `/pay-result`。

## 回滚方式

App 支付 Bridge 异常时，H5 可通过 H5 release 回滚到只读收银台；App 保持新增 action 兼容，不影响旧 H5。
