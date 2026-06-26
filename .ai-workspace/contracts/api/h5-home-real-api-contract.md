# H5 首页真实接口契约

## 契约名称

H5 首页真实接口契约

## 提供方

Java 后端，Apifox 项目 `4403987`。

## 消费方

`hybird-meumall` H5 BFF。

## Apifox 来源

目录：

```text
喵呜商城/APP接口/喵呜达人首页接口
folderId: 87570137
```

接口：

| 名称 | Method | Path | Endpoint ID | 状态 |
| --- | --- | --- | --- | --- |
| 首页聚合数据 | GET | `/p/app/home/index` | `468539323` | released |
| 首页推荐商品分页 | GET | `/p/app/home/recommendProds` | `468539324` | released |
| 为您推荐商品分页 | GET | `/p/app/home/forYouProds` | `469157763` | released |

本阶段 H5 首页首屏核心接口使用：

- `/p/app/home/index`
- `/p/app/home/recommendProds?current=<current>&size=<size>`

首页“为您推荐”右侧“更多”进入独立页面，该页面分页商品使用：

- `/p/app/home/forYouProds?current=<current>&size=<size>`

也就是说，`recommendProds` 是首页首屏推荐商品流，`forYouProds` 是“相似推荐商品”更多页的商品流。两个接口都带分页参数，但消费场景不同，不能在 H5 中混用。

`/p/app/home/index` 当前 Apifox 描述已明确：

- `banners`：首页 banner，`imgType=0`，`position` 为 `0` / `1` / `null`，不含个人中心 `position=2`。
- `navList`：首页导航入口列表，包含热门商品入口、分类搜索入口和更多分类入口；H5 分类区直接按该数组展示，不再拼接 `hotCategory + categoryTop8`。
- `seckillModule`：可购秒杀池，无商品时为 `null`。
- 首页“限时秒杀”和“推广带货”入口卡是 H5 页面固定 UI，不再由首页聚合接口或后台配置控制；入口分别固定跳转 `/seckill` 和 `/promotion/products`。

## 适用环境

- H5 BFF 通过 `JAVA_API_BASE_URL` 访问 Java 后端。
- 当前 Java 测试 base URL：`https://test.aigcpop.com/mini_h5`。
- Java 图片相对路径通过 `JAVA_OSS_ASSET_BASE_URL` 拼接为完整 OSS/CDN URL。
- 当前 Java 图片 OSS base URL：`https://awu-mall-file.oss-cn-guangzhou.aliyuncs.com/`。
- 浏览器端请求 H5 BFF，不直连 Java：
  - `GET /api/bff/home`
  - `GET /api/bff/home/recommend-products?current=1&size=10`
  - `GET /api/bff/home/for-you-products?current=1&size=10`

## H5 BFF 响应格式

浏览器端不直接消费 Java VO。H5 BFF 返回稳定视图模型和业务模块并存的结构：

```ts
type HomeBffData = {
  view: HomeExperienceData;
  modules: {
    banners: AppBannerVO[];
    navList: AppHomeNavVO[];
    hotCategory: ProdRankGroupDto | null;
    categoryTop8: CategoryDto[];
    seckillModule: AppSeckillModuleVO | null;
  };
  debugRaw?: {
    homeIndex: ServerResponseEntityAppHomeVO;
  };
};
```

- `view`：给当前首页组件渲染使用，字段应尽量稳定。
- `modules`：保留首页业务模块字段，避免联调阶段过度裁剪导致页面扩展时找不到后端字段。
- `debugRaw`：仅 `GET /api/bff/home?debugRaw=1` 且 `APP_ENV=local/test` 时返回，用于对比 Java 原始响应；正式环境不返回。

首页推荐商品分页 BFF 独立返回：

```ts
type HomeRecommendProductsBffData = {
  view: {
    products: HomeProductCard[];
  };
  page: {
    current: number;
    size: number;
    total?: number;
    pages?: number;
    hasMore: boolean;
  };
  modules: {
    recommendProducts: AppRecommendProdVO[];
    recommendPage: IPageAppRecommendProdVO;
  };
  debugRaw?: {
    recommendProds: ServerResponseEntityIPageAppRecommendProdVO;
  };
};
```

“相似推荐商品”更多页分页 BFF 独立返回：

```ts
type HomeForYouProductsBffData = {
  view: {
    products: HomeProductCard[];
  };
  page: {
    current: number;
    size: number;
    total?: number;
    pages?: number;
    hasMore: boolean;
  };
  modules: {
    forYouProducts: AppRecommendProdVO[];
    forYouPage: IPageAppRecommendProdVO;
  };
  debugRaw?: {
    forYouProds: ServerResponseEntityIPageAppRecommendProdVO;
  };
};
```

`GET /api/bff/home` 不等待分页商品接口。首页页面可并发请求 `/api/bff/home` 和 `/api/bff/home/recommend-products`，推荐商品分页失败时只影响首页商品区，不拖慢或拖垮首屏核心模块。首页商品区底部进入视口时继续按 `current + 1` 请求 `/api/bff/home/recommend-products` 下一页，成功后追加商品；加载到第 2 页后展示“顶部”按钮，便于用户快速回到页面顶部。

`GET /api/bff/home/for-you-products` 只用于 `/home/recommend-products` 页面。该页面从首页“为您推荐”的“更多”入口进入，标题为“相似推荐商品”，页面结构参考 `/search`：顶部导航、搜索栏、筛选条件、商品列表。页面底部进入视口时自动按 `current + 1` 请求下一页，成功后追加商品；分页失败时保留已加载商品。

后续 Java 只调整字段名或 envelope，但页面语义不变时，优先只改 BFF mapper。页面新增展示或交互需要新字段时，优先从 `modules` 确认字段，再决定是否沉淀进 `view`。

## 版本策略

- 当前以后端 Apifox released 契约为准。
- 新增响应字段向后兼容。
- 删除字段、字段改名、字段类型变化需要更新本契约和 H5 mapper 测试。

## 鉴权

Apifox 当前未声明鉴权方案，但测试环境直接访问接口会返回：

```json
{"code":"A00004","msg":"Unauthorized","data":null,"success":false}
```

因此 H5 BFF 按强制 Java 鉴权调用。BFF 从 `mallToken` Cookie 读取 token，并转成：

```http
Authorization: <mallToken>
```

Java / mall 后端当前不接受 `Bearer` 前缀。

## 公共响应格式

首页聚合：

```ts
type ServerResponseEntityAppHomeVO = {
  code?: string;
  msg?: string;
  data?: AppHomeVO | null;
  version?: string;
  timestamp?: number;
  sign?: string;
};
```

分页商品：

```ts
type ServerResponseEntityIPageAppRecommendProdVO = {
  code?: string;
  msg?: string;
  data?: IPageAppRecommendProdVO | null;
  version?: string;
  timestamp?: number;
  sign?: string;
  success?: boolean;
};
```

成功码待后端确认。H5 mapper 第一阶段按 `data` 是否存在做容错，BFF 网络或 HTTP 错误走统一错误响应。

## 首页聚合数据

### 请求

```http
GET /p/app/home/index
```

无 query 参数。

### 响应 data

```ts
type AppHomeVO = {
  banners?: AppBannerVO[];
  navList?: AppHomeNavVO[];
  hotCategory?: ProdRankGroupDto | null;
  categoryTop8?: CategoryDto[];
  seckillModule?: AppSeckillModuleVO | null;
};
```

### Banner

```ts
type AppBannerVO = {
  imgUrl?: string;
  seq?: number;
  uploadTime?: string;
  type?: number;
  imgType?: number;
  relation?: number;
  position?: number;
  jumpType?: 1 | 2 | 3 | 4 | 5 | number;
  jumpValue?: string;
};
```

`jumpType` 约定：

| 值 | 含义 | H5 初始映射 |
| --- | --- | --- |
| `1` | H5 | `jumpValue` |
| `2` | 商品详情 | `/product/<jumpValue or relation>` |
| `3` | 活动页 | `/promotion/activities` |
| `4` | 激励活动 | `/promotion/activities` |
| `5` | 带货排行榜 | `/promotion/rank-center` |

### 热榜

```ts
type ProdRankGroupDto = {
  rankType?: number;
  rankName?: string;
  categoryId?: number;
  icon?: string;
  top3?: ProdRankProdDto[];
  [futureField: string]: unknown;
};

type ProdRankProdDto = {
  prodId?: number;
  prodName?: string;
  pic?: string;
  price?: number;
  soldNum?: number;
  rankNo?: number;
};
```

### 分类

```ts
type CategoryDto = {
  categoryId?: number;
  parentId?: number;
  categoryName?: string;
  pic?: string;
  icon?: string;
  categories?: unknown[];
  treeCategoryIds?: number[];
};
```

H5 分类入口映射：

```text
navType=1 -> /search/ranking
navType=2 -> /search?categoryId=<categoryId>
navType=3 -> /category
```

规则：

- `navList` 顺序由 Java 返回决定，H5 不再根据旧字段二次拼接或补齐。
- `navType=1` 使用 `title` 展示，图标按首页图片 URL 规则处理，点击进入完整热榜。
- `navType=2` 需要 `categoryId`，展示 `title` / `keyword`，点击进入搜索结果页并携带 `categoryId`。
- `navType=3` 展示“更多分类”等 Java 返回标题，点击进入 `/category`。
- 缺少标题、未知 `navType` 或分类入口缺少 `categoryId` 的项不进入 H5 视图模型。
- `hotCategory`、`categoryTop8` 如后端仍返回，仅保留在 `modules` 便于调试，不参与首页分类展示。

```text
/search?categoryId=<categoryId>
```

### 秒杀模块

```ts
type AppSeckillModuleVO = {
  products?: AppSeckillItemVO[];
  [futureField: string]: unknown;
};

type AppSeckillItemVO = {
  seckillId?: number;
  prodId?: number;
  prodName?: string;
  pic?: string;
  seckillPrice?: number;
  endTime?: string;
  darenPrice?: number;
  commissionAmount?: number;
};
```

H5 使用口径：

- 首页聚合接口仍保留 `seckillModule` 到 `modules`，便于后续联调查看后端秒杀池字段。
- 首页“限时秒杀”入口卡不再依赖 `seckillModule` 是否存在，也不依赖后台活动配置，H5 固定展示并跳转 `/seckill`。
- 首页“推广带货”入口卡不来自 `/p/app/home/index`，H5 固定展示并跳转 `/promotion/products`。
- `/seckill` 页面商品列表通过 `/api/bff/seckill/products` -> Java `/p/app/home/seckillProds` 独立获取。
- `/promotion/products` 页面商品列表通过 `/api/bff/promotion/products` -> Java `/p/distribution/prod/productPage` 独立获取。

## 图片 URL 处理

首页接口中的 `imgUrl`、`pic`、`icon` 图片字段按以下规则处理：

| Java 返回值 | H5 处理 |
| --- | --- |
| `https://cdn.example.com/a.png` | 原样使用。 |
| `banner/a.png` | 拼接为 `JAVA_OSS_ASSET_BASE_URL + banner/a.png`。 |
| `/banner/a.png` | 去掉开头 `/` 后拼接为 `JAVA_OSS_ASSET_BASE_URL + banner/a.png`。 |
| 空值 | 不展示对应业务图片；不得用本地 mock 图片补齐业务内容。 |

当前联调环境：

```env
JAVA_OSS_ASSET_BASE_URL=https://awu-mall-file.oss-cn-guangzhou.aliyuncs.com/
```

## 首页推荐商品分页

### 请求

```http
GET /p/app/home/recommendProds?current=1&size=10
```

Query：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | integer | 否 | `1` | 当前页 |
| `size` | integer | 否 | `10` | 每页条数 |

响应 data 与 `forYouProds` 一致，详见下方 `IPageAppRecommendProdVO` 和 `AppRecommendProdVO`。H5 将该接口映射到首页“为您推荐”商品区，BFF path 为：

```http
GET /api/bff/home/recommend-products?current=1&size=10
```

## 相似推荐商品分页

### 请求

```http
GET /p/app/home/forYouProds?current=1&size=10
```

Query：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | integer | 否 | `1` | 当前页 |
| `size` | integer | 否 | `10` | 每页条数 |

Apifox 里还有 `optimizeJoinOfCountSql`、`MAX_SIZE` 等分页框架参数，H5 不主动传。

### 响应 data

```ts
type IPageAppRecommendProdVO = {
  records?: AppRecommendProdVO[];
  total?: number;
  size?: number;
  current?: number;
  pages?: number;
};
```

### 商品

```ts
type AppRecommendProdVO = {
  prodId?: number;
  prodName?: string;
  pic?: string;
  price?: number;
  darenPrice?: number;
  couponDiscountAmount?: number;
  bestCoupon?: AppRecommendCouponVO | null;
  commissionAmount?: number;
  soldNum?: number;
  prodTag?: string;
  activityTag?: number;
  hasMultiSku?: boolean;
  [futureField: string]: unknown;
};
```

H5 初始映射：

| 后端字段 | H5 字段 |
| --- | --- |
| `prodId` | `HomeProductCard.id`、`/product/<prodId>` |
| `prodName` | `title` |
| `pic` | `imageUrl` |
| `darenPrice` 优先，否则 `price` | `price` |
| `price` | `originalPrice` |
| `soldNum` | `soldText` |
| `prodTag === "热卖"` | `badge: "热卖"` |
| `activityTag === 2` | `promoType: "seckill"` |

## H5 BFF 响应

浏览器端只消费 H5 BFF：

```http
GET /api/bff/home
GET /api/bff/home/recommend-products?current=1&size=10
GET /api/bff/home/for-you-products?current=1&size=10
```

返回：

```ts
type H5BffResult<T> =
  | { success: true; data: T; requestId: string }
  | { success: false; code: string; message: string; requestId?: string; recoverable: boolean };
```

其中 `/api/bff/home` 的 `T` 为 `HomeBffData`，`/api/bff/home/recommend-products` 的 `T` 为 `HomeRecommendProductsBffData`，`/api/bff/home/for-you-products` 的 `T` 为 `HomeForYouProductsBffData`。

## 错误格式

- Java 后端 HTTP 非 2xx：BFF 返回统一失败响应。
- Java 后端 HTTP 200 但 body 为 `success:false / code:A00004`：BFF 转为 `AUTH_FAILED`，浏览器端收到 HTTP 401。
- Java 后端 HTTP 200 但 body 为 `success:false / code:A00005`：BFF 转为 `HTTP_ERROR`，浏览器端按可恢复后端错误处理。
- 网络失败或超时：BFF 返回 `NETWORK_ERROR` 或 `TIMEOUT`。
- 字段缺失：H5 mapper 使用安全空值；banner、分类和推荐商品不得回落到本地静态业务数据。首页“限时秒杀/推广带货”是固定 UI 入口，不属于 Java 业务数据兜底。

## 兼容性要求

- H5 不依赖后端新增字段。
- 图片 URL 可以为空，对应业务图片不展示或使用组件级非业务占位；不得使用 mock 业务图。
- 推荐商品为空时，H5 不崩溃。

## 测试方式

- Mapper 单测覆盖 banner、`navList` 分类、固定活动入口和推荐商品映射；分类必须覆盖 `navList` 直接展示、不同 `navType` 路由和旧 `hotCategory/categoryTop8` 不再拼接；活动入口必须覆盖 Java 首页聚合缺少活动/秒杀数据时仍展示固定入口。
- BFF service 单测覆盖：首屏聚合接口只请求 `/p/app/home/index`；首页推荐分页接口按 `current/size` 请求 `/p/app/home/recommendProds`；“相似推荐商品”页面分页接口按 `current/size` 请求 `/p/app/home/forYouProds`。
- 首页组件测试覆盖接口成功和失败错误态；失败时不展示本地 mock 首页业务数据。
- 推荐更多入口测试覆盖首页“更多”跳转 `/home/recommend-products`。
- 首页和相似推荐商品页测试覆盖 `current + 1` 加载下一页并追加商品，首页测试同时覆盖加载后显示回顶入口。

## 变更流程

接口字段变更时：

1. 更新 Apifox。
2. 更新本契约。
3. 更新 H5 mapper 和测试。
4. 写入任务验证记录。

## 回滚方式

H5 可回滚到上一版 active manifest。接口失败时当前版本展示错误/空业务态，不回落到本地静态业务数据；首页固定活动入口随页面版本回滚。
