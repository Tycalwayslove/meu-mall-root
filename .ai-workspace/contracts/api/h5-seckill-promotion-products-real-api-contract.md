# H5 秒杀和推广商品真实接口契约

## 基本信息

- 契约编号：API-2026-0624-001
- 状态：verified
- 提供方：Java 后端，Apifox 项目 `4403987`
- 消费方：`hybird-meumall`
- 适用环境：test / prod
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0624-001-h5-seckill-promotion-products-real-api.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0624-001-h5-seckill-promotion-products-real-api.md`

## Apifox 来源

项目：`4403987`

分支：`main`

目录：

```text
喵呜商城/APP接口/喵呜达人首页接口
```

接口：

| 名称 | Method | Java Path | H5 BFF |
| --- | --- | --- | --- |
| 首页秒杀商品分页 | GET | `/p/app/home/seckillProds` | `/api/bff/seckill/products` |
| 推广商品页分页列表 | GET | `/p/distribution/prod/productPage` | `/api/bff/promotion/products` |

## 鉴权

两个 Java 接口都需要用户登录态。H5 BFF 从 `mallToken` Cookie 读取 token，并按当前 Java 联调口径发送：

```http
Authorization: <mallToken>
```

## 首页秒杀商品分页

### 请求

```http
GET /p/app/home/seckillProds?current=1&size=10
```

Query：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | integer | 否 | `1` | 当前页 |
| `size` | integer | 否 | `10` | 每页条数 |

H5 不主动传 Apifox 中的分页框架参数 `optimizeJoinOfCountSql` 和 `MAX_SIZE`。

### 响应

```ts
type ServerResponseEntityIPageAppHomeSeckillProdVO = {
  code?: string;
  msg?: string;
  data?: IPageAppHomeSeckillProdVO | null;
  version?: string;
  timestamp?: number;
  sign?: string;
  success?: boolean;
};

type IPageAppHomeSeckillProdVO = {
  records?: AppHomeSeckillProdVO[];
  total?: number;
  size?: number;
  current?: number;
  pages?: number;
};

type AppHomeSeckillProdVO = {
  seckillId?: number;
  prodId?: number;
  prodName?: string;
  pic?: string;
  seckillPrice?: number;
  originalPrice?: number;
  soldNum?: number;
  remainingStocks?: number;
  limitNum?: number;
  endTime?: string;
  remainingSeconds?: number;
};
```

### H5 映射

| Java 字段 | H5 字段 |
| --- | --- |
| `prodId` | 商品 ID、详情跳转 `/product/<prodId>` |
| `prodName` | 商品标题 |
| `pic` | 商品图 |
| `seckillPrice` | 秒杀价 |
| `originalPrice` | 原价 |
| `soldNum` | 已售 |
| `remainingStocks` | 剩余库存 |
| `limitNum` | 限购文案 |
| `remainingSeconds` / `endTime` | 剩余时间展示 |

## 推广商品页分页列表

### 请求

```http
GET /p/distribution/prod/productPage?current=1&size=10&sort=1
```

Query：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | integer | 否 | `1` | 当前页 |
| `size` | integer | 否 | `10` | 每页条数 |
| `prodName` | string | 否 |  | 商品名搜索 |
| `sort` | integer | 否 | `1` | `1` 销量倒序，`2` 价格高到低，`3` 价格低到高，`4` 佣金金额高到低，`5` 佣金金额低到高，`6` 佣金比例高到低，`7` 佣金比例低到高 |
| `categoryId2` | integer | 否 |  | 二级分类 ID |
| `categoryId3` | integer | 否 |  | 三级分类 ID |

### 响应

```ts
type ServerResponseEntityDistributionProdProductPageDto = {
  code?: string;
  msg?: string;
  data?: DistributionProdProductPageDto | null;
  version?: string;
  timestamp?: number;
  sign?: string;
};

type DistributionProdProductPageDto = {
  total?: number;
  size?: number;
  current?: number;
  pages?: number;
  records?: DistributionPromoteProdItemDto[];
};

type DistributionPromoteProdItemDto = {
  prodId?: number;
  pic?: string;
  prodName?: string;
  price?: number;
  soldNum?: number;
  originalPrice?: number;
  commissionAmount?: number;
  isFavorite?: boolean;
};
```

### H5 映射

| Java 字段 | H5 字段 |
| --- | --- |
| `prodId` | 商品 ID、详情跳转 `/product/<prodId>`、分享 payload `productId` |
| `pic` | 商品图 |
| `prodName` | 商品标题 |
| `price` | 用户价 |
| `soldNum` | 销量 |
| `commissionAmount` | 预计可赚 |
| `isFavorite` | 收藏按钮状态预留 |

## H5 BFF 响应

浏览器端统一消费：

```ts
type H5BffResult<T> =
  | { success: true; data: T; requestId: string }
  | { success: false; code: string; message: string; requestId?: string; recoverable: boolean };
```

分页结果统一包含：

```ts
type PageInfo = {
  current: number;
  size: number;
  total?: number;
  pages?: number;
  hasMore: boolean;
};
```

## 错误格式

- Java 业务失败：BFF 转成统一失败响应。
- 未登录或 token 缺失：BFF 返回 `AUTH_FAILED` 或 `TOKEN_MISSING`。
- 网络失败或超时：BFF 返回 `NETWORK_ERROR` 或 `TIMEOUT`。
- 字段缺失：mapper 跳过不可用记录；无可用记录时页面展示空态，不拼接本地 mock。

## H5 兜底策略

- 秒杀商品列表失败：展示空态或可恢复加载状态。
- 推广商品列表失败：展示空态或可恢复加载状态。
- 图片为空：展示 `ProductImagePlaceholder`。
- 商品 ID 缺失：不进入 H5 视图模型。

## 测试方式

- BFF service 单测覆盖路径、参数、字段映射和失败处理。
- 页面测试覆盖真实初始数据、空态、商品详情跳转和分享 payload。
- 联调环境用有效 `mallToken` 验证真实接口返回。

## 回滚方式

H5 可回滚到上一版 active manifest；当前版本链调阶段不拼接本地 mock 商品。
