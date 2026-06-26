# TASK-2026-0611-003-H5 首页真实接口对接

## 状态

verified

## 目标

将 H5 首页从静态 `homeExperienceData` 逐步接入 Apifox `喵呜商城/APP接口/喵呜达人首页接口` 模块中的真实接口，让首页首屏可以展示后端返回的 banner、分类和推荐商品数据；同时新增首页“为您推荐”更多页，用于展示“相似推荐商品”列表。首页“限时秒杀”和“推广带货”入口卡改为 H5 固定 UI，不由首页接口或后台配置控制。

## 背景

H5 首页当前已完成静态高保真页面，但最终渲染仍使用本地 mock 数据。现在开始进入具体接口联调阶段，需要先把首页接口按现有 HTTP 架构接入：页面组件不直连后端，浏览器只调 H5 BFF，BFF 通过 backend client 请求 Java 后端。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 拉取并记录 Apifox `喵呜达人首页接口` 模块接口。
- 新增/更新首页 API 契约。
- 新增 H5 BFF 首页接口。
- 新增首页 server service / mapper，将后端结构转换为 `HomeBffData`：`view` 给当前页面渲染，`modules` 保留业务模块字段，local/test 可按需返回 `debugRaw` 联调原始响应。
- 新增首页推荐商品分页 BFF：`/api/bff/home/recommend-products?current=<current>&size=<size>`，请求 Java `/p/app/home/recommendProds`，用于首页“为您推荐”商品区；首页下滑到底部时继续加载下一页并追加商品。
- 新增“相似推荐商品”页面 `/home/recommend-products`，从首页“为您推荐”右侧“更多”进入，页面结构参考 `/search`，包含导航栏、搜索栏、筛选条件、商品列表和下拉加载更多。
- 新增“相似推荐商品”分页 BFF：`/api/bff/home/for-you-products?current=<current>&size=<size>`，请求 Java `/p/app/home/forYouProds`，用于新页面列表。
- 首页固定展示“限时秒杀”和“推广带货”入口，分别跳转 `/seckill` 和 `/promotion/products`；入口显隐不依赖首页聚合接口或配置模块。
- 首页客户端通过 feature API adapter 请求 BFF。
- 接口失败时展示错误/空业务态，不保留本地静态业务数据 fallback。
- 补充测试和验证记录。

不包含：

- 不实现复杂筛选后的服务端分页联动；当前筛选仍为本地已加载商品内排序/过滤。
- 不接搜索页真实接口。
- 不接商品详情真实接口。
- 不改 Java 后端。
- 不处理真实登录态刷新。

## 责任边界

H5：

- 负责调用 BFF、转换首页展示模型，接口失败展示错误/空业务态。
- 负责 requestId 和客户端上下文透传。
- 负责空数据和接口失败时不白屏。

Java 后端：

- 提供 Apifox 已发布的首页接口。
- 保证响应字段与契约一致。
- 后续按 HTTP 架构记录 `x-request-id` 和客户端上下文。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-home-real-api-contract.md`
- 是否向后兼容：是，H5 新增消费方，不改变后端接口。
- 是否需要迁移：否。
- 是否需要灰度：建议随 H5 常规灰度。

## 对接说明

- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0611-003-h5-home-real-api.md`
- 需要确认角色：Java 后端、测试。
- 当前确认状态：Apifox 接口为 released，真实环境 base URL 和登录态仍待联调确认。

## 对方责任

Java 后端：

- 确认 `/p/app/home/index`、`/p/app/home/recommendProds`、`/p/app/home/forYouProds` 的测试环境可用。
- 已确认测试环境接口无 token 时返回 `A00004 Unauthorized`，H5 BFF 需要 `mallToken` 鉴权。
- 确认 banner `jumpType` 的跳转语义。

测试：

- 验证接口成功、接口失败错误态、空列表、骨架屏和图片加载。

## Mock 和联调方式

- Mock：正式联调阶段不使用 `homeExperienceData` 补齐首页业务数据。
- 联调：H5 BFF 调 Java 后端，环境变量 `JAVA_API_BASE_URL` 指向测试后端。
- H5 失败态：BFF 请求失败或字段异常时，首页展示错误/空业务态；banner、分类和推荐商品均以 Java 返回为准，不使用本地业务 mock。首页“限时秒杀/推广带货”是固定 UI 入口，不属于业务数据 fallback。

## 验收标准

- [x] 首页 BFF route 只请求 Java 首页聚合接口，避免分页接口拖慢首屏。
- [x] 首页推荐分页 BFF route 能按 `current/size` 请求 Java `/p/app/home/recommendProds`。
- [x] 首页“为您推荐”区下滑到底部时按 `current + 1` 加载更多商品，并在加载到第 2 页后展示“顶部”按钮。
- [x] “相似推荐商品”分页 BFF route 能按 `current/size` 请求 Java `/p/app/home/forYouProds`。
- [x] mapper 能把后端 banner、分类和商品转换成 `HomeBffData` / `HomeRecommendProductsBffData` / `HomeForYouProductsBffData`，并在首页固定保留“限时秒杀/推广带货”入口。
- [x] 首页分类区按最新 Apifox 口径展示：直接使用 `/p/app/home/index` 的 `navList`，不再拼接 `hotCategory + categoryTop8`。
- [x] banner 或分类数据为空时展示骨架屏，不展示本地 mock banner 或 mock 分类。
- [x] `modules` 保留 `navList`、历史兼容字段、`seckillModule.products`、优惠券、佣金、多规格等后续扩展字段。
- [x] 首页浏览器端通过 feature API adapter 请求 `/api/bff/home`。
- [x] 接口失败时首页不白屏，展示错误/空业务态，不回落本地静态业务数据。
- [x] 推荐商品能展示真实商品图、标题、价格、销量和活动标签。
- [x] 首页“为您推荐”右侧“更多”跳转新页面 `/home/recommend-products`。
- [x] 新页面标题为“相似推荐商品”，包含搜索栏、筛选条件和商品列表。
- [x] 新页面滚动到底部时按 `current + 1` 调用 `/api/bff/home/for-you-products` 并追加商品。
- [x] Java 首页聚合不返回活动/秒杀配置时，首页仍展示固定“限时秒杀”和“推广带货”入口。
- [x] 目标测试、类型检查和 lint 通过。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/features/home/home-real-api.test.ts src/features/home/home.test.tsx src/features/home/home-recommend-products.test.tsx
pnpm typecheck
pnpm lint
```

## 发布影响

- 是否需要发布：需要随 H5 后续版本发布。
- 发布项目：`hybird-meumall`
- 是否需要灰度：建议灰度。
- 回滚目标：上一版 H5 active manifest。
- smoke check：访问首页，确认接口成功时展示真实数据，接口失败时展示错误态且不展示本地 mock 数据。

## 风险和阻塞

- `JAVA_API_BASE_URL` 已更新为当前测试域名 `https://test.aigcpop.com/mini_h5`。
- Apifox 未声明鉴权方案，但测试环境实际返回 `A00004 Unauthorized`，本任务按需要 `mallToken` 处理。
- 商品详情、搜索页、活动页真实路由尚未全部接入，首页点击仍可能进入现有静态页。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | ready | 基于 Apifox released 接口创建首页真实接口对接任务。 |
| 2026-06-11 | verified | 已完成 BFF route、mapper、客户端接入、fallback、文档和验证；真实数据展示仍需 App 注入有效 `mallToken` 后联调。 |
| 2026-06-11 | verified | 新增 `JAVA_OSS_ASSET_BASE_URL`，首页 mapper 对 Java 返回的相对图片路径拼接 OSS base URL。 |
| 2026-06-11 | verified | 修正首页商品接口分工：首页商品区使用 `/p/app/home/recommendProds`，新增 `/home/recommend-products` 相似推荐商品页使用 `/p/app/home/forYouProds`。 |
| 2026-06-11 | verified | 相似推荐商品页新增下拉加载更多，底部进入视口后自动加载下一页并追加商品。 |
| 2026-06-11 | verified | 首页“为您推荐”区新增下滑加载更多，并在加载到第 2 页后显示回到顶部按钮。 |
| 2026-06-24 | verified | 按新一轮联调口径修正首页分类映射：`hotCategory` 放首页分类第一位，`categoryTop8` 从第二位起补充，分类入口最多 10 个。 |
| 2026-06-25 | verified | 按正式联调规则移除首页本地业务 mock fallback；接口失败展示错误态，缺失 banner/分类/商品不再用 `homeExperienceData` 补齐。 |
| 2026-06-25 | verified | 按 Apifox 最新首页聚合口径修正分类来源：`navList` 直接驱动首页类目；banner/类目为空时展示骨架屏。 |
| 2026-06-25 | verified | 首页“限时秒杀”和“推广带货”入口改为 H5 固定 UI，不再由首页聚合接口或配置模块控制。 |

## 验证记录

```bash
cd hybird-meumall
pnpm test src/features/home/home-real-api.test.ts src/features/home/home.test.tsx src/features/home/home-recommend-products.test.tsx src/lib/http/h5-client.test.ts src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts
pnpm typecheck
pnpm lint
```

结果：

- `pnpm test ...`：通过，6 files / 42 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- 直接请求旧 Apifox Java 测试环境曾返回 `A00004 Unauthorized`，确认接口需要登录态。
- 当前 Java 联调域名已更新为 `https://test.aigcpop.com/mini_h5`；需要按 `config/env/h5.local.env` 重启并注入 `mallToken` 后验证真实数据。
- `JAVA_OSS_ASSET_BASE_URL` 已配置为 `https://awu-mall-file.oss-cn-guangzhou.aliyuncs.com/`，相对图片路径拼接已由 `home-real-api.test.ts` 覆盖。

2026-06-24 补充验证：

```bash
cd hybird-meumall
pnpm test src/features/home/home-real-api.test.ts
pnpm typecheck
```

结果：

- `pnpm test src/features/home/home-real-api.test.ts`：通过，1 file / 12 tests。
- `pnpm typecheck`：通过。

2026-06-25 补充验证：

```bash
cd hybird-meumall
pnpm exec vitest run src/features/home/home-real-api.test.ts src/features/home/home.test.tsx
pnpm exec vitest run src/features/home
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
pnpm run ai:check-docs-sync --strict
```

结果：

- 首页定向测试：2 files / 27 tests 通过。
- 首页测试集：4 files / 35 tests 通过。
- 固定活动入口补充验证：`pnpm exec vitest run src/features/home/home-real-api.test.ts src/features/home/home.test.tsx` 通过，2 files / 27 tests。
- 全量测试：56 files / 298 tests 通过。
- TypeScript：通过。
- ESLint：0 errors，4 warnings；warning 为 promotion 模块既有 `<img>` 提示。
- Next build：通过。
- 文档同步检查：通过，共 15 个文件。
- 飞书页面清单同步：本地事实源已更新；user 身份缺少文档授权，bot 身份缺少目标文档编辑权限，飞书 revision 仍为 12。
