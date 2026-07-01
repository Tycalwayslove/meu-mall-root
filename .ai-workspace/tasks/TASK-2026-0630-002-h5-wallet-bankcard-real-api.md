# TASK-2026-0630-002 H5 钱包与银行卡真实接口联调

## 状态

implemented

## 目标

将 `/wallet` 钱包页从本地 mock 迁移到真实 Java 接口渲染，并新增提现记录页、账户管理认证信息页与银行卡管理页，支持卖手申请通联提现、查询按年月分组的提现记录、查询会员认证信息、查询已绑银行卡、添加银行卡和解绑银行卡。

## 背景

个人中心钱包仍是静态高保真页面。用户要求按 Figma 节点 `677:29212` 调整钱包样式，并调用 Apifox 中“分销钱包接口 / 查看分销员钱包数据”和“分销员Api接口 / 分销员推广订单”获取钱包及推广订单数据。提现申请参考 Figma 节点 `681:29853`，接入“卖手申请通联提现”接口且只输入提现金额 `amount`，金额不能超过可提现金额。提现记录按 Figma 节点 `772:18489` 接入“分页获取按年月分组的用户提现记录接口”。账户管理按 Figma 节点 `681:30239` 暂时只展示认证信息入口；认证信息按 Figma 节点 `681:30324` 接入“查询会员信息”接口获取会员姓名和身份证号，同时复用银行卡列表入口，不展示“实名登记”。银行卡管理按 Figma 节点 `681:30436`、`681:30680`、`681:31290` 接入通联支付会员绑卡查询和解绑接口；添加银行卡参考 Figma 节点 `681:30872` 和成功提示节点 `681:31733`，表单只保留银行卡号、身份证号和手机号。

## 涉及项目

- `hybird-meumall`：页面、BFF、mapper、feature API adapter、样式、测试和项目事实源。
- Java 业务后端：沿用 Apifox 已有接口，不新增接口。

## 范围

包含：

- `/wallet` 钱包余额、可提现、未结算、结算统计和推广订单列表真实接口渲染。
- `/wallet` 提现弹窗，只采集提现金额并提交卖手通联提现申请。
- `/wallet/withdraw-records` 提现记录按年月分组、分页加载、空态和错误重试。
- `/wallet/account` 账户管理页，当前只展示认证信息入口。
- `/wallet/account/certification` 认证信息页，展示会员姓名、身份证号和银行卡列表入口。
- `/wallet/bank-cards` 银行卡管理列表、无卡态、添加银行卡入口和解绑确认弹窗。
- `/wallet/bank-cards/add` 添加银行卡表单，只采集银行卡号、身份证号和手机号。
- H5 BFF：
  - `GET /api/bff/wallet/summary`
  - `GET /api/bff/wallet/history-status`
  - `GET /api/bff/wallet/orders`
  - `GET /api/bff/wallet`，仅作为钱包汇总兼容入口
  - `GET /api/bff/wallet/withdraw-records`
  - `POST /api/bff/wallet/withdraw`
  - `GET /api/bff/wallet/member-info`
  - `GET /api/bff/wallet/bank-cards`
  - `POST /api/bff/wallet/bank-cards/apply`
  - `POST /api/bff/wallet/bank-cards/unbind`
- loading、empty、error 和操作中状态。
- BFF mapper / feature API adapter / 页面渲染测试。
- 仓库事实源更新。
- 飞书知识库页面清单和 API/BFF 对接说明同步。

不包含：

- 提现记录详情。
- 推广订单详情页。

## 责任边界

`hybird-meumall`：

- 调用 BFF、展示真实接口数据、处理提现申请、添加/解绑银行卡操作和失败兜底。
- 联调阶段不使用本地 mock 业务数据兜底。

Java 业务后端：

- 提供 Apifox 中已有钱包、推广订单、提现记录、查询会员信息、卖手申请通联提现、通联银行卡查询、创建会员申请和解绑接口。
- 保持鉴权、分页、金额、银行卡字段和错误 envelope 口径稳定。

原生 App：

- 继续向 H5 WebView 注入有效 `mallToken`、`pythonToken` 和 `userInfo` Cookie，其中 `userInfo.phone` 用作推广订单接口 `userId` 参数。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-wallet-bankcard-real-api-contract.md`
- 是否向后兼容：向后兼容，H5 新增消费方 BFF。
- 是否需要迁移：需要将 `/wallet` 从 mock 迁移到真实接口渲染。
- 是否需要灰度：跟随 H5 release 策略。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0630-002-h5-wallet-bankcard-real-api.md`
- 需要确认的角色：后端 / 原生 App。
- 当前确认状态：Apifox main 分支已确认接口字段；App token 联调待验证。

## 对方责任

后端：

- 保持 `/p/distribution/wallet/infoV2`、`/p/distribution/api/queryPromotionOrder`、`/p/userWithdraw/pageDateUserWithdrawCash`、`/p/allinpay/member/getMemberBasicInfoV2`、`/p/allinpay/member/memberWithdrawApply`、`/p/allinpay/member/queryBankCardV2`、`/p/allinpay/member/createMemberApply`、`/p/allinpay/member/unbindBankCardV2` 可用。

原生 App：

- WebView 打开钱包、提现记录和银行卡页时注入有效 `mallToken`。
- 初始化写入 Cookie `userInfo.phone`，供钱包汇总 `userMobile` 和推广订单 `userId` 使用。
- `/p/distribution/wallet/infoV2` 返回 `canWithdrawAmount`，供 H5 展示账户余额、可提现金额并校验提现上限。

管理后台：

- 无。

CI 或发布：

- 无新增链路；随 H5 SSR 发布。

## Mock 和联调方式

- Mock 数据位置：仅单元测试 fixture。
- 测试接口环境：`https://test.aigcpop.com/mini_h5`
- App 测试包版本：沿用当前测试包。
- 管理后台测试入口：无。
- 联调步骤：
  1. App WebView 打开 `/hybird/wallet`。
  2. 验证 BFF 调 `/api/bff/wallet/summary` 时用 Cookie `userInfo.phone` 请求 `/p/distribution/wallet/infoV2?userMobile=<phone>`，并用同一手机号请求 `/api/bff/wallet/orders` 推广订单第一页。
  3. 切换“已结算 / 待结算”，验证只重置订单列表并请求对应 `state` 的第一页。
  4. 下滑到订单列表底部，验证继续请求下一页订单。
  5. 点击“提现”打开弹窗，输入大于可提现金额时应拦截；输入合法金额后提交，验证 `/api/bff/wallet/withdraw` 只向 Java 传 `amount`。
  6. 点击“提现记录”进入 `/hybird/wallet/withdraw-records`，验证按年月分组渲染第一页。
  7. 下滑到提现记录列表底部，验证继续请求下一页；空列表展示空态。
  8. 点击“帐户管理”进入 `/hybird/wallet/account`，确认当前只展示“认证信息”入口。
  9. 点击“认证信息”进入 `/hybird/wallet/account/certification`，验证查询会员信息并展示姓名、身份证号，同时查询银行卡列表并可跳转银行卡管理。
  10. 点击“银行卡管理”进入 `/hybird/wallet/bank-cards`。
  11. 验证查询银行卡列表。
  12. 点击“添加银行卡”进入 `/hybird/wallet/bank-cards/add`，填写银行卡号、身份证号和手机号并提交，验证创建会员申请 body 只包含 `acctNum/cerNum/phone`。
  13. 添加成功后返回 `/hybird/wallet/bank-cards` 并展示“添加成功”提示。
  14. 点击解绑银行卡，确认后验证解绑接口 body 只包含 `acctNum`。
- H5 fallback：钱包页汇总接口失败时金额展示空占位；推广订单接口失败或空列表展示空态；提现记录和银行卡接口失败展示错误/重试；不回退 mock。

## 实现计划

1. 建立钱包和银行卡 BFF service、route 与 browser API adapter，并先补测试。
2. 改造 `/wallet` 页面为真实数据 loading/success/empty/error 渲染，并按 Figma 调整入口和列表样式。
3. 新增钱包提现弹窗和申请 BFF，金额超可提现金额时前端和 BFF 均拦截。
4. 新增 `/wallet/withdraw-records` 页面，接入按年月分组的提现记录分页接口。
5. 新增 `/wallet/bank-cards` 和 `/wallet/bank-cards/add` 页面，接入查卡、添加和解绑流程。
6. 更新项目状态、页面清单和验证记录。

## 验收标准

- [x] `/wallet` 首屏 loading 后只渲染真实钱包和推广订单数据。
- [x] 钱包接口失败或 Cookie `userInfo.phone` 缺失时金额展示空占位；推广订单接口失败时展示订单空态，不回退 mock。
- [x] 推广订单空数组时列表展示空态。
- [x] 推广订单切换结算 tab 时重置为第一页，触底时按下一页加载更多。
- [x] 钱包“提现”打开弹窗，表单只展示金额输入。
- [x] 提现金额为空、格式错误或超过可提现金额时前端拦截。
- [x] 提现申请 BFF 提交前校验 `amount <= canWithdrawAmount`，并只向 Java 传 `{ amount }`。
- [x] “提现记录”进入 `/wallet/withdraw-records`。
- [x] 提现记录按年月分组渲染，触底时按下一页加载更多。
- [x] 提现记录 loading、empty、error 和没有更多状态可用。
- [x] “帐户管理”进入 `/wallet/account`。
- [x] 账户管理页当前只展示“认证信息”入口。
- [x] “认证信息”进入 `/wallet/account/certification`。
- [x] 认证信息页调用 `/api/bff/wallet/member-info`，展示会员姓名和身份证号。
- [x] 认证信息页不展示“实名登记”。
- [x] 认证信息页同时读取银行卡列表，并可跳转银行卡管理页。
- [x] “银行卡管理”进入 `/wallet/bank-cards`。
- [x] 银行卡页成功展示真实已绑卡；无卡时展示“添加银行卡”入口空态。
- [x] “添加银行卡”进入 `/wallet/bank-cards/add`，提交后调用创建会员申请 BFF，成功后返回银行卡管理页并提示添加成功。
- [x] 添加银行卡请求体只包含 `acctNum/cerNum/phone`，不传 `signNum/name`。
- [x] 解绑银行卡确认弹窗可取消；确认后调用解绑 BFF，成功后刷新卡列表。
- [x] 解绑银行卡请求体只包含 `acctNum`，不传 `signNum`。
- [x] BFF 到 Java 的路径、query/body 与 Apifox main 分支一致。
- [x] 钱包账户余额、可提现金额和提现上限统一取 `canWithdrawAmount`；后端字段未返回时 H5 按 `0` 展示和校验。
- [x] 钱包页进入后调用 Python 钱包状态接口；`state=1` 时展示导航栏右侧“历史钱包”入口。
- [x] 点击“历史钱包”发送 Native Bridge `router/navigate route=history-wallet`。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx
pnpm typecheck
git diff --check
```

## 发布影响

- 是否需要发布：是。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：跟随 H5 release。
- 回滚目标：回滚 H5 release 到上一稳定版本。
- smoke check：`/hybird/wallet`、`/hybird/wallet/account`、`/hybird/wallet/account/certification`、`/hybird/wallet/withdraw-records`、`/hybird/wallet/bank-cards`、`/hybird/wallet/bank-cards/add`。

## 风险和阻塞

- 钱包汇总接口必填 `userMobile`，推广订单接口必填 `userId`，本期都从原生 Cookie `userInfo.phone` 获取；若 App 未同步写入该 Cookie，钱包汇总和订单列表会展示错误态。
- `canWithdrawAmount` 后端字段尚未上线；字段缺失时 H5 会把账户余额、可提现金额和提现上限按 `0` 处理，待后端补字段后自动展示真实金额。
- Apifox 创建会员申请和解绑银行卡仍列出 `signNum/name` 等字段，但后端已调整为自行获取；H5 本期只传 `acctNum/cerNum/phone` 或 `acctNum`，需 App WebView 真实 token 联调确认。
- Apifox 查询会员信息标注 `cerNum` 为 SM4 加密；H5 当前只脱敏展示接口返回值，不做解密，需后端确认返回值展示口径。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-30 | ready | 创建钱包与银行卡真实接口联调工作项，Apifox main 分支接口已查询。 |
| 2026-06-30 | implemented | 已完成 H5 BFF、页面、样式、测试和本地浏览器 smoke；待 App WebView 真实 `mallToken` 联调。 |
| 2026-07-01 | implemented | 推广订单 `userId` 来源由推广概览 `distributionUserId` 调整为原生 Cookie `userInfo.phone`。 |
| 2026-07-01 | implemented | 钱包汇总和推广订单 BFF 拆分为 `/summary` 和 `/orders`，订单支持结算 tab 切换和分页加载。 |
| 2026-07-01 | implemented | 新增提现记录页 `/wallet/withdraw-records` 和 BFF `/api/bff/wallet/withdraw-records`，接入按年月分组的提现记录分页接口。 |
| 2026-07-01 | implemented | 新增添加银行卡页 `/wallet/bank-cards/add` 和 BFF `/api/bff/wallet/bank-cards/apply`；解绑 BFF 改为只传 `acctNum`。 |
| 2026-07-01 | implemented | 新增钱包提现弹窗和 BFF `/api/bff/wallet/withdraw`；接入卖手申请通联提现，只传 `amount`，并校验不超过可提现金额。 |
| 2026-07-01 | implemented | 钱包汇总切换为 `/p/distribution/wallet/infoV2`，使用 Cookie `userInfo.phone` 传 `userMobile`；账户余额、可提现金额和提现上限统一取 `canWithdrawAmount`。 |
| 2026-07-01 | implemented | 新增历史钱包状态 BFF `/api/bff/wallet/history-status`，接入 Python `/user/wallet_state`；`state=1` 时展示“历史钱包”并发送原生 route `history-wallet`。 |
| 2026-07-01 | implemented | 钱包页接口失败展示口径调整：钱包汇总失败只展示金额空占位，推广订单失败展示订单空态，不再展示页内错误卡。 |
| 2026-07-01 | implemented | 新增账户管理页 `/wallet/account`、认证信息页 `/wallet/account/certification` 和 BFF `/api/bff/wallet/member-info`，接入 `/p/allinpay/member/getMemberBasicInfoV2` 并复用银行卡列表入口。 |

## 验证记录

| 日期 | 命令 | 结果 |
| --- | --- | --- |
| 2026-06-30 | `pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx` | 通过，3 files / 15 tests |
| 2026-06-30 | `pnpm typecheck` | 通过 |
| 2026-06-30 | `curl -I http://localhost:3109/hybird/wallet` | 200 OK |
| 2026-06-30 | `curl -I http://localhost:3109/hybird/wallet/bank-cards` | 200 OK |
| 2026-06-30 | Playwright + 本机 Chrome 成功态截图 | 钱包、银行卡列表、解绑弹窗可渲染，375 宽度无横向溢出 |
| 2026-07-01 | `pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx` | 通过，3 files / 18 tests |
| 2026-07-01 | `pnpm typecheck` | 通过 |
| 2026-07-01 | `pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx` | 通过，3 files / 20 tests |
| 2026-07-01 | `pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx` | 通过，3 files / 23 tests |
| 2026-07-01 | `pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx` | 通过，3 files / 24 tests |
| 2026-07-01 | `pnpm typecheck` | 通过 |
| 2026-07-01 | `git diff --check` | 通过 |
| 2026-07-01 | `pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx src/lib/navigation/hybrid-navigation.test.ts` | 通过，4 files / 33 tests |
| 2026-07-01 | `pnpm exec vitest run src/features/mine-secondary/wallet-real-service.test.ts src/features/mine-secondary/wallet-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx` | 通过，3 files / 30 tests |
| 2026-07-01 | `pnpm typecheck` | 通过 |
| 2026-07-01 | `git diff --check` | 通过 |

## 飞书知识库同步

| 日期 | 页面 | 链接 | 结果 |
| --- | --- | --- | --- |
| 2026-06-30 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=41 |
| 2026-06-30 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=12 |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=46，补充 `userInfo.phone` 口径 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=17，补充 `userInfo.phone` 口径 |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=47，补充钱包 BFF 拆分和订单分页加载 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=18，补充 `/summary` 与 `/orders` 拆分口径 |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=48，补充钱包提现记录页真实接口 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=19，补充 `/api/bff/wallet/withdraw-records` 口径 |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=49，补充添加银行卡与解绑入参调整 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=20，补充 `/bank-cards/apply` 与解绑只传 `acctNum` |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=50，补充钱包提现申请接入 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=21，补充 `/api/bff/wallet/withdraw` 与只传 `amount` |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=51，补充钱包 `infoV2`、`userMobile`、`canWithdrawAmount` 和入口图标调整 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=22，补充钱包 `infoV2`、`userMobile` 与 `canWithdrawAmount` 口径 |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=52，补充钱包历史状态 BFF 和历史钱包入口 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=23，补充 `/api/bff/wallet/history-status` 与 Python `/user/wallet_state` 口径 |
| 2026-07-01 | 原生路由对接说明 | <https://v05ctaei9gn.feishu.cn/docx/XCZQdRUpioKDT3x7haecT4OLnxe> | 同步成功，revision_id=122，补充 `history-wallet` 原生 route |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=52，补充钱包背景图和失败态展示口径 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=24，补充钱包失败态展示口径 |
| 2026-07-01 | 页面清单 | <https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc> | 同步成功，revision_id=54，补充钱包账户管理与认证信息页 |
| 2026-07-01 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/docx/EprCdgJx1odNebxaWescdGRfnve> | 同步成功，revision_id=25，补充 `/api/bff/wallet/member-info` 与认证信息展示 |

## 未验证项

- 尚未在 App WebView 内用真实 `mallToken` 验证 Java 返回数据、添加银行卡和解绑银行卡动作。
- 尚未在 App WebView 内验证 `userInfo` Cookie 初始化，以及 `userInfo.phone` 作为推广订单 `userId` 的真实返回。
- 尚未在 App WebView 内验证 `userInfo.phone` 作为钱包汇总 `userMobile` 的真实返回。
- 尚未在 App WebView 内验证认证信息 `/p/allinpay/member/getMemberBasicInfoV2` 的真实返回和证件号码展示口径。
- 尚未在 App WebView 内验证提现申请接口真实返回；H5 已按后端最新口径只传 `amount` 并校验不超过 `canWithdrawAmount`。
- 后端 `canWithdrawAmount` 字段尚未上线；字段缺失时 H5 暂按 `0` 展示账户余额和可提现金额。
- 尚未在 App WebView 内验证提现记录接口的真实返回、分页加载和空态。
- 添加银行卡和解绑银行卡已按后端最新口径不传 `signNum/name`；仍需真实环境确认后端可自行补齐会员编号和姓名。
- 尚未在 App WebView 内用真实 `pythonToken` 验证 `/user/wallet_state` 返回，以及点击“历史钱包”后 App 打开原生历史钱包页。
