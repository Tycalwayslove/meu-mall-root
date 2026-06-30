# API 契约：H5 钱包与银行卡真实接口

## 基本信息

- 契约编号：API-2026-0630-002
- 状态：implemented
- 提供方：Java 业务后端
- 消费方：`hybird-meumall`
- 适用环境：dev / test / prod
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0630-002-h5-wallet-bankcard-real-api.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0630-002-h5-wallet-bankcard-real-api.md`
- Apifox：Project `4403987`，Branch `main`

## 背景

H5 钱包页需要展示分销员钱包余额、结算状态和推广订单；银行卡管理页需要查询通联支付已绑银行卡并支持解绑。

## 接口定义

### H5 BFF

| Method | Path | 用途 | Java 依赖 |
| --- | --- | --- | --- |
| `GET` | `/api/bff/wallet` | 钱包汇总和推广订单 | `GET /p/distribution/wallet/info`、`GET /p/distribution/home/overview`、`GET /p/distribution/api/queryPromotionOrder` |
| `GET` | `/api/bff/wallet/bank-cards` | 银行卡列表 | `GET /p/distribution/home/overview`、`GET /p/allinpay/member/queryBankCardV2` |
| `POST` | `/api/bff/wallet/bank-cards/unbind` | 解绑银行卡 | `POST /p/allinpay/member/unbindBankCardV2` |

H5 BFF 调 Java 时统一由 backend client 注入 `Authorization: <mallToken>`、`source: 1`、`x-request-id` 和客户端上下文 header。

## 请求参数

### 钱包数据

Java `GET /p/distribution/wallet/info` 无 query。

响应 `DistributionUserWalletDto`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `unsettledAmount` | number | 待结算金额 |
| `settledAmount` | number | 可提现金额 |
| `invalidAmount` | number | 已失效金额 |
| `applyWithdrawAmount` | number | 提现申请中金额 |
| `extractedAmount` | number | 已提现金额 |
| `addupAmount` | number | 累积收益，包含已提现佣金和可提现佣金 |

### 推广订单

Java `GET /p/distribution/api/queryPromotionOrder`

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | number | 否 | `1` | 当前页 |
| `size` | number | 否 | `10` | 每页数量 |
| `state` | number | 否 | `2` | `0` 待支付，`1` 待结算，`2` 已结算，`-1` 订单失效 |
| `userId` | string | 是 | 无 | 分销员 ID，H5 从 `/p/distribution/home/overview` 的 `userInfo.distributionUserId` 获取 |

核心响应 `DistributionOrdersVO`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `orderNumber` | string | 订单流水号 |
| `prodName` | string | 商品名称 |
| `pic` | string | 商品图 |
| `distributionAmount` | number | 分销佣金 |
| `price` | number | 售价 |
| `commissionRate` | number | 佣金比例 |
| `state` | number | 分销订单状态，`1` 未结算，`2` 已结算 |
| `orderState` | number | 订单状态 |
| `createTime` | string | 下单时间 |
| `updateTime` | string | 更新时间 |
| `reson` | number | 失效原因 |

### 银行卡列表

Java `GET /p/allinpay/member/queryBankCardV2` 无 query。

响应 `BindCardV2[]`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `bankCardNo` | string | 银行卡号 |
| `bankAccountName` | string | 银行户名 |
| `bankName` | string | 银行名称 |
| `bindTime` | string | 绑定时间 |
| `cardType` | string | `0` 借记卡，`1` 信用卡 |
| `bindStatus` | string | `1` 已绑定，`2` 已解除 |
| `bankReservePhone` | string | 预留手机号 |
| `openBankBranchName` | string | 开户支行 |

### 解绑银行卡

Java `POST /p/allinpay/member/unbindBankCardV2`

```json
{
  "signNum": "商户会员编号",
  "acctNum": "银行卡号"
}
```

H5 BFF 对浏览器端接收：

```json
{
  "acctNum": "6222********5211",
  "signNum": "DU123"
}
```

## H5 BFF 响应结构

### 钱包

```json
{
  "success": true,
  "data": {
    "view": {
      "summary": {
        "balanceText": "2383.43",
        "withdrawableText": "47548",
        "unsettledText": "2383",
        "settledIncomeText": "+3470",
        "pendingIncomeText": "+2383"
      },
      "orders": [
        {
          "id": "1001",
          "title": "商品名称",
          "time": "2026-06-30 10:00",
          "amountText": "+99.00",
          "status": "settled",
          "detailHref": "/orders/NO1001"
        }
      ]
    },
    "page": {
      "current": 1,
      "size": 10,
      "total": 1,
      "pages": 1,
      "hasMore": false
    },
    "modules": {}
  },
  "requestId": "req_xxx"
}
```

### 银行卡

```json
{
  "success": true,
  "data": {
    "view": {
      "cards": [
        {
          "id": "62225211",
          "bankName": "工商银行",
          "cardTypeText": "储蓄卡",
          "maskedCardNo": "**** **** **** 5211",
          "acctNum": "6222********5211",
          "signNum": "DU123"
        }
      ]
    },
    "modules": {}
  },
  "requestId": "req_xxx"
}
```

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `AUTH_FAILED` | 401 | token 缺失或 Java 未授权 | 展示错误态，不回退 mock |
| `HTTP_ERROR` | 4xx/5xx | Java 业务失败或网络失败 | 展示错误和重试 |
| `PARSE_ERROR` | 400 | H5 BFF 入参非法或关键字段缺失 | 展示错误态或操作失败提示 |

## H5 兜底策略

- 钱包接口不可用：钱包页展示错误态和重试按钮。
- 推广订单为空：展示订单空态。
- 银行卡为空：展示“添加银行卡”入口；入口本期不实现新增流程。
- 解绑失败：关闭操作中状态，保留当前列表并展示失败提示。
- 用户未登录：展示错误态，依赖 App 重新注入 token。

## 兼容性要求

- 新增字段：H5 忽略未知字段。
- 删除字段：删除 `distributionUserId`、`bankCardNo` 或解绑所需会员编号会影响功能，需提前通知 H5。
- 字段类型变化：H5 对 ID、金额和卡状态做字符串/数字兼容解析。
- 默认值：钱包金额缺失时按 `0` 展示；银行卡类型未知时展示“银行卡”。

## 测试方式

- 后端验证：使用 App 注入的 `mallToken` 调用 Apifox main 分支接口。
- H5 验证：打开 `/wallet` 和 `/wallet/bank-cards`，验证成功、空态、错误态和解绑银行卡。
- 契约测试：Vitest 覆盖 BFF service、feature API adapter 和页面。
- 联调环境：`https://test.aigcpop.com/mini_h5`

## 回滚方式

如接口异常影响用户，回滚 H5 release 到上一稳定版本；Java 后端接口不需要回滚。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-30 | ready | 根据 Apifox main 分支创建钱包与银行卡真实接口契约。 |
| 2026-06-30 | implemented | H5 已新增钱包/银行卡 BFF、页面和本地验证；待 App WebView 真实 token 联调确认 `signNum`。 |
