# API 契约：H5 搜索结果商品

## 基本信息

- 契约编号：API-2026-0625-002
- 状态：ready
- 提供方：Java 后端，H5 BFF
- 消费方：`hybird-meumall`
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0625-002-h5-search-products-real-api.md`
- Apifox Project：`4403987`
- Apifox Branch：`main`
- Apifox 目录：`喵呜商城/APP接口/商品接口`

## H5 BFF

### `GET /api/bff/search/products`

Query：

| 字段 | 类型 | 必填 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | number | 否 | `1` | 页码。 |
| `size` | number | 否 | `10` | 每页条数。 |
| `orderBy` | string | 否 | 无 | 排序，格式为 `+field` 或 `-field`，H5 只透传 `soldNum`、`price`、`createTime`。 |
| `keyword` | string | 否 | 无 | 搜索关键词。 |
| `categoryId` | number/string | 否 | 无 | 当前商品分类筛选 ID。 |
| `scopeCategoryId` | number/string | 否 | 无 | 分类入口 scope；存在时分类筛选只展示其子分类。 |
| `categoryOptionsParentId` | number/string | 否 | 无 | 当前需要展开子分类的父级类目 ID；点击分类项后传当前类目，用于继续加载子孙类目。 |
| `debugRaw` | `1` | 否 | 无 | local/test 环境可返回原始 Java envelope。 |

Response：

```ts
type SearchProductCategoryOption = {
  id: string;
  label: string;
  children?: SearchProductCategoryOption[];
};

type SearchProductsBffData = {
  view: {
    keyword: string;
    activeCategoryId?: string;
    categories: SearchProductCategoryOption[];
    products: Array<{
      id: string;
      href: string;
      title: string;
      feature: string;
      price: number;
      originalPrice: number;
      soldText: string;
      tag: "热卖" | "推荐";
      imageUrl?: string;
      badge?: { type: "seckill" | "hot" | "recommend"; label: string };
    }>;
  };
  page: {
    current: number;
    size: number;
    hasMore: boolean;
    pages?: number;
    total?: number;
  };
  modules: {
    productPage: IPageProductCardVO;
    products: ProductCardVO[];
    categories: CategoryVO[];
  };
};
```

## Java 后端依赖

### `GET /p/app/prod/page`

说明：自购商城 App 分页查询商品。

Query：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `current` | integer | 否 | 页码，默认 `1`。 |
| `size` | integer | 否 | 每页条数，默认 `10`。 |
| `orderBy` | string | 否 | 排序条件。格式 `+field` 升序、`-field` 降序，多个用逗号隔开；字段白名单：`soldNum`、`price`、`createTime`。 |
| `keyword` | string | 否 | 搜索关键词。 |
| `categoryId` | integer | 否 | 商品分类筛选 ID。 |

Response data：`IPageProductCardVO`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `records` | `ProductCardVO[]` | 商品卡片列表。 |
| `total` | number | 总数。 |
| `size` | number | 每页条数。 |
| `current` | number | 当前页。 |
| `pages` | number | 总页数。 |

`ProductCardVO` 字段同搜索热榜契约：`prodId`、`prodName`、`pic`、`price`、`displayPrice`、`discountAmount`、`oriPrice`、`soldNum`、`activityType`、`isHot`、`isRecommend`。

### 分类筛选依赖

| 场景 | Java 接口 | 说明 |
| --- | --- | --- |
| 带分类入口 scope | `GET /category/list?parentId=<scopeCategoryId>&shopId=0` | 不传 `depth`，由后端返回当前类目的所有子孙类目，避免 H5 分层请求遗漏。 |
| 不带分类入口 scope | `GET /category/list?parentId=0&shopId=0` | 不传 `depth`，返回全局分类树，允许全局搜索筛选。 |
| 点击分类筛选项 | `GET /category/list?parentId=<clickedCategoryId>&shopId=0` | 不传 `depth`，继续获取当前分类的全部子孙类目。 |

## H5 渲染规则

- `/search?q=<keyword>`：不传 `categoryId`，全局搜索商品；分类筛选展示一级分类。
- `/search?categoryId=<id>`：无关键词也进入结果页；默认按该分类查询商品；分类筛选展示该分类子分类。
- `/search?q=<keyword>&categoryId=<id>`：在分类 scope 内搜索关键词。
- 排序只保留“销量”和“价格”两个条件；两者互斥，同一条件重复点击在升序/降序之间切换。
- 销量降序映射 `orderBy=-soldNum`，销量升序映射 `orderBy=+soldNum`。
- 价格从低到高映射 `orderBy=+price`，价格从高到低映射 `orderBy=-price`。
- 分类筛选使用级联展示：搜索筛选场景调用 `/category/list` 时默认不传 `depth`，后端返回所有子孙类目；BFF 必须递归保留 Java 返回项中的 `children/categories` 树，H5 选择某个类目后优先直接展示该节点 `children` 中的所有子孙层级，再按需要继续请求当前类目。无子级时停留在当前层级，不使用本地兜底。
- 筛选 UI 使用“综合筛选”壳层、销量/价格分段按钮和分类层级标题；分类面板展开时展示蒙层并锁定页面滚动。
- 分类点击只更新待确认选中态，不立即请求商品或分类接口；点击“确认”后才应用分类并请求 BFF；点击“重置”会清空已应用分类并重新请求当前 scope 下商品与分类。
- 排序和分类切换只更新页面 state 与 BFF 请求，不修改 URL。
- 搜索结果页内再次提交关键词或清空关键词时，只更新本页关键词 state，并用 `history.replaceState` 同步 URL；不得整页 replace/remount，避免重置当前排序和分类筛选状态。
- 搜索输入框使用普通文本输入 + H5 自定义清空按钮，避免浏览器原生 `type=search` 清除按钮和自定义按钮重复出现。
- 商品为空时展示通用 `EmptyState`，不拼接本地 mock 商品。
- 搜索结果页首屏只展示骨架屏；接口 500、401 或业务失败时展示错误态和重试入口，不回退本地 mock 商品或分类。
- 搜索结果页有下一页且当前已有商品时，底部哨兵进入视口后自动请求 `current + 1` 并追加商品，不展示“加载更多”按钮。
- 搜索结果商品点击商品详情使用 replace 式跳转，避免 App 返回/滑动返回停回搜索页。
- Java / mall 出站请求统一携带 `source: 1`，Authorization 使用 `mallToken`。

## 验证

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/search/search-products-real-api.test.ts src/features/search/search.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
```
