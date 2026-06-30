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

H5 运行在 App WebView 中，不能直接使用 uni-app 的 `uni.requestPayment`。H5 负责向 Java 申请支付参数，App 负责调支付宝/微信 SDK 或打开通联外部 URL。

## Bridge 方法一：`payment.pay`

- 调用方向：H5 -> Native
- 信封：`{ module: "rpc", action: "payment.pay", payload, callbackId }`
- 是否需要登录：否，支付申请已由 H5 BFF 使用 `mallToken` 完成。
- 是否需要能力检测：是，H5 通过 `bridge.isAvailable()` 和 RPC 错误处理判断。
- 超时时间：建议 H5 侧 120 秒；当前 runtime 默认可按支付调用覆盖。

请求参数：

```json
{
  "provider": "alipay",
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
| `provider` | `"alipay" \| "wechat"` | 是 | 支付 SDK。 | 新增 provider 需更新契约。 |
| `payType` | number | 是 | Java 支付类型，支付宝 App=7，微信 App=8。 | 兼容旧 Java 枚举。 |
| `orderNumbers` | string | 是 | 订单号。 | 不可为空。 |
| `sdkPayload` | unknown | 是 | Java `/p/order/pay` 返回并由 BFF 归一化的 SDK 参数。 | App 只读取所需字段。 |
| `status` | string | 是 | `success/cancelled/failed/unknown`。 | H5 仍需回查订单。 |

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

- `payment.pay` 不可用：不调用 Java 支付成功逻辑，不伪造成功。
- `payment.openUrl` 不可用：Web 环境可尝试 `window.location.assign(url)`，App 环境展示错误。
- 支付完成与否必须由 H5 回查订单状态。

## 原生实现要求

- [ ] 方法名保持稳定。
- [ ] 校验 `provider/payType/orderNumbers/url`。
- [ ] 支付 SDK 失败、取消、异常均返回明确状态。
- [ ] `payment.openUrl` 只允许安全 scheme 和支付 URL。
- [ ] 最低版本写入 App 发布说明。

## 测试方式

- H5 mock：Vitest 校验 Bridge envelope。
- App 测试包：用真实订单号点击 `/pay-way`。
- 联调步骤：H5 发起支付 -> App 执行 -> H5 回查 -> `/pay-result`。

## 回滚方式

App 支付 Bridge 异常时，H5 可通过 H5 release 回滚到只读收银台；App 保持新增 action 兼容，不影响旧 H5。
