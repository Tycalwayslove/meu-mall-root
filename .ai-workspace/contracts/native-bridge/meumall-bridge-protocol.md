# MeuMall Native Bridge 总协议草案

## 基本信息

- 契约编号：CONTRACT-2026-0603-005
- 状态：draft
- 提供方：`app-meumall`
- 消费方：`hybird-meumall`
- 参考来源：`aigcpop/MallProject` 的 `ProtocolCore/docs/interface.md`
- 适用平台：iOS / Android
- 最低 App 版本：待原生 App 确认
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0603-005-h5-native-bridge-integration.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0603-002-h5-native-bridge-integration.md`

## 背景

MeuMall H5 运行在原生 App WebView 中。H5 需要通过 Native Bridge 获取登录 token、设备和版本信息、请求原生导航、分享、支付、保存图片、关闭页面、接收登出通知等能力。

当前 H5 项目已有 `src/lib/bridge` typed adapter 和 Web mock，但协议仍停留在 `window.MeumallNativeBridge.call(method, payload)` 的简化形态。App 项目目前已有 `WKWebView` 和 manifest runtime，但尚未实现正式 Bridge runtime。

本契约建议以 `MallProject` 的统一信封模型为基础，但按 MeuMall 的项目职责重新抽象，避免业务代码直接依赖具体平台入口。

## 总体原则

- Bridge 不是业务实现层，而是跨端通信协议层。
- H5 只消费原生能力，不在 H5 中模拟原生职责。
- App 只提供容器、登录、安全、系统能力和页面栈能力，不实现 H5 业务页面。
- 所有 Bridge 能力必须支持能力检测、超时、错误码和 fallback。
- 新增能力只扩展能力表，不改变信封、handler 名和回传命名空间。
- token、支付、权限、相册、定位等敏感能力必须单独标注安全边界。

## 通道约定

### H5 到 Native

iOS：

```ts
window.webkit.messageHandlers.bridgeHandler.postMessage(message)
```

Android：

```ts
window.bridgeHandler.postMessage(JSON.stringify(message))
```

### Native 到 H5

RPC 成功：

```ts
window.__bridgeHandler.resolve(callbackId, data)
```

RPC 失败：

```ts
window.__bridgeHandler.reject(callbackId, code, message)
```

Native 主动事件：

```ts
window.__bridgeHandler.emit(eventName, payload)
```

## 消息信封

```ts
type BridgeModule = "router" | "event" | "rpc";

type BridgeMessage<TPayload = unknown> = {
  module: BridgeModule;
  action: string;
  payload?: TPayload;
  callbackId?: string;
};
```

字段说明：

| 字段 | 类型 | 必填 | 说明 | 兼容规则 |
| --- | --- | --- | --- | --- |
| `module` | `"router" \| "event" \| "rpc"` | 是 | 消息分类。 | 不允许改名。新增分类必须单独评审。 |
| `action` | `string` | 是 | 动作名。router 固定为 `navigate`；event 为事件名；rpc 为方法名。 | 新增 action 向后兼容；删除或改名不兼容。 |
| `payload` | `unknown` | 否 | 参数体。 | 新增可选字段向后兼容；改字段类型不兼容。 |
| `callbackId` | `string` | rpc 必填 | RPC 回调关联 ID。 | 仅 rpc 使用。 |

## H5 侧推荐抽象

H5 不直接在业务代码中调用 `window.webkit` 或 `window.bridgeHandler`。推荐分层：

```text
页面/业务逻辑
  -> bridge facade
    -> router / event / rpc typed API
      -> protocol adapter
        -> transport(iOS / Android / Web mock)
```

建议目录：

```text
hybird-meumall/src/lib/bridge/
  types.ts                 # Bridge 方法、事件、错误类型
  index.ts                 # facade，对业务暴露统一入口
  protocol/
    message.ts             # 信封、handler 名、namespace
    transport.ts           # iOS/Android/Web mock postMessage
    callback-registry.ts   # callbackId、Promise、timeout
    router.ts              # navigate()
    event.ts               # emit() / on()
    rpc.ts                 # rpc()
  adapters/
    native.ts              # 浏览器 window 检测
    web-mock.ts            # 本地调试 mock
```

H5 对外暴露建议：

```ts
bridge.canIUse(action)
bridge.navigate(payload)
bridge.emit(eventName, payload)
bridge.rpc(action, payload?, options?)
bridge.on(eventName, handler)
```

现有 `nativeBridge.call(method, payload)` 可以作为兼容内部封装保留一段时间，但新业务能力应优先使用 `navigate`、`emit`、`rpc` 语义化入口。

## App 侧推荐抽象

App 不建议在 `WKScriptMessageHandler` 中写大量 switch 业务逻辑。推荐分层：

```text
WKWebView / WebView 容器
  -> BridgeScriptMessageHandler
    -> BridgeMessageDecoder
      -> BridgeDispatcher
        -> RouterHandler / EventHandler / RPCHandler
          -> App Service(Login, Token, Share, Navigation, Payment...)
  -> BridgeReplyEmitter(resolve/reject/emit)
```

iOS 建议类型：

```swift
struct BridgeMessage: Decodable {
    let module: BridgeModule
    let action: String
    let payload: AnyCodable?
    let callbackId: String?
}

enum BridgeModule: String, Decodable {
    case router
    case event
    case rpc
}
```

App 必须提供：

- `bridgeHandler` message handler 注册。
- message 解码和参数校验。
- RPC `callbackId` 回传。
- unsupported、invalid_payload、permission_denied 等错误码。
- 可信域名校验。
- WebView 销毁时清理 handler，避免循环引用。

## 能力分组

### P0：基础联调能力

| 能力 | module/action | 方向 | 说明 | H5 fallback |
| --- | --- | --- | --- | --- |
| 获取 token | `rpc/getTokens` | H5 -> Native | 获取 `accessToken`、`mallToken`、`expiredAt`。 | 返回未登录态，请求不发起或进入登录提示。 |
| 获取设备信息 | `rpc/getDeviceInfo` | H5 -> Native | 获取平台、App 版本、build、bridgeVersion。 | 使用 web/mock 设备信息，只允许本地调试。 |
| 回首页 | `router/navigate` route=`home` | H5 -> Native | 请求原生切首页 tab 或首页页面。 | H5 内部跳 `/`。 |
| 返回上一页 | `router/navigate` route=`back` | H5 -> Native | 请求原生页面栈返回。 | `history.back()`，不可返回时隐藏按钮。 |
| 打开商品详情 | `router/navigate` route=`product_detail` | H5 -> Native | 请求原生打开商品详情对应 H5/原生容器。 | H5 跳 `/product/[id]`。 |
| 打开 WebView | `router/navigate` route=`webview` | H5 -> Native | 用原生容器打开站内 H5 链接。 | 当前窗口跳转，仅允许白名单 URL。 |
| token 失效事件 | `event/token_expired` | H5 -> Native | H5 通知原生统一登出或刷新登录。 | H5 清理内存态并展示登录失效。 |
| 原生登出通知 | `emit/logout` | Native -> H5 | 原生通知 H5 清理会话态。 | 无。 |

### P1：业务增强能力

| 能力 | 建议 module/action | 方向 | 说明 | H5 fallback |
| --- | --- | --- | --- | --- |
| 分享商品 | `event/share` | H5 -> Native | 拉起原生分享面板。 | 隐藏分享按钮或复制链接。 |
| 设置标题 | `rpc/setTitle` 或 `event/setTitle` | H5 -> Native | 设置原生导航标题。 | H5 内展示标题。 |
| 关闭 WebView | `rpc/closeWebView` 或 `router/back` | H5 -> Native | 关闭当前页面。 | `history.back()`。 |
| 请求登录 | `event/need_login` | H5 -> Native | H5 发现未登录时请求原生登录。 | 展示未登录状态。 |
| 切换一级 tab | `router/navigate` route=`tab` | H5 -> Native | H5 请求原生切 tab。 | H5 路由跳转。 |
| 打开原生页 | `router/navigate` route=`<native-page>` | H5 -> Native | route 直接使用原生页面名，例如 `settings`、`address`、`history-wallet`、`login`。 | 业务自行决定 H5 fallback。 |
| 地址管理 | `rpc/address.*` | H5 -> Native | H5 商品详情、订单确认和地址管理页优先通过 App 获取/管理地址。 | 回退 H5 BFF `/api/bff/address/*`。 |
| App 内支付 | `rpc/paymentStartCashier` | H5 -> Native | H5 收银台请求 App 按后端支付参数拉起支付宝/微信 SDK；通联微信走喵呜小程序支付桥页。 | 不降级到浏览器支付，提示在 App 内完成。 |
| 打开支付 URL | `rpc/payment.openUrl` | H5 -> Native | H5 收银台请求 App 打开通联等外部支付 URL。 | 浏览器调试可直接跳转 URL，App 内应走 Bridge。 |

### P2：后续高风险能力

| 能力 | 说明 | 必须单独契约 |
| --- | --- | --- |
| 保存图片/海报 | 涉及相册权限、失败提示、素材来源。 | 是 |
| 相机/相册选择 | 涉及权限、文件大小、上传链路。 | 是 |
| 定位 | 涉及隐私、授权、城市和坐标精度。 | 是 |
| 剪贴板 | 涉及隐私提示和平台限制。 | 是 |
| 打开外部 App | 涉及 URL scheme 白名单。 | 是 |

## 地址 Bridge 能力

### 背景

旧 uni-app 地址模块依赖小程序/uni 运行时。当前 H5 运行在 App WebView 内，商品详情配送地址、订单确认默认地址和地址管理页应优先通过 App Native Bridge 获取和管理地址；H5 BFF 继续保留为老版本 App 和本地浏览器兜底，同时订单确认/提交 BFF 必须用 Java 地址接口做服务端校验。

### Action 表

| action | payload | resolve data | 用途 |
| --- | --- | --- | --- |
| `address.getDefault` | 无 | `{ "address": Address \| null }` | 商品详情配送行、订单确认默认地址。 |
| `address.getList` | 无 | `{ "addresses": Address[] }` | `/address` 地址列表。 |
| `address.getInfo` | `{ "addrId": "3001" }` | `{ "address": Address \| null }` | `/address/edit` 编辑回填。 |
| `address.save` | `Address` | `{ "addrId": "3001", "message": "地址已保存" }` | 新增/编辑地址。 |
| `address.setDefault` | `{ "addrId": "3001" }` | `{ "message": "默认地址已更新" }` | 设置默认地址。 |
| `address.delete` | `{ "addrId": "3001" }` | `{ "message": "地址已删除" }` | 删除地址。 |
| `address.chooseLocation` | 无 | `{ "location": AddressLocation \| null }` | 定位选点预留；App 后续接入真实定位/地图选点。 |

### Address 字段

```ts
type Address = {
  addr?: string;
  addrId?: string | number;
  area?: string;
  areaId?: string | number;
  city?: string;
  cityId?: string | number;
  commonAddr?: 0 | 1 | "0" | "1" | boolean;
  lat?: string | number;
  lng?: string | number;
  mobile?: string;
  province?: string;
  provinceId?: string | number;
  receiver?: string;
};
```

```ts
type AddressLocation = {
  addr?: string;
  area?: string;
  areaId?: string | number;
  city?: string;
  cityId?: string | number;
  lat?: string | number;
  lng?: string | number;
  name?: string;
  province?: string;
  provinceId?: string | number;
};
```

### H5 兜底规则

- Bridge 不可用、超时、`unsupported` 或 `invalid_payload` 时，H5 回退 `/api/bff/address/*`。
- `address.chooseLocation` 是定位能力预留，不回退 BFF；App 未接入时 H5 显示提示，并输出 `[MeuMall][address-location]` console 日志。
- 订单确认和提交不能只信任 Bridge 返回的地址快照；BFF 仍会调用 Java `/p/address/addrInfo/{addrId}` 校验地址存在性。
- App debug receiver 仅证明 RPC 通道可用，地址列表/详情返回空，不内置调试收货地址。

## 支付 Bridge 能力

### 背景

旧 uni-app 收银台在点击确认付款后会调用 Java `/p/order/pay` 获取支付参数，再根据测试环境配置 `paySettlementType` 分流到普通支付宝/微信 App SDK 或通联支付。当前 H5 收银台保持同一后端链路，H5 自身不实现 SDK 支付，只负责：

1. 请求 H5 BFF 创建支付参数。
2. 将支付参数交给 App Bridge。
3. 根据 App 返回或通联回查结果进入 `/pay-result`。

### Action 表

| action | payload | resolve data | 用途 |
| --- | --- | --- | --- |
| `paymentStartCashier` | `{ provider, payType, orderNumbers, sdkPayload, paymentMode?, settlementProvider?, miniProgram?, bizOrderNo? }` | `{ status, message? }` | 普通 App 内支付宝/微信 SDK 支付，或通联微信小程序支付桥。 |
| `payment.openUrl` | `{ provider: "allinpay", url, orderNumbers, bizOrderNo? }` | `{ opened, status, message? }` | 通联支付宝 URL 支付或后续其它支付 URL。 |

### Payload 字段

```ts
type PaymentPayPayload = {
  provider: "alipay" | "wechat" | "allinpay" | string;
  settlementProvider?: "allinpay";
  paymentMode?: "app-sdk" | "allinpay-mini-program-bridge";
  payType: 7 | 8 | 0 | number;
  orderNumbers: string;
  /** Java /p/order/pay 返回的完整 data，H5 不裁剪。 */
  sdkPayload: unknown;
  bizOrderNo?: string;
  /** data.chnlFrontParamInfo 可解析时的对象，顶层参数原样传给原生。 */
  chnlFrontParamInfo?: Record<string, string>;
  miniProgram?: {
    appId: string;
    cashierAppId?: string;
    extraData?: {
      allinpayParams?: Record<string, string>;
      orderNumbers?: string;
      bizOrderNo?: string;
      reqsn?: string;
      returnToCaller?: boolean;
    };
    launchMode?: "embedded-mini-program";
    path: string;
    type: "wechat";
  };
};

type PaymentOpenUrlPayload = {
  provider: "allinpay" | string;
  url: string;
  orderNumbers: string;
  bizOrderNo?: string;
};
```

### H5 / App 边界

- H5 调 Java `/p/order/pay` 和通联状态回查接口，负责生成和刷新收银台业务状态。
- App 负责真实支付宝/微信 SDK 拉起、通联微信小程序收银台拉起、外部 URL 打开、安全白名单、用户取消和 SDK 回调归一化。
- `paymentStartCashier.sdkPayload` 固定透传 Java `/p/order/pay` 返回的完整 `data`；`chnlFrontParamInfo` 是 H5 对 `sdkPayload.chnlFrontParamInfo` 的 JSON 解析结果；`miniProgram` 只是在通联微信模式下由 H5 派生的喵呜小程序支付桥拉起参数。
- `paymentMode=allinpay-mini-program-bridge` 时，App 打开 `miniProgram.appId=wx264f4850dc92b03d`、`miniProgram.path=package-pay/pages/allinpay-bridge/allinpay-bridge`，并把 `miniProgram.extraData` 传入喵呜小程序；小程序桥页再把 `extraData.allinpayParams` 原样传给通联收银台 `wxef277996acc166c3`。打开成功但结果未知时返回 `status=unknown`，H5 进入结果页回查。
- App 返回 `status=success/paid` 时 H5 进入支付成功页；返回 `cancelled/failed/unknown` 时 H5 展示可重试或待确认状态。
- `payment.openUrl` 在生产 App 中必须校验 URL scheme / host 白名单；debug receiver 可只作为通道验证，不代表生产安全策略。

## 首批能力明细

### `rpc/getTokens`

请求：

```json
{
  "module": "rpc",
  "action": "getTokens",
  "callbackId": "cb_xxx"
}
```

响应：

```json
{
  "accessToken": "eyJ...",
  "mallToken": "mall_xxx",
  "expiredAt": 1735689600000
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `accessToken` | string | 是 | 给 Python 后端，H5 出站加 `Bearer ` 前缀。 |
| `mallToken` | string | 是 | 给 mall4j Java 后端，H5 出站按后端约定裸值或指定 header 传递。 |
| `expiredAt` | number | 是 | 毫秒时间戳。H5 只用于判断即将过期，不持久化长期 token。 |

H5 处理：

- token 只进入内存态或短生命周期请求上下文。
- 禁止写入 `localStorage`、普通缓存或日志。
- 过期或取不到 token 时触发未登录流程或 `event/token_expired`。

### `rpc/getDeviceInfo`

响应：

```json
{
  "platform": "ios",
  "version": "1.2.0",
  "build": "100",
  "bridgeVersion": "1.0.0",
  "supportedActions": ["rpc/getTokens", "rpc/getDeviceInfo", "router/navigate"]
}
```

`supportedActions` 建议由 App 提供，用于 H5 能力检测。若 App 暂时无法提供，H5 可先用固定 allowlist mock，但不能把 mock 当正式能力。

### `router/navigate`

请求：

```json
{
  "module": "router",
  "action": "navigate",
  "payload": {
    "route": "product_detail",
    "params": { "id": "1001" },
    "presentation": { "style": "push", "animated": true }
  }
}
```

首批 route：

| route | 参数 | 归属 | 说明 |
| --- | --- | --- | --- |
| `home` | 无 | App Tab + H5 内容 | 切回首页。 |
| `back` | 无 | App | 原生页面栈返回。 |
| `product_detail` | `{ id: string }` | H5 | 打开商品详情。 |
| `webview` | `{ url: string }` | App 容器 | 打开站内 H5 URL。 |
| `<native-page>` | 可选 | App 原生页 | 打开对应原生页面。原生页不再使用 `route=native_page` + `params.name` 包装；页面名直接作为 `route`。 |

#### 原生页 route 直出规则

`<native-page>` 不是字面量 route，而是表示“由 App 原生实现的页面名”。H5 打开设置页时，正式信封为：

```json
{
  "module": "router",
  "action": "navigate",
  "payload": {
    "route": "settings"
  }
}
```

旧讨论稿中的以下格式后续不再由 H5 主动发送：

```json
{
  "module": "router",
  "action": "navigate",
  "payload": {
    "route": "native_page",
    "params": {
      "name": "settings"
    }
  }
}
```

App dispatcher 需要直接按 `payload.route` 分发原生页，例如 `settings` 打开设置页、`address` 打开地址页、`history-wallet` 打开历史钱包页；`payload.params` 只承载页面参数，不再承载目标页名称。

### `event/token_expired`

请求：

```json
{
  "module": "event",
  "action": "token_expired",
  "payload": { "reason": "401" }
}
```

App 处理：

- 统一处理登录失效。
- 可以刷新登录态或引导登录。
- 处理完成后通过 `emit/logout` 或后续登录态事件通知 H5。

### `event/share`

请求：

```json
{
  "module": "event",
  "action": "share",
  "payload": { "productId": "1001" }
}
```

此能力先作为 P1。正式分享时需要补充分享标题、图片、链接、渠道、失败结果和分享面板状态。

### `emit/logout`

原生调用：

```ts
window.__bridgeHandler.emit("logout", { reason: "session_expired" })
```

H5 处理：

- 清理内存 token 和私有页面状态。
- 取消或失败化当前私有 API 请求。
- 首页、推广、我的等登录态页面进入未登录或重新拉取状态。

## 错误码

| code | 来源 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `unknown` | Native | 未分类错误。 | 记录 telemetry，展示可恢复错误。 |
| `timeout` | Native/H5 | 调用超时。 | 使用 fallback，必要时提示重试。 |
| `cancelled` | Native | 调用被取消。 | 不重复发起，按用户取消处理。 |
| `permission_denied` | Native | 无权限或受限。 | 引导授权或隐藏入口。 |
| `unsupported` | Native | 不支持或未知方法。 | fallback，并记录能力缺失。 |
| `invalid_payload` | Native | 入参非法。 | 修正 H5 参数，联调期记录缺陷。 |
| `no_native_bridge` | H5 | 非原生容器。 | 使用 Web mock 或降级。 |
| `post_failed` | H5 | postMessage 失败。 | fallback，记录错误。 |

## 能力检测

推荐规则：

1. H5 启动后优先调用 `rpc/getDeviceInfo`。
2. 如果返回 `supportedActions`，H5 以此作为正式能力表。
3. 如果没有 `supportedActions`，H5 使用最低 App 版本和本地 allowlist 判断。
4. 业务调用前执行 `bridge.canIUse(action)`。
5. 不支持时必须走 fallback，不能直接抛错导致页面白屏。

能力 key 建议格式：

```text
rpc/getTokens
rpc/getDeviceInfo
router/navigate
event/token_expired
event/share
emit/logout
```

## 安全边界

- App 只向可信 H5 域名暴露 Bridge，例如 `hybird.aigcpop.com` 和明确测试域。
- `webview` route 的 URL 必须做同源或白名单校验。
- H5 不保存长期 token，不把 token 写入日志、埋点、URL、localStorage。
- 支付、提现、账号安全能力不得复用通用 `event` 草率实现，必须单独契约。
- 原生调用 `evaluateJavaScript` 时只能调用固定命名空间和 JSON 参数，不拼接未转义字符串。

## 联调方式

1. H5 先实现协议 adapter、callback registry 和 Web mock。
2. App 实现 `bridgeHandler` 和 `__bridgeHandler` 回传。
3. 双方先只联调 P0。
4. 测试页提供按钮：获取设备、获取 token、导航、token 失效、监听 logout。
5. 每个能力记录成功、失败、超时、无 Bridge 四种结果。
6. P0 稳定后再接 P1 分享和标题等能力。

## 变更流程

1. 更新本契约。
2. 更新对应能力子契约或补充能力表。
3. App 方确认方法名、参数、错误码和最低版本。
4. H5 更新 adapter 和 mock。
5. App 更新 dispatcher 和 handler。
6. 双方使用测试包联调。
7. 验证结果写回工作项和对接说明。

## 回滚方式

- H5 可通过能力检测关闭新入口。
- App 不支持新能力时返回 `unsupported`。
- 高风险能力通过 manifest 或后台配置隐藏入口。
- 如 Bridge runtime 出现严重问题，H5 回退到 Web mock/fallback，只保留基本页面展示。
