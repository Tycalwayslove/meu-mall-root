# TASK-2026-0625-002 H5 搜索结果商品真实接口联调

## 状态

verified

## 目标

将 `hybird-meumall` 搜索结果页从本地 mock 商品切换到 Java 商品接口，支持首页分类入口 `categoryId`、搜索框关键词、热门搜索和搜索历史入口。

## 背景

搜索页热门词和热榜已接真实接口，但 `/search?q=<keyword>` 和 `/search?categoryId=<id>` 的商品结果仍来自本地 mock。用户要求基于 Apifox“商品接口”目录的分类查询商品接口完成搜索结果页商品对接。

Apifox 查询来源：

- Project ID：`4403987`
- Branch：`main`
- 接口目录：`喵呜商城/APP接口/商品接口`
- Java 接口：`GET /p/app/prod/page`

## 范围

包含：

- 新增 H5 BFF `/api/bff/search/products`。
- BFF 调 Java `GET /p/app/prod/page`，支持 `current`、`size`、`orderBy`、`keyword`、`categoryId`。
- 首页分类进入 `/search?categoryId=<id>` 时，不需要关键词也进入搜索结果页。
- 带 `categoryId` 的搜索结果页会用该 ID 作为分类 scope；后续分类筛选查询当前类目的所有子孙类目。
- 不带 `categoryId` 的搜索结果页按全局搜索处理，可查询全部类目。
- 搜索结果页销量、价格、分类筛选改为请求真实 BFF，不再做本地排序/拼接。
- 不带 `categoryId` 的搜索结果页查询分类筛选项时，Java `/category/list` 固定传 `parentId=0`。
- 排序状态只保留销量和价格两个互斥条件，并在按钮后展示升序/降序箭头。
- 分类筛选递归保留 Java `children/categories` 子孙树，点击后逐级展示所有子孙类目，当前类目无子类目时不展示兜底数据。
- 筛选 UI 优化为“综合筛选”壳层、当前筛选摘要、销量/价格分段按钮和分类层级标题；切换排序或分类不修改 URL。
- 分类面板展开时显示蒙层并锁定页面滚动；分类项点击只更新待确认状态，确认后才请求接口，重置清空分类并重新请求。
- Java 返回空商品时使用设计系统通用 `EmptyState`。
- 搜索结果有下一页时，底部进入视口自动请求下一页并追加商品，不再展示手动“加载更多”按钮。
- 搜索结果页内再次搜索或清空关键词时保留当前排序和分类筛选状态，不重新挂载结果页。
- 搜索输入框只保留一个自定义清空按钮，避免浏览器原生清除按钮重复展示。
- 搜索结果商品点击进入商品详情仍使用 replace 式离开搜索页，避免 App 返回/滑动返回停回搜索页。

不包含：

- 搜索建议、联想词。
- 收藏、加购、分享、支付。
- 分类树全量重构。
- 后端接口新增或字段调整。

## 契约

- `.ai-workspace/contracts/api/h5-search-products-contract.md`

## 验收标准

- [x] `/api/bff/search/products` 请求 Java `/p/app/prod/page`。
- [x] `orderBy` 支持 `+price`、`-price`、`-soldNum` 等后端白名单字段。
- [x] `keyword` 只在有搜索词时传给 Java。
- [x] `categoryId` 只在分类入口或分类筛选时传给 Java。
- [x] 分类入口 `categoryId` 存在时，即使 `q` 为空也展示搜索结果页。
- [x] 分类入口存在 scope 时，分类筛选选项来自 `/category/list?parentId=<scopeCategoryId>&shopId=0`，默认不传 `depth`。
- [x] 无 scope 的全局搜索分类筛选来自 `/category/list?parentId=0&shopId=0`；点击分类后继续以当前类目 ID 作为 `parentId` 获取子孙类目。
- [x] Java 分类响应中的 `children/categories` 递归映射到 H5 `view.categories.children`，H5 可直接展示所有子孙类目。
- [x] 分类面板展开时有蒙层和滚动锁定；确认/重置按钮控制何时应用分类请求。
- [x] 商品为空时使用通用 `EmptyState`，不拼接本地 mock 商品。
- [x] 搜索结果页首屏不渲染本地 mock 商品或分类；接口 500/401/业务失败时展示错误态，不回退 mock。
- [x] 搜索结果商品图、价格、销量和活动标签由 Java `ProductCardVO` 映射。
- [x] 搜索结果分页不再展示“加载更多”按钮，底部哨兵进入视口后自动加载 `current + 1`。
- [x] 搜索结果页提交新关键词或清空关键词时不重置排序和分类筛选 state。
- [x] 搜索输入框不再使用 `type=search`，避免出现两个清空图标。
- [x] `pnpm test`、`pnpm typecheck`、`pnpm lint`、`pnpm run build` 通过或记录限制。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/search/search-products-real-api.test.ts src/features/search/search.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
pnpm run ai:check-docs-sync --strict
```

## 发布影响

- 影响 H5 `/search` 搜索结果页和分类结果页。
- 不影响原生 App Bridge。
- 不改变 manifest schema。

## 风险

- Java `/p/app/prod/page` 若返回空商品，H5 直接展示空态，不使用本地 mock 兜底。
- 分类 scope 依赖首页/分类入口传入正确 `categoryId`。
- 真实图片依赖 Java 返回 `pic` 和 `JAVA_OSS_ASSET_BASE_URL`。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-25 | ready | 根据 Apifox 商品接口“分页查询商品”创建工作项，准备实现搜索结果商品 BFF 和页面联调。 |
| 2026-06-25 | verified | 已接入 `/api/bff/search/products`，搜索结果页按 `keyword/orderBy/categoryId` 请求真实商品；分类入口 scope 子分类逻辑完成；目标测试和类型检查通过。 |
| 2026-06-25 | verified | 全量测试、lint、构建和文档同步检查通过；飞书页面清单同步因 user token 缺失和 Bot 文档权限不足阻塞，已记录在测试报告。 |
| 2026-06-25 | verified | 按交互反馈整理排序和分类筛选：排序只保留销量/价格双向互斥，分类筛选支持逐级展开子孙类目；全量验证通过，飞书同步仍被 Bot 文档权限阻塞。 |
| 2026-06-25 | verified | 按正式联调规则移除搜索结果页 mock 首屏兜底；分类筛选统一改用 Apifox 分类接口目录 `GET /category/list`。 |
| 2026-06-25 | verified | 搜索结果页分类筛选调用 `/category/list` 时默认不传 `depth`，由后端返回当前类目的所有子孙类目。 |
| 2026-06-25 | verified | 递归保留分类接口 `children/categories` 子孙树，筛选面板优化为摘要 + 分段排序 + 分级类目标题。 |
| 2026-06-25 | verified | 分类筛选面板新增蒙层、滚动锁定、确认和重置操作；点击类目不再立即请求接口。 |
| 2026-06-25 | verified | 无分类入口时分类查询参数改为 `parentId=0`；搜索结果页分页改为滚动到底部自动加载下一页。 |
| 2026-06-25 | verified | 搜索结果页内搜索/清空关键词改为本地 state 更新，保留排序和分类筛选；输入框去掉原生 search 清除按钮。 |
