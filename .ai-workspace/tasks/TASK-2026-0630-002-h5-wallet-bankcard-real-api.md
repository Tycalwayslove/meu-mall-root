# TASK-2026-0630-002 H5 钱包与银行卡真实接口联调

## 状态

implemented

## 目标

将 `/wallet` 钱包页从本地 mock 迁移到真实 Java 接口渲染，并新增提现记录页与银行卡管理页，支持查询按年月分组的提现记录、查询已绑银行卡和解绑银行卡。

## 背景

个人中心钱包仍是静态高保真页面。用户要求按 Figma 节点 `677:29212` 调整钱包样式，并调用 Apifox 中“分销钱包接口 / 查看分销员钱包数据”和“分销员Api接口 / 分销员推广订单”获取钱包及推广订单数据。提现记录按 Figma 节点 `772:18489` 接入“分页获取按年月分组的用户提现记录接口”。银行卡管理按 Figma 节点 `681:30436`、`681:30680`、`681:31290` 接入通联支付会员绑卡查询和解绑接口。本期只完成这些页面和接口，新增绑卡、提现申请等后续补充。

## 涉及项目

- `hybird-meumall`：页面、BFF、mapper、feature API adapter、样式、测试和项目事实源。
- Java 业务后端：沿用 Apifox 已有接口，不新增接口。

## 范围

包含：

- `/wallet` 钱包余额、可提现、未结算、结算统计和推广订单列表真实接口渲染。
- `/wallet/withdraw-records` 提现记录按年月分组、分页加载、空态和错误重试。
- `/wallet/bank-cards` 银行卡管理列表、无卡态和解绑确认弹窗。
- H5 BFF：
  - `GET /api/bff/wallet/summary`
  - `GET /api/bff/wallet/orders`
  - `GET /api/bff/wallet`，仅作为钱包汇总兼容入口
  - `GET /api/bff/wallet/withdraw-records`
  - `GET /api/bff/wallet/bank-cards`
  - `POST /api/bff/wallet/bank-cards/unbind`
- loading、empty、error 和操作中状态。
- BFF mapper / feature API adapter / 页面渲染测试。
- 仓库事实源更新。
- 飞书知识库页面清单和 API/BFF 对接说明同步。

不包含：

- 新增银行卡绑定流程。
- 提现申请、提现记录详情或账户管理详情。
- 推广订单详情页。

## 责任边界

`hybird-meumall`：

- 调用 BFF、展示真实接口数据、处理解绑银行卡操作和失败兜底。
- 联调阶段不使用本地 mock 业务数据兜底。

Java 业务后端：

- 提供 Apifox 中已有钱包、推广订单、提现记录、通联银行卡查询和解绑接口。
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

- 保持 `/p/distribution/wallet/info`、`/p/distribution/home/overview`、`/p/distribution/api/queryPromotionOrder`、`/p/userWithdraw/pageDateUserWithdrawCash`、`/p/allinpay/member/queryBankCardV2`、`/p/allinpay/member/unbindBankCardV2` 可用。

原生 App：

- WebView 打开钱包、提现记录和银行卡页时注入有效 `mallToken`。

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
  2. 验证 BFF 调 `/api/bff/wallet/summary` 获取钱包汇总，并用 Cookie `userInfo.phone` 请求 `/api/bff/wallet/orders` 推广订单第一页。
  3. 切换“已结算 / 待结算”，验证只重置订单列表并请求对应 `state` 的第一页。
  4. 下滑到订单列表底部，验证继续请求下一页订单。
  5. 点击“提现记录”进入 `/hybird/wallet/withdraw-records`，验证按年月分组渲染第一页。
  6. 下滑到提现记录列表底部，验证继续请求下一页；空列表展示空态。
  7. 点击“银行卡管理”进入 `/hybird/wallet/bank-cards`。
  8. 验证查询银行卡列表。
  9. 点击解绑银行卡，确认后验证解绑接口 body 包含 `signNum` 与 `acctNum`。
- H5 fallback：接口失败展示错误/重试；空列表展示空态；不回退 mock。

## 实现计划

1. 建立钱包和银行卡 BFF service、route 与 browser API adapter，并先补测试。
2. 改造 `/wallet` 页面为真实数据 loading/success/empty/error 渲染，并按 Figma 调整入口和列表样式。
3. 新增 `/wallet/withdraw-records` 页面，接入按年月分组的提现记录分页接口。
4. 新增 `/wallet/bank-cards` 页面，接入查卡和解绑流程。
5. 更新项目状态、页面清单和验证记录。

## 验收标准

- [x] `/wallet` 首屏 loading 后只渲染真实钱包和推广订单数据。
- [x] 钱包接口失败、Cookie `userInfo.phone` 缺失或推广订单接口失败时展示错误态，不回退 mock。
- [x] 推广订单空数组时列表展示空态。
- [x] 推广订单切换结算 tab 时重置为第一页，触底时按下一页加载更多。
- [x] “提现记录”进入 `/wallet/withdraw-records`。
- [x] 提现记录按年月分组渲染，触底时按下一页加载更多。
- [x] 提现记录 loading、empty、error 和没有更多状态可用。
- [x] “银行卡管理”进入 `/wallet/bank-cards`。
- [x] 银行卡页成功展示真实已绑卡；无卡时展示“添加银行卡”入口空态。
- [x] 解绑银行卡确认弹窗可取消；确认后调用解绑 BFF，成功后刷新卡列表。
- [x] BFF 到 Java 的路径、query/body 与 Apifox main 分支一致。

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
- smoke check：`/hybird/wallet`、`/hybird/wallet/withdraw-records`、`/hybird/wallet/bank-cards`。

## 风险和阻塞

- 推广订单接口必填 `userId`，本期从原生 Cookie `userInfo.phone` 获取；若 App 未同步写入该 Cookie，钱包订单列表会展示错误态。
- 银行卡解绑接口要求 `signNum`，Apifox 查询银行卡响应未显式返回该字段；H5 将优先使用卡片字段或推广概览 `cardNo` 作为会员编号，仍需后端联调确认。
- 新增银行卡绑定流程不在本期范围，入口暂只展示不可操作提示或占位。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-30 | ready | 创建钱包与银行卡真实接口联调工作项，Apifox main 分支接口已查询。 |
| 2026-06-30 | implemented | 已完成 H5 BFF、页面、样式、测试和本地浏览器 smoke；待 App WebView 真实 `mallToken` 联调。 |
| 2026-07-01 | implemented | 推广订单 `userId` 来源由推广概览 `distributionUserId` 调整为原生 Cookie `userInfo.phone`。 |
| 2026-07-01 | implemented | 钱包汇总和推广订单 BFF 拆分为 `/summary` 和 `/orders`，订单支持结算 tab 切换和分页加载。 |
| 2026-07-01 | implemented | 新增提现记录页 `/wallet/withdraw-records` 和 BFF `/api/bff/wallet/withdraw-records`，接入按年月分组的提现记录分页接口。 |

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

## 未验证项

- 尚未在 App WebView 内用真实 `mallToken` 验证 Java 返回数据和解绑银行卡动作。
- 尚未在 App WebView 内验证 `userInfo` Cookie 初始化，以及 `userInfo.phone` 作为推广订单 `userId` 的真实返回。
- 尚未在 App WebView 内验证提现记录接口的真实返回、分页加载和空态。
- 银行卡解绑 `signNum` 当前取推广概览 `userInfo.cardNo`，仍需后端确认是否为最终口径。
