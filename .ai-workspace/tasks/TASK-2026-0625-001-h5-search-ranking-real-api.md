# TASK-2026-0625-001 H5 搜索热榜真实接口联调

## 状态

verified

## 目标

将 `hybird-meumall` 搜索页下方热榜标签和对应商品列表从本地 mock 改为真实 Java 商品榜单接口，覆盖 `/search` 首页热榜模块和 `/search/ranking` 完整热榜页。

## 背景

当前搜索页热门搜索词已接真实 BFF，但热榜标签和商品列表仍来自 `searchPageData` 静态数据。用户要求基于 Apifox“商品榜单接口”目录中的“顶部标签”和“商品列表”两个接口完成联调。

Apifox 查询来源：

- Project ID：`4403987`
- Branch：`main`
- 接口目录：`喵呜商城/APP接口/商品榜单接口`

## 范围

包含：

- 新增 H5 BFF `/api/bff/search/ranking`。
- BFF 聚合 Java `GET /search/rankTabs` 和 `GET /search/rank/{rankType}`。
- 搜索首页热榜模块首屏 loading，成功后以 `categoryBoardCount=4` 拉取真实标签，商品列表只展示前三条，空数据展示空态，失败展示错误态。
- 完整热榜页 `/search/ranking` 使用同一套真实 BFF 和切换逻辑，标签接口不传 `categoryBoardCount`，商品列表按接口返回完整展示。
- 从 `/search` 进入商品详情或完整榜单时使用 replace 式跳转，避免原生返回按钮或 App 滑动返回停回搜索页。
- 商品卡点击进入 `/product/<prodId>`。
- 图片 URL 按 Java OSS base URL 归一。
- 测试覆盖 mapper、BFF path、页面不再渲染热榜 mock 商品。

不包含：

- 搜索结果页商品搜索接口。
- 收藏、加购、分享、支付。
- 后端接口新增或字段调整。

## 契约

- `.ai-workspace/contracts/api/h5-search-ranking-contract.md`

## 验收标准

- [x] `/api/bff/search/ranking` 请求 Java `/search/rankTabs` 和 `/search/rank/{rankType}`。
- [x] 标签映射 `rankType/rankName/categoryId`。
- [x] 商品映射 `prodId/prodName/pic/displayPrice/price/oriPrice/soldNum/activityType/isHot/isRecommend`。
- [x] `/search` 热榜区域不再首屏渲染本地 mock 热榜商品。
- [x] `/search` 热榜标签请求 `categoryBoardCount=4`，商品列表截取前三条。
- [x] `/search/ranking` 完整热榜不传 `categoryBoardCount`，商品列表不截断。
- [x] `/search` 点击“查看完整榜单”携带当前标签 `rankType/categoryId`，进入完整榜单后默认展示对应标签。
- [x] `/search/ranking` 页内切换标签不操作路由，只更新 state 并请求 BFF，避免污染返回栈。
- [x] 搜索页热榜空商品复用通用空态，但空态容器背景透明，避免破坏绿色背景。
- [x] `/search` 离开到商品详情或完整榜单时替换当前 history，返回链路回到搜索页之前的首页。
- [x] `/search/ranking` 完整热榜页成功、loading、empty、error 状态可用。
- [x] `pnpm test`、`pnpm typecheck`、`pnpm lint`、`pnpm run build` 通过或记录限制。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/search/search-ranking-real-api.test.ts src/features/search/search.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
pnpm run ai:check-docs-sync --strict
```

## 发布影响

- 影响 H5 `/search` 和 `/search/ranking` 页面展示。
- 不影响原生 App Bridge。
- 不改变 manifest schema。

## 风险

- Java 商品榜单接口若返回空标签或空商品，H5 显示空态，不回退本地 mock。
- 真实图片依赖 Java 返回 `pic` 和 `JAVA_OSS_ASSET_BASE_URL`。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-25 | ready | 根据 Apifox 商品榜单接口创建工作项，准备实现 H5 BFF 和页面联调。 |
| 2026-06-25 | verified | 已接入 `/api/bff/search/ranking`，搜索页和完整热榜页使用真实标签/商品；全量测试、类型、lint、构建和本地 smoke 通过。 |
| 2026-06-25 | verified | 本地页面清单已更新；飞书页面清单同步因 user token 缺失和 Bot 文档权限不足阻塞，已记录在测试报告。 |
| 2026-06-25 | verified | 按联调反馈细化热榜参数：`/search` 传 `categoryBoardCount=4` 并截前三条商品，`/search/ranking` 不传该参数并展示完整商品；首页热榜区铺满剩余空间展示背景色。 |
| 2026-06-25 | verified | 搜索页离开跳转改为 replace：商品详情、搜索结果商品和完整榜单入口不再把 `/search` 留在 WebView history 栈里。 |
| 2026-06-25 | verified | 搜索页“查看完整榜单”会携带当前标签 `rankType/categoryId`；完整榜单页切换标签不改 URL；搜索热榜空态容器改为透明背景。 |
