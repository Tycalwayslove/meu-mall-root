# 对接说明：H5 钱包与银行卡真实接口联调

## 基本信息

- 编号：BRIEF-2026-0630-002
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0630-002-h5-wallet-bankcard-real-api.md`
- 状态：implemented
- H5 负责人：H5
- 后端负责人：Java 业务后端
- 原生 App 负责人：App WebView
- 管理后台负责人：无
- 目标联调时间：2026-06-30 起
- 目标上线环境：测试环境优先

## 需求背景

H5 个人中心钱包页仍展示本地 mock，本次需要接入真实分销钱包、推广订单、提现记录和通联银行卡接口，避免联调阶段出现静态样例数据。

## H5 侧目标

用户进入 `/wallet` 后看到真实钱包金额和推广订单；点击“提现记录”进入 `/wallet/withdraw-records`，看到按年月分组的真实提现记录；点击“银行卡管理”进入 `/wallet/bank-cards`，看到真实已绑卡列表，并可对单张银行卡发起解绑确认。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 我的钱包 | `/wallet` | H5 | 钱包汇总、结算 tab、推广订单列表 |
| 提现记录 | `/wallet/withdraw-records` | H5 | 按年月分组的提现记录、分页加载、空态 |
| 银行卡管理 | `/wallet/bank-cards` | H5 | 银行卡列表、无卡态、解绑确认 |

## 数据流

```text
钱包页进入 -> H5 BFF /wallet/summary -> 钱包接口 -> H5 渲染汇总
结算 tab / 翻页 -> H5 BFF /wallet/orders + Cookie userInfo.phone -> 推广订单接口 -> H5 追加或重置订单
点击提现记录 -> H5 BFF /wallet/withdraw-records -> 提现记录接口 -> H5 按年月分组渲染并分页追加
银行卡页进入 -> H5 BFF -> 推广概览会员编号 + 通联绑卡查询 -> H5 渲染
点击解绑 -> H5 确认弹窗 -> H5 BFF -> 通联解绑接口 -> 刷新列表
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 否 | 沿用 Apifox 已有接口 | `.ai-workspace/contracts/api/h5-wallet-bankcard-real-api-contract.md` |
| 调整接口 | 待确认 | 银行卡查询响应未显式提供解绑所需 `signNum`，H5 暂用达人 `cardNo` | 同上 |
| 鉴权 | 是 | App 写入 `mallToken`，H5 BFF 转 `Authorization: <mallToken>` | `docs/05_API_SPEC.md` |
| 缓存策略 | 是 | 钱包、订单、提现记录、银行卡均为私有 no-store | 同上 |
| 错误码 | 是 | Java envelope 失败由 BFF 转统一错误 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本期不新增 Bridge | 无 |
| 原生页面跳转 | 否 | 银行卡页为 H5 路由 | 无 |
| 登录态 | 是 | App WebView 需注入 `mallToken` Cookie | `docs/05_API_SPEC.md` |
| 最低 App 版本 | 否 | 无新增原生能力 | 无 |
| fallback | 是 | 缺 token 展示错误态，不展示 mock | 同上 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 否 | 无后台配置 | 无 |
| 素材管理 | 否 | 无 | 无 |
| 上下线开关 | 否 | 无 | 无 |
| 排序规则 | 否 | 沿用 Java 返回顺序 | 无 |
| 灰度规则 | 否 | 跟随 H5 release | 无 |

## H5 侧责任

- [x] 页面结构和状态。
- [x] API client 调用。
- [x] loading、error、empty、未登录状态。
- [x] Mock 数据仅用于单测，联调阶段不作为页面兜底。
- [ ] 联调验证。

## 对方责任

### 后端

- [ ] 确认银行卡解绑 `signNum` 取值来源；若不是达人 `cardNo`，需要在查询绑卡接口返回可用字段。
- [ ] 保持 Apifox main 分支接口路径和 envelope 口径可用。

### 原生 App

- [ ] 在 WebView 中继续写入有效 `mallToken` 和 `pythonToken` Cookie。
- [ ] 初始化写入 Cookie `userInfo`，且其中 `phone` 可作为推广订单接口 `userId` 参数。

### 管理后台

- [x] 无需配合。

## Mock 和联调方式

- Mock 数据位置：仅单测 fixture。
- Mock 使用阶段：仅限单测。
- 测试接口环境：`https://test.aigcpop.com/mini_h5`
- App 测试包版本：沿用当前测试包。
- 管理后台测试入口：无。
- 联调阶段是否已移除页面 mock 兜底：是。

## 真实接口渲染规则

- 首屏展示 loading，不展示 mock 业务数据。
- 接口成功后只渲染真实接口返回并经过 mapper 处理的数据。
- 推广订单、提现记录和银行卡为空时展示空态。
- 接口失败、超时或鉴权失败时展示 error 和重试，不回退 mock。

## H5 兜底策略

- 未登录或 token 缺失：展示接口错误态，提示重试或重新进入 App。
- 钱包金额缺失：金额字段按 `0` 展示，但关键接口缺失时仍视为失败。
- 推广订单为空：展示空态。
- 推广订单分页：切换结算 tab 时重置为第一页；触底加载更多时追加下一页，失败时保留已加载列表并展示可重试提示。
- 提现记录为空：展示空态。
- 提现记录分页：按 `current/size` 触底加载更多，失败时保留已加载列表并展示可重试提示。
- 银行卡为空：展示“添加银行卡”入口，本期不实现新增绑卡。
- 解绑失败：保留列表并展示失败提示。

## 验收标准

- [x] H5 页面成功状态可用。
- [x] H5 页面 loading、error、empty 状态可用。
- [x] 首屏 loading、接口成功、空数据空态、失败/重试状态均已验证。
- [x] 联调阶段未渲染或拼接 mock 业务数据。
- [x] API 契约与文档一致。
- [ ] 对方交付事项已确认。
- [ ] 联调环境验证通过。
- [x] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 将钱包与银行卡管理接入真实接口。
需要后端确认：
1. GET /p/distribution/wallet/info
2. 原生 Cookie userInfo.phone 是否已随 mallToken/pythonToken 一起写入
3. GET /p/distribution/api/queryPromotionOrder?userId=<userInfo.phone>&state=<state>
4. GET /p/userWithdraw/pageDateUserWithdrawCash
5. GET /p/allinpay/member/queryBankCardV2
6. POST /p/allinpay/member/unbindBankCardV2 的 signNum 来源

App 侧只需继续注入 mallToken Cookie；本期不新增 Native Bridge。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-30 | H5 | 已整理 | Apifox main 分支接口已查询；signNum 来源待联调确认。 |
| 2026-06-30 | H5 | H5 已实现 | BFF、页面和本地验证已完成；待 App WebView 真实 `mallToken` 联调。 |
| 2026-06-30 | H5 | 已同步飞书 | 页面清单 revision_id=41，API/BFF 对接说明 revision_id=12。 |
| 2026-07-01 | H5 | BFF 已拆分 | 钱包汇总和推广订单拆分为 `/summary` 与 `/orders`，订单支持 tab 切换和分页加载。 |
| 2026-07-01 | H5 | 提现记录已实现 | 新增 `/wallet/withdraw-records` 与 `/api/bff/wallet/withdraw-records`，接入按年月分组的提现记录分页接口。 |
