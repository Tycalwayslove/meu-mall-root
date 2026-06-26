# 对接说明：H5 搜索结果商品真实接口

## 基本信息

- 日期：2026-06-25
- 状态：ready
- 关联任务：`.ai-workspace/tasks/TASK-2026-0625-002-h5-search-products-real-api.md`
- 关联契约：`.ai-workspace/contracts/api/h5-search-products-contract.md`
- 涉及项目：`hybird-meumall`

## 背景

搜索首页热门词、搜索热榜和分类页已接真实接口，但搜索结果页商品仍来自本地 mock。当前需要将首页分类入口、搜索框、热门搜索和搜索历史统一接到真实商品分页接口。

## 入口规则

| 入口 | H5 URL | 商品查询范围 |
| --- | --- | --- |
| 首页商品分类、分类页 leaf | `/search?categoryId=<categoryId>` | 默认只查该分类；后续分类筛选只查当前类目的子分类。 |
| 搜索框提交 | `/search?q=<keyword>` | 不带 `categoryId`，搜索全部类目。 |
| 热门搜索 | `/search?q=<keyword>` | 不带 `categoryId`，搜索全部类目。 |
| 搜索历史 | `/search?q=<keyword>` | 不带 `categoryId`，搜索全部类目。 |
| 分类内搜索 | `/search?q=<keyword>&categoryId=<categoryId>` | 在当前分类 scope 内搜索。 |

## 调用链路

```text
/search?q=<keyword> 或 /search?categoryId=<id>
  -> H5 client /api/bff/search/products
  -> Java /p/app/prod/page?current=<n>&size=<n>&orderBy=<orderBy>&keyword=<keyword>&categoryId=<categoryId>
  -> Java /category/list?parentId=<parentId>&shopId=0
```

## 参数规则

| 参数 | 来源 | 说明 |
| --- | --- | --- |
| `keyword` | 搜索框、热门搜索、搜索历史 | 有值才传；分类入口无搜索词时不传。 |
| `categoryId` | 首页分类入口或结果页分类筛选 | 有值才传；无分类入口时不传，表示全局搜索。 |
| `scopeCategoryId` | 首页分类入口 | 用于初始化分类筛选范围。 |
| `categoryOptionsParentId` | 点击分类筛选项 | 用于继续请求当前类目的子孙类目，逐级追加展示；搜索筛选分类接口默认不传 `depth`。 |
| `orderBy` | 销量/价格筛选 | 只保留销量和价格；两者互斥，同一条件点击切换升降序。 |

## 验收口径

- 首页分类进入 `/search?categoryId=<id>` 后可以在无关键词时展示商品结果。
- 分类入口后的分类筛选只展示该分类的子分类，不展示全局一级类目。
- 分类筛选点击后逐级展示子孙类目；BFF 递归保留 Java 返回项中的 `children/categories` 树，H5 优先直接展示已返回的子孙类目；无子类目时不展示兜底数据。
- 分类筛选请求 Java `/category/list` 时不传 `depth`，由后端返回当前 `parentId` 下所有子孙类目。
- 不带分类入口时，分类筛选请求 Java `/category/list?parentId=0&shopId=0` 获取全局分类树。
- 筛选区 UI 使用“综合筛选”壳层、当前筛选摘要、销量/价格分段按钮和分类层级标题；分类面板展开时有蒙层并锁定页面滚动。
- 点击分类项只更新待确认选中态，不立即请求接口；点击“确认”后应用分类并请求 BFF，点击“重置”后清空分类并重新请求当前 scope。
- 排序/分类切换只更新页面 state 与 BFF 请求，不修改 URL。
- 搜索结果页内再次搜索或清空关键词只更新当前页面 state，并用 `history.replaceState` 同步 URL；不得重建页面导致排序/分类筛选重置。
- 搜索输入框只展示 H5 自定义清空按钮，不使用浏览器原生 `type=search` 清除按钮。
- 排序栏只展示“销量”和“价格”两个排序条件，后方展示上下箭头，当前排序方向高亮。
- 搜索框、热门搜索、搜索历史进入 `/search?q=<keyword>` 时不传 `categoryId`。
- 商品列表为空时展示通用空态，不展示 mock 商品。
- 商品或分类接口失败时展示错误态和重试入口，不展示本地 mock 商品或分类。
- 商品结果有下一页时，底部进入视口自动加载下一页并追加商品，不再要求用户点击“加载更多”。
- 商品点击进入详情时使用 replace 式离开搜索页；原生返回或滑动返回回到搜索页之前的首页。

## 对后端/原生影响

- 不需要 Java 新增接口，复用旧 App 商品接口和分类接口。
- 不涉及 Native Bridge 协议变更。
- 原生只需按既有 H5 URL 打开搜索页；首页分类入口要确保 URL 带 `categoryId`。

## 变更记录

| 日期 | 角色 | 状态 | 说明 |
| --- | --- | --- | --- |
| 2026-06-25 | H5 | 已更新 | 新增搜索结果商品 BFF，按 `keyword/orderBy/categoryId` 联调 Java `/p/app/prod/page`。 |
| 2026-06-25 | H5 | 已更新 | 分类筛选统一改用分类接口目录 `GET /category/list`；搜索结果页接口失败不展示本地 mock 商品或分类。 |
| 2026-06-25 | H5 | 已更新 | 搜索结果页分类筛选接口默认不传 `depth`，获取当前类目的所有子孙类目。 |
| 2026-06-25 | H5 | 已更新 | 分类筛选递归消费 Java `children/categories` 子孙树，筛选 UI 优化为摘要 + 分段排序 + 分级类目面板。 |
| 2026-06-25 | H5 | 已更新 | 分类面板新增蒙层和滚动锁定；分类项点击不再立即请求，确认/重置才应用筛选并请求 BFF。 |
| 2026-06-25 | H5 | 已更新 | 无分类入口时分类查询改为 `parentId=0`；搜索结果分页改为底部哨兵自动加载下一页。 |
| 2026-06-25 | H5 | 已更新 | 搜索结果页内再次搜索或清空关键词不再重置排序/分类状态；输入框去掉浏览器原生 search 清除按钮。 |
