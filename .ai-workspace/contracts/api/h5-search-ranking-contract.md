# API 契约：H5 搜索热榜

## 基本信息

- 契约编号：API-2026-0625-001
- 状态：ready
- 提供方：Java 后端，H5 BFF
- 消费方：`hybird-meumall`
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0625-001-h5-search-ranking-real-api.md`
- Apifox Project：`4403987`
- Apifox Branch：`main`
- Apifox 目录：`喵呜商城/APP接口/商品榜单接口`

## H5 BFF

### `GET /api/bff/search/ranking`

Query：

| 字段 | 类型 | 必填 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| `categoryBoardCount` | number | 否 | 无 | 搜索页排行榜分类数量，透传给 Java `/search/rankTabs`；`/search` 首页传 `4`，`/search/ranking` 完整榜单页不传。 |
| `rankType` | `1 \| 2` | 否 | 第一个标签的 `rankType` 或 `1` | 榜单类型，`1=喵呜热榜`，`2=品类热榜`。 |
| `categoryId` | number/string | 否 | 无 | 品类热榜一级分类 ID。 |
| `debugRaw` | `1` | 否 | 无 | local/test 环境可返回原始 Java envelope。 |

Response：

```ts
type SearchRankingBffData = {
  view: {
    tabs: Array<{
      id: string;
      label: string;
      rankType: 1 | 2;
      categoryId?: string;
    }>;
    activeTabId: string;
    notice: string;
    products: Array<{
      id: string;
      href: string;
      title: string;
      feature: string;
      price: number;
      originalPrice: number;
      soldText: string;
      imageUrl?: string;
      badge?: { type: "seckill" | "hot" | "recommend"; label: string };
    }>;
  };
  modules: {
    rankTabs: ProdRankTabDto[];
    products: ProductCardVO[];
  };
};
```

## Java 后端依赖

### `GET /search/rankTabs`

说明：商品分类排行页顶部标签。

Query：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `categoryBoardCount` | integer | 否 | 搜索页排行榜分类数量。 |

Response data：`ProdRankTabDto[]`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `rankType` | integer | 榜单类型：`1=喵呜热榜`，`2=品类热榜`。 |
| `rankName` | string | 标签名称。 |
| `categoryId` | integer | 品类热榜对应 `grade=0` 分类 ID；喵呜热榜为空。 |

### `GET /search/rank/{rankType}`

说明：查询商品排行榜商品列表。

Path：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `rankType` | integer | 是 | 榜单类型：`1=喵呜热榜`，`2=品类热榜`。 |

Query：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `categoryId` | integer | 否 | 品类热榜时传入一级分类 ID。 |

Response data：`ProductCardVO[]`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `prodId` | integer | 商品 ID。 |
| `prodName` | string | 商品名称。 |
| `pic` | string | 商品主图。 |
| `price` | number | 现价。 |
| `displayPrice` | number | 优惠后价格。 |
| `discountAmount` | number | 优惠金额。 |
| `oriPrice` | number | 原价/市场价。 |
| `soldNum` | integer | 已售数量。 |
| `activityType` | integer | 活动类型：`0=普通商品`，`1=秒杀`。 |
| `isHot` | boolean | 是否热销。 |
| `isRecommend` | boolean | 是否推荐。 |

## H5 渲染规则

- 首屏展示热榜骨架，不展示本地 mock 商品。
- 接口成功后只渲染真实标签和商品。
- `/search` 首页热榜请求 `categoryBoardCount=4`，商品列表只展示前三条。
- `/search/ranking` 完整榜单页不传 `categoryBoardCount`，商品列表按 Java 返回正常展示，不做三条截断。
- `/search` 离开到完整榜单、热榜商品详情或搜索结果商品详情时使用 replace 式跳转，替换当前搜索 history；App 返回按钮或滑动返回应回到搜索页之前的首页。
- `/search` 点击“查看完整榜单”时必须携带当前标签参数：喵呜热榜为 `/search/ranking?rankType=1`，品类热榜为 `/search/ranking?rankType=2&categoryId=<categoryId>`。
- `/search/ranking` 会读取 URL 上的 `rankType/categoryId` 作为初始标签和首个商品请求；进入页面后切换标签只更新组件 state 并请求 BFF，不调用 router、不更新 query、不追加 history。
- 标签为空或商品为空时展示空态。
- 搜索页热榜区域背景为绿色渐变，商品为空时复用通用 `EmptyState`，但外层空态容器背景必须透明，不能使用白底卡片。
- 接口失败时展示错误态和重试入口。
- 图片相对路径通过 `JAVA_OSS_ASSET_BASE_URL` 拼接；完整 `http(s)` URL 原样使用。
- Java / mall 出站请求统一携带 `source: 1`，Authorization 使用 `mallToken`。

## 验证

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/search/search-ranking-real-api.test.ts src/features/search/search.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
```
