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

H5 钱包页需要展示分销员钱包余额、结算状态、推广订单和提现记录，并支持卖手申请通联提现；账户管理页需要展示通联会员认证信息；银行卡管理页需要查询通联支付已绑银行卡，并支持添加银行卡和解绑。

## 接口定义

### H5 BFF

| Method | Path | 用途 | 后端依赖 |
| --- | --- | --- | --- |
| `GET` | `/api/bff/wallet/summary` | 钱包汇总 | `GET /p/distribution/wallet/infoV2` |
| `GET` | `/api/bff/wallet/history-status` | 历史钱包状态 | Python `GET /user/wallet_state` |
| `GET` | `/api/bff/wallet/orders` | 推广订单分页 | `GET /p/distribution/api/queryPromotionOrder` |
| `GET` | `/api/bff/wallet/withdraw-records` | 提现记录分页 | `GET /p/userWithdraw/pageDateUserWithdrawCash` |
| `POST` | `/api/bff/wallet/withdraw` | 卖手申请通联提现 | `POST /p/allinpay/member/memberWithdrawApply` |
| `GET` | `/api/bff/wallet` | 钱包汇总兼容入口 | `GET /p/distribution/wallet/infoV2` |
| `GET` | `/api/bff/wallet/member-info` | 会员认证信息 | `GET /p/allinpay/member/getMemberBasicInfoV2` |
| `GET` | `/api/bff/wallet/bank-cards` | 银行卡列表 | `GET /p/allinpay/member/queryBankCardV2` |
| `POST` | `/api/bff/wallet/bank-cards/apply` | 添加银行卡 / 创建会员申请 | `POST /p/allinpay/member/createMemberApply` |
| `POST` | `/api/bff/wallet/bank-cards/unbind` | 解绑银行卡 | `POST /p/allinpay/member/unbindBankCardV2` |

H5 BFF 调 Java 时统一由 backend client 注入 `Authorization: <mallToken>`、`source: 1`、`x-request-id` 和客户端上下文 header。
H5 BFF 调 Python 时由 backend client 注入 `Authorization: Bearer <pythonToken>`、`x-request-id` 和客户端上下文 header。

## 请求参数

### 钱包数据

Java `GET /p/distribution/wallet/infoV2`

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `userMobile` | string | 是 | H5 从原生 Cookie `userInfo.phone` 获取 |

H5 BFF 使用 `/api/bff/wallet/summary` 独立获取钱包汇总。旧 `/api/bff/wallet` 仅作为汇总兼容入口保留，不再聚合推广订单。

响应 `DistributionUserWalletV2Dto`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `unsettledAmount` | number | 待结算金额 |
| `settledAmount` | number | 已结算金额 |
| `canWithdrawAmount` | number | 可提现金额；后端待补字段，H5 账户余额和可提现金额都取该字段 |
| `invalidAmount` | number | 已失效金额 |
| `applyWithdrawAmount` | number | 提现申请中金额 |
| `extractedAmount` | number | 已提现金额 |
| `addupAmount` | number | 累积收益，包含已提现佣金和可提现佣金 |

### 历史钱包状态

Python `GET /user/wallet_state`

H5 BFF 使用 `/api/bff/wallet/history-status` 独立获取历史钱包状态。Apifox OpenAPI 当前响应 schema 为空对象，产品/后端最新口径为响应包含 `state`；H5 兼容顶层 `state` 和 `data.state`。当 `state=1` 时，钱包页导航栏右侧展示“历史钱包”入口；其它状态或接口失败时不展示入口。

核心响应：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `state` | number | `1` 表示存在历史钱包 |

### 推广订单

Java `GET /p/distribution/api/queryPromotionOrder`

H5 BFF 使用 `/api/bff/wallet/orders?state=settled|pending&current=1&size=10` 独立分页获取推广订单。切换结算 tab 时重置订单页码为 `1`；触底加载更多时传 `current + 1`，钱包汇总不随订单翻页重复请求。

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | number | 否 | `1` | 当前页 |
| `size` | number | 否 | `10` | 每页数量 |
| `state` | number | 否 | `2` | `0` 待支付，`1` 待结算，`2` 已结算，`-1` 订单失效 |
| `userId` | string | 是 | 无 | Java 参数名保持 `userId`，H5 从原生 Cookie `userInfo.phone` 获取 |

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

### 提现记录

Java `GET /p/userWithdraw/pageDateUserWithdrawCash`

H5 BFF 使用 `/api/bff/wallet/withdraw-records?current=1&size=10` 分页获取提现记录。Java 响应按年月分组，H5 保留分组并在页面触底时传 `current + 1` 追加下一页。

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | number | 否 | `1` | 当前页 |
| `size` | number | 否 | `10` | 每页数量 |

核心响应 `DateUserWithdrawCashVO`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `date` | string | 提现年月 |
| `withdrawCashVOs` | `UserWithdrawCashVO[]` | 提现记录 |

核心响应 `UserWithdrawCashVO`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `cashId` | number | 提现记录 ID |
| `orderNo` | string | 提现订单号 |
| `amount` | number | 提现金额 |
| `status` | number | `0` 待支付，`1` 申请成功/到账中，`2` 提现成功，`3` 提现失败 |
| `createTime` | string | 创建时间 |
| `updateTime` | string | 更新时间 |

### 提现申请

Java `POST /p/allinpay/member/memberWithdrawApply`

Apifox main 分支仍列出 `signNum/notifyUrl/amount`，但后端最新约定为：H5 BFF 对浏览器端只接收提现金额 `amount`，`signNum` 和回调地址等信息由后端自行处理。BFF 在转发前会先读取 `GET /p/distribution/wallet/infoV2?userMobile=<userInfo.phone>`，校验提现金额大于 `0` 且不超过 `canWithdrawAmount` 可提现金额。

H5 BFF 对浏览器端接收：

```json
{
  "amount": 99.5
}
```

H5 BFF 转 Java 时只发送：

```json
{
  "amount": 99.5
}
```

H5 BFF 禁止传：

```json
{
  "signNum": "不传",
  "notifyUrl": "不传"
}
```

核心响应 `MemberWithdrawApplyResponse`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `result` | string | 订单状态，`0` 进行中，`1` 交易成功，`2` 交易失败 |
| `respTraceNum` | string | 通联订单号 |
| `reqTraceNum` | string | 商户订单号 |
| `chnlTradeCode` | string | 收付通渠道银行流水号 |
| `extendParams` | string | 扩展信息 |
| `respCode` | string | 业务返回码，`00000` 代表成功 |
| `respMsg` | string | 业务返回说明 |

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

### 会员认证信息

Java `GET /p/allinpay/member/getMemberBasicInfoV2` 无 query。

H5 BFF 使用 `/api/bff/wallet/member-info` 获取认证信息。账户管理页 `/wallet/account` 当前只展示“认证信息”入口；认证信息页 `/wallet/account/certification` 展示会员姓名和身份证号，并同时消费 `/api/bff/wallet/bank-cards` 展示银行卡列表预览和跳转入口。页面不展示 Figma 中的“实名登记”模块。

核心响应 `MemberBasicInfoV2`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `name` | string | 姓名 |
| `memberName` | string | 会员姓名，H5 优先展示该字段 |
| `cerType` | string | 证件类型 |
| `cerNum` | string | 证件号码；Apifox 标注为 SM4 加密，H5 当前只脱敏展示，不做解密 |
| `isWithdraw` | string | 是否允许提现 |
| `phone` | string | 手机号 |
| `idValidStartDate` | string | 证件有效期开始 |
| `idValidEndDate` | string | 证件有效期结束 |
| `registerTime` | string | 注册时间 |
| `isRealNameAuth` | string | 是否实名 |
| `realNameAuthTime` | string | 实名时间 |
| `memberStatus` | string | 会员状态 |
| `memberRole` | string | 会员角色 |
| `memberType` | string | 会员类型 |

### 添加银行卡

Java `POST /p/allinpay/member/createMemberApply`

Apifox main 分支仍列出 `signNum/name/cerNum/acctNum/phone`，但后端最新约定为：`signNum` 和 `name` 由后端自行获取，H5 不传。

H5 BFF 对浏览器端接收并转 Java：

```json
{
  "cerNum": "证件号码",
  "acctNum": "银行卡号",
  "phone": "银行预留手机号"
}
```

H5 BFF 禁止传：

```json
{
  "signNum": "不传",
  "name": "不传"
}
```

核心响应 `MemberApplyResponse`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `respTraceNum` | string | 响应流水号 |
| `signNum` | string | 商户会员编号，后端返回，仅用于调试或后续扩展 |
| `respCode` | string | 业务返回码，`00000` 代表成功 |
| `respMsg` | string | 业务返回说明 |

### 解绑银行卡

Java `POST /p/allinpay/member/unbindBankCardV2`

```json
{
  "acctNum": "银行卡号"
}
```

Apifox main 分支仍列出 `signNum/acctNum`，但后端最新约定为：`signNum` 由后端自行获取，H5 BFF 对浏览器端只接收并转发：

```json
{
  "acctNum": "6222********5211"
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
          "status": "settled"
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
          "acctNum": "6222********5211"
        }
      ]
    },
    "modules": {}
  },
  "requestId": "req_xxx"
}
```

### 会员认证信息

```json
{
  "success": true,
  "data": {
    "view": {
      "member": {
        "nameText": "张三",
        "cerNumText": "440***********1234"
      }
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

- 钱包汇总接口不可用：钱包页账户卡片金额展示为空数据占位，不额外展示错误卡或重试按钮。
- 历史钱包状态不可用或 `state` 非 `1`：不展示导航栏“历史钱包”入口，不影响钱包汇总和订单列表。
- 推广订单为空或订单接口失败：展示订单空态。
- 提现记录为空：展示提现记录空态；接口失败展示错误和重试。
- 提现申请：钱包页弹窗只输入金额；前端和 BFF 均校验金额不能超过可提现金额；成功后关闭弹窗、提示“提现申请已提交”并刷新钱包汇总。
- 认证信息不可用：认证信息页展示姓名和身份证号空占位；银行卡列表仍独立请求和展示。
- 银行卡为空：展示“添加银行卡”入口。
- 添加银行卡成功：返回银行卡管理页并展示“添加成功”提示。
- 解绑失败：关闭操作中状态，保留当前列表并展示失败提示。
- 用户未登录：展示错误态，依赖 App 重新注入 token。

## 兼容性要求

- 新增字段：H5 忽略未知字段。
- 删除字段：删除 Cookie `userInfo.phone`、历史钱包 `state`、钱包 `canWithdrawAmount`、会员信息 `memberName/name/cerNum`、银行卡 `bankCardNo`、提现申请所需 `amount`、创建会员申请所需 `cerNum/acctNum/phone` 会影响功能，需提前通知 H5。
- 字段类型变化：H5 对 ID、金额和卡状态做字符串/数字兼容解析。
- 默认值：钱包金额缺失时按 `0` 展示；`canWithdrawAmount` 缺失时账户余额、可提现金额和提现上限均按 `0` 处理；银行卡类型未知时展示“银行卡”。

## 测试方式

- 后端验证：使用 App 注入的 `mallToken` 调用 Apifox main 分支接口。
- H5 验证：打开 `/wallet`、`/wallet/account`、`/wallet/account/certification`、`/wallet/withdraw-records`、`/wallet/bank-cards` 和 `/wallet/bank-cards/add`，验证成功、空态、错误态、历史钱包入口、分页加载、认证信息、提现申请、添加银行卡和解绑银行卡。
- 契约测试：Vitest 覆盖 BFF service、feature API adapter 和页面。
- 联调环境：`https://test.aigcpop.com/mini_h5`

## 回滚方式

如接口异常影响用户，回滚 H5 release 到上一稳定版本；Java 后端接口不需要回滚。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-30 | ready | 根据 Apifox main 分支创建钱包与银行卡真实接口契约。 |
| 2026-06-30 | implemented | H5 已新增钱包/银行卡 BFF、页面和本地验证；后续添加/解绑入参已按后端最新口径调整。 |
| 2026-07-01 | implemented | H5 钱包汇总和推广订单拆分为 `/summary` 与 `/orders` 两个 BFF，订单支持 tab 切换和分页加载。 |
| 2026-07-01 | implemented | 新增提现记录页和 `/api/bff/wallet/withdraw-records`，接入 `/p/userWithdraw/pageDateUserWithdrawCash`。 |
| 2026-07-01 | implemented | 新增添加银行卡页和 `/api/bff/wallet/bank-cards/apply`，接入 `/p/allinpay/member/createMemberApply`；解绑银行卡改为只传 `acctNum`。 |
| 2026-07-01 | implemented | 新增钱包提现弹窗和 `/api/bff/wallet/withdraw`，接入 `/p/allinpay/member/memberWithdrawApply`；H5 只传 `amount`，BFF 校验不超过可提现金额。 |
| 2026-07-01 | implemented | 钱包汇总切换为 `/p/distribution/wallet/infoV2`，使用 Cookie `userInfo.phone` 传 `userMobile`；账户余额、可提现金额和提现上限统一取 `canWithdrawAmount`。 |
| 2026-07-01 | implemented | 新增 `/api/bff/wallet/history-status`，接入 Python `/user/wallet_state`；`state=1` 时展示钱包页“历史钱包”入口。 |
| 2026-07-01 | implemented | 钱包页汇总接口失败时只展示金额空占位，推广订单接口失败时展示订单空态，不再展示页内错误卡和重试按钮。 |
| 2026-07-01 | implemented | 新增 `/wallet/account`、`/wallet/account/certification` 和 `/api/bff/wallet/member-info`，接入 Java `/p/allinpay/member/getMemberBasicInfoV2` 展示认证信息，并复用银行卡列表入口。 |
