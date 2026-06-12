# API 契约：H5 商品详情真实接口与订单确认校验

## 基本信息

- 契约编号：API-2026-0611-008
- 状态：ready
- 提供方：Java 后端，H5 BFF
- 消费方：`hybird-meumall`
- 适用环境：local / test / prod
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0611-008-h5-product-detail-real-flow.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0611-008-h5-product-detail-real-flow.md`

## 背景

H5 商品详情页需要从静态 mock 迁移到真实商品接口。本期只消费普通商品、快递配送、SKU 和立即购买到订单确认的实时校验能力。

## 接口定义

### H5 BFF：商品详情

- Method：`GET`
- Path：`/api/bff/product-detail`
- 鉴权：用户登录态，服务端从 Cookie 读取 `mallToken`
- 幂等性：是
- 缓存策略：H5 BFF 不缓存；后续如缓存，只能缓存商品基础信息，价格和库存必须短 TTL 或 no-store
- 超时时间：沿用 H5 backend client 默认超时

#### Query

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `prodId` | string | 是 | 无 | 商品 ID，对应路由 `/product/[id]`。 |
| `addrId` | string | 否 | `0` | 地址 ID。本期固定默认。 |
| `dvyType` | `1` | 否 | `1` | 配送方式。本期只做快递。 |

### H5 BFF：订单确认实时校验

- Method：`GET`
- Path：`/api/bff/order-confirm`
- 鉴权：用户登录态，服务端从 Cookie 读取 `mallToken`
- 幂等性：是
- 缓存策略：no-store，不能用缓存继续交易
- 超时时间：沿用 H5 backend client 默认超时

#### Query

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `productId` | string | 是 | 无 | 商品 ID。 |
| `skuId` | string | 是 | 无 | 已选 SKU ID。 |
| `quantity` | number | 是 | `1` | 购买数量。 |
| `addrId` | string | 否 | `0` | 本期固定默认。 |
| `dvyType` | `1` | 否 | `1` | 本期只做快递。 |

### Java 后端：商品详情

- Method：`GET`
- Path：`/prod/prodInfo`
- 示例：`/prod/prodInfo?prodId=1000054&addrId=0&dvyType=1`
- 鉴权：`Authorization: <mallToken>`
- 幂等性：是
- 缓存策略：基础信息可短缓存；价格、库存和订单确认校验不可作为离线可信数据

#### Query

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `prodId` | string/number | 是 | 无 | 商品 ID。 |
| `addrId` | string/number | 是 | `0` | 地址 ID。 |
| `dvyType` | number | 是 | `1` | `1` 快递；本期只使用 `1`。 |

## 响应结构

### H5 BFF 商品详情响应

```ts
type ProductDetailBffData = {
  view: ProductDetailData;
  modules: {
    commentPage?: JavaProductCommentPage;
    commentSummary?: JavaProductCommentSummary;
    productInfo: JavaProductInfo;
    shopInfo?: JavaShopHeadInfo;
    skuList: JavaProductSku[];
  };
  debugRaw?: {
    prodInfo: JavaEnvelope<JavaProductInfo>;
  };
};
```

### H5 BFF 订单确认响应

```ts
type OrderConfirmBffData = {
  view: OrderConfirmData;
  modules: {
    productInfo: JavaProductInfo;
    selectedSku: JavaProductSku;
  };
  debugRaw?: {
    prodInfo: JavaEnvelope<JavaProductInfo>;
  };
};
```

### Java envelope

```ts
type JavaEnvelope<T> = {
  code?: string;
  msg?: string;
  success?: boolean;
  data?: T | null;
};
```

## 字段说明

| 字段 | 类型 | 必填 | 说明 | 兼容规则 |
| --- | --- | --- | --- | --- |
| `prodId` | string/number | 是 | 商品 ID。 | H5 转为 string。 |
| `prodName` | string | 是 | 商品标题。 | 缺失时进入不可见/错误态。 |
| `brief` | string | 否 | 商品副标题。 | 缺失展示空字符串。 |
| `price` | number | 否 | 展示价格。 | 优先 SKU 价格，缺失用商品价格。 |
| `pic` | string | 否 | 主图。 | 支持相对路径和完整 URL。 |
| `imgs` | string | 否 | 逗号分隔轮播图。 | H5 拆分并拼 OSS。 |
| `video` | string | 否 | 商品视频。 | 存在时作为媒体轮播第一项，封面使用 OSS `video/snapshot` 首帧规则。 |
| `content` | string | 否 | 商品详情富文本 HTML。 | H5 使用 `sanitize-html` 白名单清洗，再用 `html-react-parser` 渲染为 React 节点；富文本图片相对路径按 `JAVA_OSS_ASSET_BASE_URL` 拼接；`script`、事件属性和危险协议会被移除。 |
| `shopId` | string/number | 否 | 店铺 ID。 | 本期只保留在 modules。 |
| `afterSaleType` / `afterSaleContent` | string | 否 | 售后保障。 | 按旧 `getAfterSaleName` 映射；无字段时不展示静态兜底。 |
| `prodCertificateRecordDtoList` | array | 否 | 资质/认证信息。 | H5 提取标题并展示为资质条。 |
| `isDelivery` | boolean | 否 | 是否支持快递。 | `false` 时不可购买。 |
| `deliveryModeVO.hasShopDelivery` | boolean | 否 | 是否支持快递。 | `false` 时不可购买。 |
| `skuList` | array | 是 | SKU 列表。 | 空数组时不可购买。 |
| `skuList[].skuId` | string/number | 是 | SKU ID。 | H5 转为 string。 |
| `skuList[].properties` | string | 否 | SKU 规格，例如 `颜色:红;尺码:M`。 | H5 解析成规格文案。 |
| `skuList[].price` | number | 否 | SKU 价格。 | 缺失时使用商品价格。 |
| `skuList[].stocks` | number | 否 | 普通库存。 | 缺失按 0 处理。 |
| `skuList[].pic` | string | 否 | SKU 图片。 | 支持相对路径和完整 URL。 |

### 商品详情辅助接口

`/api/bff/product-detail` 在商品主数据成功后，会尽量聚合以下只读辅助接口：

| 功能 | Java 接口 | 入参 | H5 用途 | 失败策略 |
| --- | --- | --- | --- | --- |
| 店铺头部 | `GET /shop/headInfo` | `shopId` | `modules.shopInfo`，`view.shop` 仅供后续跳店铺能力复用 | 页面不展示店铺卡片；失败不影响商品主数据。 |
| 评论统计 | `GET /prod/prodCommData` | `prodId`, `stationId` | `view.reviewSummary.countText/positiveRateText/tags`、`modules.commentSummary` | 失败时展示无评论概要，不影响商品主数据。 |
| 评论分页 | `GET /prod/prodCommPageByProd` | `prodId`, `size=10`, `current=1`, `evaluate=-1`, `stationId` | `view.reviewSummary.reviews` 取前两条、`modules.commentPage` | 失败时展示无评论概要，不影响商品主数据。 |

店铺和评论属于商品详情首屏只读增强数据，不作为购买、价格、库存和订单确认的可信来源。当前页面不渲染店铺卡片，评价模块即使无评论也保留空态。

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `TOKEN_MISSING` | 401 | 缺少 `mallToken`。 | 商品详情展示登录/鉴权错误，订单确认禁用提交。 |
| `AUTH_FAILED` | 401 | token 无效或过期。 | 同上。 |
| `NOT_FOUND` | 404 | 商品不存在或无有效商品数据。 | 展示商品不可见。 |
| `PARSE_ERROR` | 502 | Java 响应结构无法映射。 | 展示可恢复错误。 |
| `HTTP_ERROR` | 502 | 后端业务或 HTTP 异常。 | 展示可恢复错误。 |
| `OUT_OF_STOCK` | 409 | 订单确认选择的 SKU 库存不足。 | 禁用提交并提示库存不足。 |
| `INVALID_PARAMS` | 400 | 缺少商品、SKU 或数量参数。 | 展示可恢复错误。 |

## H5 兜底策略

- 商品详情接口失败：展示错误态，不白屏。
- 商品不存在或字段不足：展示商品暂时不可见。
- 图片缺失：使用现有商品图占位组件。
- 富文本缺失：展示详情描述兜底。
- 富文本包含危险标签、事件属性或 `javascript:` 链接：H5 清洗后再渲染。
- SKU 缺失或库存为 0：禁用购买确认。
- 订单确认实时校验失败：不展示可提交状态。
- 无 token：展示鉴权失败，不尝试浏览器端读取 token。

## Mock 数据

继续保留：

```text
hybird-meumall/src/features/product/mock/product-detail.ts
```

该 mock 仅用于开发 fallback 和测试，不作为真实接口验收依据。

## 兼容性要求

- 新增字段：H5 忽略未知字段。
- 删除字段：删除 `prodName`、`prodId`、`skuId` 等关键字段会导致 H5 进入错误态。
- 字段类型变化：H5 对 string/number ID 做兼容；数组和对象结构变化需要更新契约。
- 默认值：`addrId=0`、`dvyType=1`。

## 测试方式

- 后端验证：直接访问测试环境 `/prod/prodInfo?prodId=1000054&addrId=0&dvyType=1`，需带 `Authorization`。
- H5 验证：打开 `/product/1000054` 和 `/order-confirm?productId=1000054&skuId=<skuId>&quantity=1`。
- 契约测试：覆盖 mapper、图片 URL、SKU 默认选择、库存不足和错误 envelope。
- 联调环境：`JAVA_API_BASE_URL=https://test.aigcpop.com/mini_h5`。

## 变更流程

1. 更新本契约。
2. 后端确认旧接口字段。
3. H5 更新 BFF 和 mapper。
4. 联调验证。
5. 更新工作项和对接说明。

## 回滚方式

H5 异常时回滚到本任务前版本。后端旧接口不做变更，无后端回滚动作。订单确认未接正式下单接口，因此不会产生真实订单副作用。
