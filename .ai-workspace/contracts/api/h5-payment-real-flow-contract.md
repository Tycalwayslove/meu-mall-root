# API 契约：H5 收银台真实支付链路

## 基本信息

- 契约编号：API-2026-0629-006
- 状态：in_progress
- 提供方：Java 后端 / H5 BFF
- 消费方：`hybird-meumall`
- 适用环境：test / prod
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0629-006-h5-payment-real-flow.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0629-006-h5-payment-real-flow.md`

## 背景

H5 收银台需要从只读展示升级为真实发起支付。H5 不直接暴露 Java 后端给浏览器，而是通过 BFF 读取 Cookie 中的 `mallToken` 后调用 Java。

## H5 BFF 接口

### GET `/api/bff/order-pay-info`

读取订单支付信息、支付开关和通联结算模式。

Query：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `orderNumbers` | string | 是 | - | 订单号，支持逗号分隔。 |
| `dvyType` | string | 否 | `1` | 配送方式。 |
| `isPurePoints` | string | 否 | `0` | 是否纯积分订单。 |
| `orderType` | string | 否 | `0` | 订单类型。 |
| `ordermold` | string | 否 | `0` | 虚拟商品标识。 |

后端调用：

- `GET /p/order/getOrderPayInfoByOrderNumber?orderNumbers=<orderNumbers>`
- `GET /sys/config/info/getSysPaySwitch`
- `GET /sys/config/paySettlementType`

### POST `/api/bff/order-pay`

申请支付执行参数。

Body：

```json
{
  "orderNumbers": "O202606290001",
  "payType": 7,
  "dvyType": "1",
  "isPurePoints": false,
  "orderType": "0",
  "ordermold": "0"
}
```

H5 BFF 转 Java `/p/order/pay`：

```json
{
  "payType": 7,
  "orderNumbers": "O202606290001",
  "returnUrl": "https://<h5-host>/<basePath>/pay-result?orderNumbers=O202606290001",
  "systemType": 5,
  "allinPaySystemType": 1
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `systemType` | number | 是 | H5 从 App 上下文推断：Android=4，iOS=5，默认 iOS=5。 |
| `allinPaySystemType` | number | 否 | `paySettlementType=1` 时传 `1`。 |
| `source` | header | 是 | Java 请求头由 H5 backend client 统一设置为 `1`。 |

响应：

```json
{
  "view": {
    "orderNumbers": "O202606290001",
    "payType": 7,
    "paySettlementType": 1,
    "execution": {
      "type": "open-url",
      "provider": "allinpay",
      "url": "alipays://platformapi/startapp?...",
      "bizOrderNo": "TL202606290001"
    }
  },
  "modules": {
    "orderPay": {},
    "paySettlementType": 1
  }
}
```

通联微信小程序收银台响应示例：

```json
{
  "view": {
    "orderNumbers": "O202606300001",
    "payType": 8,
    "paySettlementType": 1,
    "execution": {
      "type": "native-sdk",
      "provider": "allinpay",
      "settlementProvider": "allinpay",
      "paymentMode": "wechat-mini-program",
      "bizOrderNo": "TL202606300001",
      "paymentPayload": {
        "cusid": "990581007426001",
        "appid": "002",
        "trxamt": "12990",
        "reqsn": "O202606300001"
      },
      "miniProgram": {
        "type": "wechat",
        "appId": "wxef277996acc166c3",
        "originalId": "gh_e64a1a89a0ad",
        "path": "pages/orderDetail/orderDetail?cusid=990581007426001&appid=002&trxamt=12990&reqsn=O202606300001",
        "queryString": "cusid=990581007426001&appid=002&trxamt=12990&reqsn=O202606300001",
        "query": {
          "cusid": "990581007426001",
          "appid": "002",
          "trxamt": "12990",
          "reqsn": "O202606300001"
        }
      }
    }
  },
  "modules": {
    "orderPay": {
      "bizOrderNo": "TL202606300001",
      "miniprogramPayInfo_VSP": "{\"cusid\":\"990581007426001\",\"appid\":\"002\",\"trxamt\":\"12990\",\"reqsn\":\"O202606300001\"}"
    },
    "paySettlementType": 1
  }
}
```

`execution.type`：

| 类型 | 说明 | H5 处理 |
| --- | --- | --- |
| `native-sdk` | App 支付 SDK 参数；`paymentMode=wechat-mini-program` 时表示通联微信小程序收银台参数。 | 调 `rpc/payment.pay`。 |
| `open-url` | 通联或支付宝外部 URL。 | 调 `rpc/payment.openUrl`。 |
| `paid` | 纯积分或无需支付。 | 直接进入成功结果。 |

通联分流规则：

- `paySettlementType=1 + payType=7`：H5 BFF 从 `/p/order/pay` 读取 `miniprogramPayInfo_VSP`，再调 Java `/p/allinpay/order/getAliAppPayUrl` 换取支付宝 URL，返回 `execution.type="open-url"`。
- `paySettlementType=1 + payType=8`：H5 BFF 从 `/p/order/pay` 读取 `miniprogramPayInfo_VSP/miniprogramPayInfo/miniProgramPayInfo/payInfo/wxPayInfo` 或顶层通联字段，生成 `execution.type="native-sdk"`、`provider="allinpay"`、`paymentMode="wechat-mini-program"`、`miniProgram` 和原始 `paymentPayload`。
- `miniProgram.path` 固定以 `pages/orderDetail/orderDetail` 为页面路径，query 来自后端通联支付字段，H5 不自行新增签名字段。

### GET `/api/bff/allinpay-order-status`

查询通联订单状态。

Query：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `bizOrderNo` | string | 是 | 通联业务订单号。 |
| `orderNumbers` | string | 否 | H5 订单号，用于结果页展示。 |

后端调用：

- `GET /p/allinpay/order/getOrderStatus?bizOrderNo=<bizOrderNo>`

响应：

```json
{
  "view": {
    "bizOrderNo": "TL202606290001",
    "status": "paid",
    "paid": true,
    "statusText": "支付成功"
  },
  "modules": {
    "orderStatus": {
      "orderStatus": 4
    }
  }
}
```

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `PARSE_ERROR` | 400 | 参数缺失或格式错误。 | 展示错误，不发起支付。 |
| `TOKEN_MISSING` | 401 | `mallToken` 缺失。 | 走登录态兜底。 |
| `HTTP_ERROR` | 502 | Java 业务失败。 | 展示后端消息，允许重试。 |
| `NETWORK_ERROR` | 502/504 | BFF 或后端网络失败。 | 展示可恢复错误。 |

## H5 兜底策略

- 支付方式为空时禁用按钮。
- `paySettlementType` 读取失败时按普通支付处理，但保留模块为空；测试环境应视为联调风险。
- Bridge 不可用或超时不判定支付成功。
- 支付结果最终以 `/p/order/getOrderPayInfoByOrderNumber` 或 `/p/allinpay/order/getOrderStatus` 为准。

## 兼容性要求

- 新增字段：向后兼容。
- 删除字段：不允许。
- 字段类型变化：必须先更新契约并联调。
- 默认值：`systemType` 默认 iOS=5，`paySettlementType` 默认 0。

## 测试方式

- H5 验证：Vitest 覆盖 BFF mapper、API adapter、页面状态和 Bridge payload。
- 联调环境：`https://test.aigcpop.com/mini_h5`。
- 契约测试：H5 fake backend 校验 Java 出站 path/body。

## 回滚方式

H5 回滚到上一版仅展示支付信息的 release；后端旧接口保持不变；App 新增 Bridge action 可保留兼容。
