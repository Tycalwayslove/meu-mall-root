# TASK-2026-0611-008 H5 商品详情真实接口与立即购买链路

## 状态

verified

## 目标

在 `hybird-meumall` 中把商品详情页从静态 mock 改造为真实 Java 商品接口驱动，并纳入本期订单确认页改造，跑通：

```text
商品详情 -> 选择 SKU / 数量 -> 立即购买 -> 订单确认实时校验
  -> 提交普通快递订单 -> 返回待支付订单号
```

## 背景

当前 `/product/[id]`、购买弹窗和 `/order-confirm` 已完成 H5 高保真静态阶段，但商品信息、SKU、价格、库存、配送和订单确认仍来自 mock。旧 uni-app 小程序项目已有商品详情实现，迁移向导已确认可剥离小程序特有逻辑后复用其主要接口与交易流程。

用户已确认本期：

- 使用旧 Java 接口，例如 `https://test.aigcpop.com/mini_h5/prod/prodInfo?prodId=1000054&addrId=0&dvyType=1`。
- 只做普通商品 + 快递 + SKU + 立即购买。
- 秒杀、拼团、自提、同城后置。
- 订单确认页可以纳入本期一并改造。
- 2026-06-12 用户反馈订单仍无法提交，本期范围扩展为接入普通商品快递订单创建；支付 Bridge 和支付结果仍后置。
- 2026-06-26 用户确认“确认付款流程先不要迁移”，本期范围扩展为订单创建后进入 H5 收银台展示支付信息，但点击确认付款只提示“已发起支付”，不调用 `/p/order/pay`。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- `/product/[id]` 读取真实商品详情 BFF。
- `GET /api/bff/product-detail?prodId=<id>` 调 Java `/prod/prodInfo`，默认 `addrId=0`、`dvyType=1`。
- 商品图片 OSS 地址拼接、标题、价格、服务标签、快递配送、SKU、库存和详情内容映射。
- 购买弹窗使用真实 SKU，选择 SKU 和数量后进入 `/order-confirm`。
- `/order-confirm` 读取参数并通过 BFF 重新校验收货地址、商品、SKU、价格和库存。
- `GET /api/bff/order-confirm?productId=<id>&skuId=<skuId>&quantity=<n>&addrId=<addrId>` 先调 Java `/p/address/addrInfo/<addrId|0>` 解析默认/选中地址，再用解析后的地址 ID 调商品详情接口做实时校验。
- `/api/bff/order-confirm` 会继续调 Java `/p/order/confirm`，按旧 uni-app 普通商品立即购买参数生成订单确认上下文；确认页优先使用 Java 确认返回的实付款、数量、运费、优惠和 `submitOrder` 状态。
- `/order-confirm` 提交时通过 `POST /api/bff/order-submit` 创建普通快递订单。
- `POST /api/bff/order-submit` 服务端先调 Java `/p/address/addrInfo/<addrId|0>` 解析收货地址，地址缺失时返回 409；再调 `/prod/prodInfo` 校验商品和 SKU，调 `/p/order/confirm` 生成后端确认上下文，最后调 `/p/order/submit` 返回待支付订单号。
- `/order-confirm` 提交成功后跳转 `/pay-way?orderNumbers=<orderNumbers>&dvyType=1&isPurePoints=0&orderType=0&ordermold=0`。
- `/pay-way` 通过 `GET /api/bff/order-pay-info` 读取 Java `/p/order/getOrderPayInfoByOrderNumber` 和 `/sys/config/info/getSysPaySwitch`，展示金额、倒计时、支付状态和支付方式。
- `/pay-way` 点击“确定支付”本期只本地提示“已发起支付”，不调用 `/p/order/pay`、不接支付 Bridge、不跳支付结果页。
- loading、error、empty、库存不足、参数非法等 H5 兜底。
- 商品详情和订单确认相关测试、文档和验证记录。

不包含：

- 秒杀、拼团、积分商品、活动商品。
- 自提、同城配送、门店定位、地址列表真实接口和地址保存。
- 购物车数量和加入购物车；喵呜已确认无购物车。
- 真正确认付款、支付 Bridge、支付结果页。
- 收藏、浏览记录、优惠券领取、分享海报、分销海报。
- 后端接口实现或改造。

## 责任边界

`hybird-meumall`：

- 负责 H5 BFF、mapper、页面状态、购买弹窗、订单确认页和测试。
- 负责通过 BFF 消费 Java 接口，不在浏览器端直接持有 token 调后端。
- 负责接口失败、无商品、无 SKU、库存不足等兜底。

后端：

- 提供既有 Java 商品详情接口 `/prod/prodInfo`。
- 提供既有 Java 地址详情接口 `/p/address/addrInfo/{addrId}`；`addrId=0` 返回当前用户默认地址。
- 提供既有 Java 普通订单确认接口 `/p/order/confirm` 和提交接口 `/p/order/submit`。
- 保持 `mallToken` 鉴权和 Java envelope 响应。
- 返回商品基础信息、SKU、价格、库存、图片、配送和详情字段。

原生 App：

- 继续负责向 H5 域名写入 `mallToken` Cookie。
- 本任务不新增支付 Native Bridge；确认付款能力后续另建任务。

管理后台：

- 本任务无管理后台实现责任。

CI 或发布：

- 本任务不修改 CI 或 manifest schema，后续随 H5 常规发版。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-product-detail-real-flow-contract.md`
- 是否向后兼容：是，新增 H5 BFF endpoint，不改变后端旧接口。
- 是否需要迁移：H5 从 mock 迁移到真实 BFF；后端无迁移。
- 是否需要灰度：不单独要求，随 H5 常规灰度/回滚策略。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0611-008-h5-product-detail-real-flow.md`
- 需要确认的角色：后端 / 原生 App / QA 或发布。
- 当前确认状态：已确认本期接口路径和范围；响应字段以旧项目和联调返回为准，H5 做兼容映射。

## 对方责任

后端：

- 保证测试环境 `/prod/prodInfo` 可用。
- 确认普通商品 + 快递 + SKU 的字段语义与旧项目一致。

原生 App：

- 保证 WebView 访问 H5 时带 `mallToken` Cookie。

管理后台：

- 无。

CI 或发布：

- 按常规 H5 流程发布和回滚。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/product/mock/product-detail.ts`，仅作为接口失败时的开发 fallback。
- 测试接口环境：`JAVA_API_BASE_URL=https://test.aigcpop.com/mini_h5`。
- App 测试包版本：使用当前可注入 `mallToken` 的测试包。
- 管理后台测试入口：无。
- 联调步骤：
  1. 本地或测试环境启动 H5。
  2. 使用 App 注入的 `mallToken` 或本地 `.env.local` 的 `H5_LOCAL_JAVA_TOKEN`。
  3. 打开 `/product/1000054`。
  4. 选择 SKU 和数量，点击确认进入 `/order-confirm`。
  5. 确认订单页会重新请求并校验同一商品和 SKU。
  6. 点击提交订单，BFF 依次调用 `/p/order/confirm` 和 `/p/order/submit`，成功后进入 `/pay-way`。
  7. 收银台调用 `/p/order/getOrderPayInfoByOrderNumber` 和 `/sys/config/info/getSysPaySwitch` 展示支付信息；点击“确定支付”只提示“已发起支付”。
- H5 fallback：商品接口失败时显示可恢复错误；未知商品显示未找到；SKU 无库存时禁用确认；订单确认校验失败时禁止提交；订单提交失败时保留订单确认页并展示错误，不进入收银台；收银台支付信息失败时展示错误，不调用支付接口。

## 实现计划

1. 为商品详情 BFF mapper、订单确认实时校验和页面行为补测试，先看失败。
2. 新增商品详情真实 BFF service，复用 `createBffRequestContext()`、Java token、后端日志和 `toBffResponse()`。
3. 扩展 `src/features/product/types.ts`，让 view model 支持真实图片、HTML 详情、安全 SKU 和不可购买状态。
4. 改造 `/product/[id]` 与购买弹窗，使用真实数据或可恢复 fallback。
5. 改造 `/order-confirm`，通过 BFF 重新确认商品、SKU、库存、价格和数量。
6. 新增普通快递订单提交 BFF，复用旧 uni-app 普通订单的 `/p/order/confirm` 和 `/p/order/submit` 流程。
7. 更新 H5 API 文档、项目状态、TODO、变更摘要和验证记录。

## 验收标准

- [x] `/product/1000054` 能通过 H5 BFF 请求 Java `/prod/prodInfo?prodId=1000054&addrId=0&dvyType=1`。
- [x] 浏览器端不直接请求 Java 后端，不读取 token。
- [x] 商品标题、价格、图片、快递配送、SKU、库存和详情内容由真实接口映射。
- [x] 相对图片路径按 `JAVA_OSS_ASSET_BASE_URL` 拼接，完整 URL 不重复拼接。
- [x] 商品无 SKU、无库存、接口失败或鉴权失败时页面不白屏。
- [x] 购买弹窗能选择 SKU 和数量，并把 `productId`、`skuId`、`quantity`、`dvyType=1` 带到 `/order-confirm`。
- [x] `/order-confirm` 重新请求商品详情并校验 SKU、库存和价格，不只信任 URL 参数。
- [x] `/order-confirm` 按旧 uni-app 流程调用 Java `/p/order/confirm`，确认页加载阶段即创建后端确认上下文。
- [x] `/order-confirm` 和 `/api/bff/order-submit` 先解析默认/选中收货地址；无收货地址时禁止提交订单。
- [x] `/order-confirm` 点击提交订单时调用 `/api/bff/order-submit`，服务端重新校验 SKU/库存后创建普通快递订单。
- [x] 订单提交成功后展示后端返回的 `orderNumbers`；失败时展示错误并停留在订单确认页。
- [x] 订单提交成功后进入 `/pay-way`，收银台读取订单支付信息和支付开关。
- [x] 确认付款流程暂不迁移；点击收银台“确定支付”只提示“已发起支付”，不调用 `/p/order/pay`。
- [x] `/order-confirm` 成功态保留真实 `productId`，顶部返回使用对应商品详情页作为 fallback。
- [x] 秒杀、拼团、自提、同城、购物车不进入本期实现。
- [x] `pnpm test`、`pnpm typecheck`、`pnpm lint` 和 `pnpm run build` 通过或限制已记录。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/product/product-real-flow.test.tsx src/features/product/order-confirm.test.tsx
pnpm exec vitest run src/features/product/product-real-flow.test.tsx src/features/product/order-confirm.test.tsx src/features/mine-secondary/address-pages.test.tsx src/features/mine-secondary/mine-secondary-pages.test.tsx
pnpm exec vitest run src/features/product/product-detail.test.tsx src/features/product/order-confirm.test.tsx
pnpm exec vitest run src/features/product/product-real-flow.test.tsx src/features/product/order-confirm.test.tsx src/features/product/product-detail.test.tsx
pnpm typecheck
pnpm lint
pnpm run build
```

## 发布影响

- 是否需要发布：需要随 H5 常规发版。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：建议按 H5 常规灰度。
- 回滚目标：回滚到本任务前的 H5 商品详情 mock 版本。
- smoke check：打开 `/product/1000054`，完成 SKU 选择并进入 `/order-confirm`；无 token 时确认错误态可恢复。

## 风险和阻塞

- 旧接口响应字段可能存在环境差异，H5 mapper 需要保守处理可选字段。
- 订单提交已创建待支付订单并进入收银台，但本期不发起真实支付、不接支付 Bridge、不处理支付结果。
- 如果 App 未注入有效 `mallToken`，接口会返回鉴权失败，H5 只能展示错误态。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | ready | 用户确认使用旧 Java 接口，本期只做普通商品、快递、SKU、立即购买和订单确认实时校验。 |
| 2026-06-11 | verified | 已在 `hybird-meumall` 完成商品详情真实 BFF、订单确认实时校验页、页面状态、测试、API 文档和验证记录。 |
| 2026-06-12 | verified | 扩展接入普通快递订单创建：`/api/bff/order-submit` -> Java `/p/order/confirm` -> `/p/order/submit`；支付仍后置。 |
| 2026-06-12 | verified | 订单确认和提交链路补充收货地址解析：BFF 先调 `/p/address/addrInfo/{addrId}`，无地址时阻断提交。 |
| 2026-06-25 | verified | 修复订单确认下单链路：`/api/bff/order-confirm` 加入 Java `/p/order/confirm` 调用，`dvyTypes` 补齐旧 uni-app DTO 的 `lat/lng/stationId`，提交体补 `orderFlowLogParam` 并优先使用确认返回的 `shopCartOrders` 生成 `orderShopParams`。 |
| 2026-06-26 | verified | 新增收银台展示链路：`/pay-way` -> `/api/bff/order-pay-info` -> Java `/p/order/getOrderPayInfoByOrderNumber` 和 `/sys/config/info/getSysPaySwitch`；确认付款按钮本期只提示“已发起支付”。 |

## 验证结果

验证记录：

- `hybird-meumall/.ai/test-reports/2026-06-11-product-detail-real-flow.md`
- `hybird-meumall/.ai/test-reports/2026-06-12-product-order-submit.md`
- `hybird-meumall/.ai/test-reports/2026-06-25-product-order-confirm-submit-flow-fix.md`
- `hybird-meumall/.ai/test-reports/2026-06-26-cashier-pay-info-display.md`

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/product/product-real-flow.test.tsx
pnpm exec vitest run src/features/product/product-real-flow.test.tsx src/features/product/order-confirm.test.tsx
pnpm exec vitest run src/features/product/product-detail.test.tsx src/features/product/order-confirm.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
```

结果：

- `product-real-flow + order-confirm`：2 files / 11 tests 通过。
- 商品真实链路、订单确认、地址页和个人中心二级页回归：4 files / 25 tests 通过。
- 商品详情和订单确认既有测试：5 tests 通过。
- 全量测试：47 files / 239 tests 通过。
- TypeScript：通过。
- ESLint：0 errors，4 warnings；warning 均为 promotion 模块既有 `<img>` 规则提示，不属于本次商品/订单改造。
- Next build：通过，构建产物包含 `/api/bff/product-detail`、`/api/bff/order-confirm`、`/api/bff/order-submit`、`/api/bff/address/*`、`/product/[id]`、`/order-confirm`、`/address` 和 `/address/edit`。
- 本地 smoke：现有 dev server `http://localhost:3109` 下，`/hybird/product/1000054` 和 `/hybird/order-confirm?productId=1000054&skuId=6001&quantity=1` 均返回 HTTP 200。
- 2026-06-25 订单确认参数修复：`product-real-flow` 1 file / 14 tests 通过；`product-real-flow + order-confirm` 2 files / 16 tests 通过；TypeScript 通过；ESLint 0 errors / 4 existing warnings；Next build 通过。
- 2026-06-25 飞书知识库同步：已覆盖同步页面盘点到 `新款app开发资料 / 前端知识库` 页面 <https://v05ctaei9gn.feishu.cn/wiki/WgaqwTRRUitnRNkCtNPcOcDnnre>；返回 docx URL `https://v05ctaei9gn.feishu.cn/docx/IsGAdbLzUoZvZfxzOORcWlKknhc`，`revision_id=22`。

## 已知限制

- 本期已创建普通快递待支付订单，但不接支付 Bridge、收银台和支付结果页。
- 本地或测试环境调用真实 Java 接口仍依赖有效 `mallToken`；无 token 时 H5 展示错误态。
- 地址列表和新增/编辑页面已接真实 H5 BFF，不保留本地业务数据兜底；订单确认/提交链路已使用 Java `/p/address/addrInfo/{addrId}` 解析默认或选中地址。
- 秒杀、拼团、自提、同城、收藏、优惠券领取和支付后置。
