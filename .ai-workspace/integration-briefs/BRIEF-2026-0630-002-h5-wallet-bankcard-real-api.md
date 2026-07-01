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

H5 个人中心钱包页仍展示本地 mock，本次需要接入真实分销钱包、推广订单、提现记录、账户认证信息、卖手申请通联提现和通联银行卡接口，并补齐添加/解绑银行卡动作，避免联调阶段出现静态样例数据。

## H5 侧目标

用户进入 `/wallet` 后看到真实钱包金额和推广订单；点击“提现”打开金额输入弹窗，金额不能超过可提现金额，确认后提交卖手通联提现申请；点击“提现记录”进入 `/wallet/withdraw-records`，看到按年月分组的真实提现记录；点击“帐户管理”进入 `/wallet/account`，再进入认证信息页查看会员姓名、身份证号和银行卡列表入口；点击“银行卡管理”进入 `/wallet/bank-cards`，看到真实已绑卡列表，可进入 `/wallet/bank-cards/add` 添加银行卡，并可对单张银行卡发起解绑确认。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 我的钱包 | `/wallet` | H5 | 钱包汇总、结算 tab、推广订单列表 |
| 提现申请 | `/wallet` 弹窗 | H5 | 只输入提现金额并提交通联提现申请 |
| 提现记录 | `/wallet/withdraw-records` | H5 | 按年月分组的提现记录、分页加载、空态 |
| 账户管理 | `/wallet/account` | H5 | 当前只展示认证信息入口 |
| 认证信息 | `/wallet/account/certification` | H5 | 会员姓名、身份证号和银行卡列表入口 |
| 银行卡管理 | `/wallet/bank-cards` | H5 | 银行卡列表、无卡态、解绑确认 |
| 添加银行卡 | `/wallet/bank-cards/add` | H5 | 银行卡号、身份证号、手机号表单 |

## 数据流

```text
钱包页进入 -> H5 BFF /wallet/summary -> 钱包接口 -> H5 渲染汇总
结算 tab / 翻页 -> H5 BFF /wallet/orders + Cookie userInfo.phone -> 推广订单接口 -> H5 追加或重置订单
点击提现 -> H5 弹窗输入 amount -> H5 BFF /wallet/withdraw -> 校验可提现金额 -> 通联提现申请接口 -> H5 提示并刷新汇总
点击提现记录 -> H5 BFF /wallet/withdraw-records -> 提现记录接口 -> H5 按年月分组渲染并分页追加
点击帐户管理 -> 认证信息 -> H5 BFF /wallet/member-info -> 查询会员信息接口 -> H5 展示姓名和身份证号
认证信息页进入 -> H5 BFF /wallet/bank-cards -> 通联绑卡查询 -> H5 展示银行卡预览和跳转入口
银行卡页进入 -> H5 BFF -> 通联绑卡查询 -> H5 渲染
点击添加银行卡 -> H5 表单 -> H5 BFF -> 通联创建会员申请 -> 返回银行卡管理并提示添加成功
点击解绑 -> H5 确认弹窗 -> H5 BFF -> 通联解绑接口 -> 刷新列表
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 否 | 沿用 Apifox 已有接口 | `.ai-workspace/contracts/api/h5-wallet-bankcard-real-api-contract.md` |
| 调整接口 | 已确认 | 钱包汇总改为 `/p/distribution/wallet/infoV2` 且必传 `userMobile=userInfo.phone`；历史钱包状态读取 Python `/user/wallet_state`，`state=1` 时展示入口；账户余额、可提现金额和提现上限统一取 `canWithdrawAmount`；认证信息读取 `/p/allinpay/member/getMemberBasicInfoV2`；提现申请只传 `amount`；创建会员申请和解绑银行卡后端自行获取 `signNum/name`，H5 不传 | 同上 |
| 鉴权 | 是 | App 写入 `mallToken` 和 `pythonToken`，H5 BFF 分别转发给 Java / Python | `docs/05_API_SPEC.md` |
| 缓存策略 | 是 | 钱包、订单、提现记录、银行卡均为私有 no-store | 同上 |
| 错误码 | 是 | Java envelope 失败由 BFF 转统一错误 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 是 | 钱包页历史状态 `state=1` 时展示右上角入口，点击发送 `router/navigate route=history-wallet` | `.ai-workspace/contracts/native-bridge/meumall-bridge-protocol.md` |
| 原生页面跳转 | 是 | `history-wallet` 由 App 打开原生历史钱包页；银行卡页仍为 H5 路由 | 同上 |
| 登录态 | 是 | App WebView 需注入 `mallToken` 和 `pythonToken` Cookie | `docs/05_API_SPEC.md` |
| 最低 App 版本 | 待确认 | 需要支持 `history-wallet` 原生 route 的 App 版本 | 无 |
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
- [x] 提现申请弹窗、金额校验和提交状态。
- [x] 账户管理和认证信息展示。
- [x] Mock 数据仅用于单测，联调阶段不作为页面兜底。
- [ ] 联调验证。

## 对方责任

### 后端

- [ ] 保持 Apifox main 分支接口路径和 envelope 口径可用。
- [ ] Python `/user/wallet_state` 返回 `state`，其中 `1` 表示存在历史钱包。
- [ ] 在 `/p/distribution/wallet/infoV2` 返回 `canWithdrawAmount`，供 H5 展示账户余额、可提现金额和校验提现上限。
- [ ] 确认 `/p/allinpay/member/memberWithdrawApply` 只传 `amount` 时后端可自行补齐会员编号、回调地址等信息。
- [ ] 确认 `/p/allinpay/member/getMemberBasicInfoV2` 可返回会员姓名和证件号码；若 `cerNum` 为加密值，需确认 H5 是否继续只脱敏展示。
- [ ] 确认 `/p/allinpay/member/createMemberApply` 只传 `cerNum/acctNum/phone` 时后端可自行补齐会员编号和姓名。
- [ ] 确认 `/p/allinpay/member/unbindBankCardV2` 只传 `acctNum` 时后端可自行补齐会员编号。

### 原生 App

- [ ] 在 WebView 中继续写入有效 `mallToken` 和 `pythonToken` Cookie。
- [ ] 初始化写入 Cookie `userInfo`，且其中 `phone` 可作为钱包汇总 `userMobile` 和推广订单接口 `userId` 参数。
- [ ] 支持 `router/navigate` 的 `history-wallet` route，打开原生历史钱包页。

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
- 钱包页汇总接口失败、超时或鉴权失败时，金额区域展示空数据占位，不展示页内错误卡；推广订单接口失败时展示订单空态，不回退 mock。
- 提现记录和银行卡接口失败、超时或鉴权失败时展示 error 和重试，不回退 mock。
- 认证信息接口失败、超时或鉴权失败时展示姓名和身份证号空占位，银行卡列表仍独立请求。

## H5 兜底策略

- 未登录或 token 缺失：钱包页汇总金额展示空占位，推广订单展示空态；提现记录和银行卡页展示接口错误态。
- 钱包金额缺失：金额字段按 `0` 展示；钱包关键接口失败时金额展示空占位。
- 推广订单为空或接口失败：展示空态。
- 推广订单分页：切换结算 tab 时重置为第一页；触底加载更多时追加下一页，失败时保留已加载列表，不展示页内错误卡。
- 提现申请：金额为空、格式错误、金额超过可提现金额时前端拦截；BFF 提交前再次读取钱包汇总并校验 `amount <= canWithdrawAmount`；成功后关闭弹窗、提示成功并刷新钱包汇总。
- 提现记录为空：展示空态。
- 提现记录分页：按 `current/size` 触底加载更多，失败时保留已加载列表并展示可重试提示。
- 认证信息：只展示会员姓名、身份证号和银行卡入口；不展示“实名登记”模块。
- 银行卡为空：展示“添加银行卡”入口。
- 添加银行卡成功：返回银行卡管理页并展示“添加成功”轻提示。
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
本次 H5 将钱包、账户认证信息与银行卡管理接入真实接口。
需要后端确认：
1. GET /p/distribution/wallet/infoV2?userMobile=<userInfo.phone>，返回 canWithdrawAmount
2. 原生 Cookie userInfo.phone 是否已随 mallToken/pythonToken 一起写入
3. GET /p/distribution/api/queryPromotionOrder?userId=<userInfo.phone>&state=<state>
4. GET /p/userWithdraw/pageDateUserWithdrawCash
5. POST /p/allinpay/member/memberWithdrawApply，H5 只传 amount
6. GET /p/allinpay/member/getMemberBasicInfoV2，H5 展示会员姓名和身份证号
7. GET /p/allinpay/member/queryBankCardV2
8. POST /p/allinpay/member/createMemberApply，H5 只传 cerNum/acctNum/phone
9. POST /p/allinpay/member/unbindBankCardV2，H5 只传 acctNum

App 侧需继续注入 mallToken/pythonToken/userInfo Cookie，并支持已约定的 history-wallet 原生 route。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-30 | H5 | 已整理 | Apifox main 分支接口已查询；后续已确认 `signNum/name` 由后端自行获取。 |
| 2026-06-30 | H5 | H5 已实现 | BFF、页面和本地验证已完成；待 App WebView 真实 `mallToken` 联调。 |
| 2026-06-30 | H5 | 已同步飞书 | 页面清单 revision_id=41，API/BFF 对接说明 revision_id=12。 |
| 2026-07-01 | H5 | BFF 已拆分 | 钱包汇总和推广订单拆分为 `/summary` 与 `/orders`，订单支持 tab 切换和分页加载。 |
| 2026-07-01 | H5 | 提现记录已实现 | 新增 `/wallet/withdraw-records` 与 `/api/bff/wallet/withdraw-records`，接入按年月分组的提现记录分页接口。 |
| 2026-07-01 | H5 | 添加银行卡已实现 | 新增 `/wallet/bank-cards/add` 与 `/api/bff/wallet/bank-cards/apply`；解绑银行卡改为只传 `acctNum`。 |
| 2026-07-01 | H5 | 提现申请已实现 | 钱包页新增提现金额弹窗和 `/api/bff/wallet/withdraw`；BFF 校验可提现金额后只传 `amount` 到通联提现申请接口。 |
| 2026-07-01 | H5 | 钱包汇总接口调整 | 钱包汇总切换为 `/p/distribution/wallet/infoV2`，使用 Cookie `userInfo.phone` 传 `userMobile`；账户余额、可提现金额和提现上限统一取 `canWithdrawAmount`。 |
| 2026-07-01 | H5 | 历史钱包入口已实现 | 新增 `/api/bff/wallet/history-status` 接入 Python `/user/wallet_state`；`state=1` 时展示“历史钱包”并发送原生 route `history-wallet`。 |
| 2026-07-01 | H5 | 账户管理已实现 | 新增 `/wallet/account`、`/wallet/account/certification` 与 `/api/bff/wallet/member-info`，接入 Java `/p/allinpay/member/getMemberBasicInfoV2` 并复用银行卡列表入口。 |
