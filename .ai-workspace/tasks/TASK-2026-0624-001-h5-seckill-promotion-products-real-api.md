# TASK-2026-0624-001-H5 秒杀和推广商品真实接口联调

## 状态

verified

## 目标

将首页活动入口跳转后的两个 H5 商品列表接入 Java 真实分页接口：

- `/seckill` 使用 Apifox「首页秒杀商品分页」。
- `/promotion/products` 使用 Apifox「推广商品页分页列表」。

页面需要展示真实商品，并能从商品卡进入现有商品详情页。

## 背景

首页活动区当前固定展示「限时秒杀」和「推广带货」两张卡，其中 `/seckill` 和 `/promotion/products` 已完成静态高保真，但商品列表仍来自本地 mock。新一轮联调需要让两个列表使用 Java 分页接口；链调阶段以 Java 返回为准，接口无数据时展示空态，不再拼接本地 mock。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 查询并记录 Apifox 当前接口契约。
- 新增秒杀商品 BFF：`GET /api/bff/seckill/products?current=<current>&size=<size>`。
- 新增推广商品 BFF：`GET /api/bff/promotion/products?current=<current>&size=<size>&prodName=<prodName>&sort=<sort>&categoryId2=<id>&categoryId3=<id>`。
- `/seckill` 接入真实秒杀商品列表，商品卡点击进入 `/product/<prodId>`。
- `/promotion/products` 接入真实推广商品列表，推广按钮使用真实 `prodId` 发送分享 payload。
- 接口失败、空数据或字段缺失时展示空态或可恢复状态，不拼接本地 mock 商品。
- 补充 mapper、页面和 BFF service 测试。

不包含：

- 不实现秒杀下单、秒杀资格校验、支付或倒计时服务端校准。
- 不实现推广商品收藏接口。
- 不新增推广商品分类接口；`categoryId2/categoryId3` 仅预留透传。
- 不改 Java 后端。

## 责任边界

`hybird-meumall`：

- 负责 BFF 调用、字段映射、页面展示、空态、跳转商品详情和测试。

Java 后端：

- 提供 `/p/app/home/seckillProds` 和 `/p/distribution/prod/productPage`。
- 保证测试环境接口、鉴权和响应字段与 Apifox released 契约一致。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-seckill-promotion-products-real-api-contract.md`
- 是否向后兼容：是，H5 新增消费方，不改变 Java 接口。
- 是否需要迁移：否。
- 是否需要灰度：建议随 H5 常规灰度。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0624-001-h5-seckill-promotion-products-real-api.md`
- 需要确认的角色：后端、测试。
- 当前确认状态：Apifox released，真实 token 联调待验证。

## 对方责任

后端：

- 确认两个接口在测试环境可用，且需要 `mallToken` 鉴权。
- 确认秒杀商品点击普通商品详情 `/product/<prodId>` 是否满足当前联调口径。
- 确认推广商品排序枚举和分类 ID 口径。

原生 App：

- 无新增 Bridge；沿用已有 H5 WebView 跳转和分享事件。

管理后台：

- 无本期依赖。

CI 或发布：

- 随 H5 版本常规发布。

## 联调方式

- Mock 数据位置：`hybird-meumall/src/features/seckill/mock/seckill-page-data.ts`、`hybird-meumall/src/features/promotion/mock/products.ts`
- 测试接口环境：`JAVA_API_BASE_URL=https://test.aigcpop.com/mini_h5`
- App 测试包版本：待 App 注入有效 `mallToken` 后验证。
- 管理后台测试入口：无。
- 联调步骤：打开首页 -> 点击「限时秒杀」或「推广带货」-> 验证列表真实商品、分页、商品详情跳转和分享 payload。
- H5 空数据策略：Java 返回空列表时展示页面空态；BFF 失败时不拼接本地 mock 商品。

## 实现计划

1. 建立两个 BFF service 和 route。
2. 建立页面 feature API adapter。
3. 将 `/seckill` 和 `/promotion/products` 从静态 mock 接入真实分页，并按接口空数据展示空态。
4. 更新契约、对接 brief、项目状态和验证记录。

## 验收标准

- [x] `/api/bff/seckill/products` 按 `current/size` 请求 Java `/p/app/home/seckillProds`。
- [x] `/seckill` 能展示真实秒杀商品，商品卡和秒杀按钮进入 `/product/<prodId>`。
- [x] `/api/bff/promotion/products` 按分页、搜索和排序参数请求 Java `/p/distribution/prod/productPage`。
- [x] `/promotion/products` 能展示真实推广商品价格、销量和预计佣金。
- [x] 推广按钮分享 payload 使用真实 `prodId`。
- [x] 接口失败或空数据时两个页面不白屏，且不拼接本地 mock。
- [x] 目标测试和类型检查通过。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/features/seckill/seckill.test.tsx src/features/promotion/promotion-products.test.tsx
pnpm typecheck
```

## 发布影响

- 是否需要发布：需要随 H5 后续版本发布。
- 发布项目：`hybird-meumall`
- 是否需要灰度：建议灰度。
- 回滚目标：上一版 H5 active manifest。
- smoke check：访问 `/seckill` 和 `/promotion/products`，验证真实数据、空态、商品详情跳转和分享按钮。

## 风险和阻塞

- Apifox header 示例仍写 `Bearer {{Authorization}}`，但当前 H5 Java BFF 统一按联调结果发送裸 `Authorization: <mallToken>`。
- 推广商品分类筛选需要分类 ID 来源，本期只预留 BFF 参数透传，不做分类接口。
- 秒杀购买仍走普通商品详情，秒杀交易链路后置。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-24 | ready | 创建秒杀和推广商品真实接口联调任务。 |
| 2026-06-24 | verified | 已完成 BFF、mapper、页面接入、商品详情跳转、推广分享 payload 修正、契约和验证记录。 |
| 2026-06-24 | verified | 链调阶段移除列表 mock fallback，Java 空列表展示空态。 |

## 验证记录

```bash
cd hybird-meumall
pnpm test src/features/seckill/seckill.test.tsx src/features/promotion/promotion-products.test.tsx
pnpm typecheck
pnpm lint
```

结果：

- `pnpm test ...`：通过，2 files / 13 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，0 errors，4 warnings；warning 均为既有 promotion 页面 `<img>` 规则提示，不是本次新增文件。
