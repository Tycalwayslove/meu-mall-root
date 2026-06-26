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

H5 商品详情页需要从静态 mock 迁移到真实商品接口。本期消费普通商品、快递配送、SKU、立即购买到订单确认的实时校验能力、普通快递订单创建能力，以及创建订单后的收银台支付信息展示。确认付款流程暂不迁移：H5 不调用 Java `/p/order/pay`，不接支付 Bridge，不处理支付结果页。

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
| `addrId` | string | 否 | `0` | 地址 ID。商品详情默认 `0`；订单确认和提交会优先使用默认/选中收货地址解析后的 `addrId`。 |
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
| `addrId` | string | 否 | `0` | 收货地址 ID。未传时 BFF 先用 `0` 请求默认地址；解析到默认地址后再用真实 `addrId` 校验商品详情。 |
| `dvyType` | `1` | 否 | `1` | 本期只做快递。 |

#### BFF 服务端流程

1. 调 Java `/p/address/addrInfo/<addrId>` 解析收货地址；未传地址时使用 `0` 获取默认地址。
2. 调 Java `/prod/prodInfo?prodId=<productId>&addrId=<resolvedAddrId>&dvyType=1` 校验商品、SKU、库存和配送。
3. 调 Java `/p/order/confirm`，按旧 uni-app 普通商品立即购买参数生成后端订单确认上下文。
4. 确认成功后调 Java `/p/score/scoreInfo` 拉取会员积分信息；该接口失败不阻断订单确认页。
5. H5 确认页优先使用 Java 确认返回的 `actualTotal`、`totalCount`、`totalTransFee`、`orderReduce`；未返回时回退商品侧估算。
6. 普通快递链路对齐旧 uni-app：确认响应里的 `submitOrder` 不作为 H5 按钮置灰或提交拦截条件；无收货地址仍禁止提交。

### H5 BFF：提交普通快递订单

- Method：`POST`
- Path：`/api/bff/order-submit`
- 鉴权：用户登录态，服务端从 Cookie 读取 `mallToken`
- 幂等性：否，会创建后端订单；前端按钮提交中和成功后需禁用，避免重复点击
- 缓存策略：no-store
- 超时时间：沿用 H5 backend client 默认超时

#### Body

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `productId` | string | 是 | 无 | 商品 ID。 |
| `skuId` | string | 是 | 无 | 已选 SKU ID。 |
| `quantity` | number | 否 | `1` | 购买数量，BFF 会归一为不小于 1 的整数。 |
| `addrId` | string/number | 否 | `0` | 收货地址 ID。未传时 BFF 先解析默认地址；无法解析收货地址时禁止提交订单。 |
| `orderFlowLogParam` | object | 否 | H5 兜底生成 | 订单流埋点上下文，客户端按旧 uni-app `bbcFlowAnalysisLogDto` 规则生成并随提交透传。 |

#### BFF 服务端流程

1. 调 Java `/p/address/addrInfo/<addrId>` 解析收货地址；未传地址时使用 `0` 获取默认地址。
2. 若提交订单时无法解析收货地址，H5 返回 409，不继续确认或提交。
3. 调 Java `/prod/prodInfo?prodId=<productId>&addrId=<resolvedAddrId>&dvyType=1` 重新校验商品、SKU、库存和配送。
4. 调 Java `/p/order/confirm`，使用旧 uni-app 普通商品快递确认参数和解析后的 `addrId` 生成后端订单确认上下文。
5. 复用确认响应里的 `shopCartOrders` 生成 `orderShopParams`，不因普通确认响应 `submitOrder === 0` 在 H5 层提前拦截。
6. 调 Java `/p/order/submit` 创建订单；提交失败时使用 Java 返回的错误提示。
7. 成功时返回 Java `orderNumbers`，H5 跳转 `/pay-way` 展示收银台支付信息。

### H5 BFF：收银台支付信息

- Method：`GET`
- Path：`/api/bff/order-pay-info`
- 鉴权：用户登录态，服务端从 Cookie 读取 `mallToken`
- 幂等性：是
- 缓存策略：no-store，交易态不能缓存

#### Query

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `orderNumbers` | string | 是 | 无 | `/p/order/submit` 返回的订单号，支持旧接口逗号分隔订单号。 |
| `dvyType` | string | 否 | `1` | 配送方式。本期普通快递默认 `1`。 |
| `isPurePoints` | `0`/`1` | 否 | `0` | 是否纯积分订单；普通商品默认 `0`。 |
| `orderType` | string | 否 | `0` | 订单类型，普通商品默认 `0`。 |
| `ordermold` | string | 否 | `0` | 订单模具/虚拟商品标记，普通商品默认 `0`。 |

#### BFF 服务端流程

1. 调 Java `/p/order/getOrderPayInfoByOrderNumber?orderNumbers=<orderNumbers>` 读取待支付订单金额、过期时间、积分和订单状态。
2. 调 Java `/sys/config/info/getSysPaySwitch` 读取支付方式开关；该接口失败时 H5 可展示默认支付宝/微信支付方式，不阻断收银台展示。
3. 输出 `view.methods`，当前只展示 App 支付语境下的支付宝 `payType=7` 和微信 `payType=8`。
4. 本期点击“确定支付”只本地提示“已发起支付”，不调用 Java `/p/order/pay`。

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

### Java 后端：收货地址详情

- Method：`GET`
- Path：`/p/address/addrInfo/{addrId}`
- 示例：`/p/address/addrInfo/0`
- 鉴权：`Authorization: <mallToken>`
- 来源：H5 BFF 对 Java / mall 后端统一注入请求头 `source: 1`
- 幂等性：是

#### Path

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `addrId` | string/number | 是 | `0` | 收货地址 ID；旧 uni-app 使用 `0` 读取当前用户默认地址。 |

#### H5 使用口径

- `/api/bff/order-confirm` 会先解析地址，再用解析后的 `addrId` 请求 `/prod/prodInfo`，用于配送和价格校验；地址缺失时页面展示未选择地址并禁止提交。
- `/api/bff/order-submit` 会强制解析地址，解析失败直接返回 409，避免创建无收货地址订单。
- `/address` 和 `/address/edit` 已由地址模块契约承接真实 BFF；地址页不使用本地业务数据兜底，省市区通过 Java `/p/area/listByPid`，地图选点后置。

#### Response 关键字段

```ts
type JavaUserAddress = {
  addr?: string;
  addrId?: number | string;
  area?: string;
  city?: string;
  mobile?: string;
  province?: string;
  receiver?: string;
};
```

### Java 后端：普通订单确认

- Method：`POST`
- Path：`/p/order/confirm`
- 鉴权：`Authorization: <mallToken>`
- 来源：H5 BFF 对 Java / mall 后端统一注入请求头 `source: 1`
- 幂等性：是，确认价格、库存、配送和可提交状态

#### Body

```ts
type JavaOrderConfirmRequest = {
  addrId: number; // 订单确认/提交 BFF 解析后的真实收货地址 ID
  dvyTypes: Array<{
    dvyType: 1;
    lat: null;
    lng: null;
    shopId: number;
    stationId: 0;
  }>;
  isScorePay: 0;
  orderItem: {
    prodCount: number;
    prodId: string;
    shopId: number;
    skuId: string;
  };
  couponParams: [];
  prodCount: number;
  userChangeCoupon: 0;
  userUseScore: 0;
};
```

#### Response 关键字段

```ts
type JavaOrderConfirmInfo = {
  actualTotal?: number; // 实付款
  orderReduce?: number; // 订单优惠
  submitOrder?: number; // 普通快递链路仅记录后端返回，不作为 H5 置灰/拦截条件；最终以 /p/order/submit 返回为准
  total?: number; // 商品总额
  totalCount?: number; // 商品总数
  totalTransFee?: number; // 运费
  shopCartOrders?: Array<{
    remarks?: string;
    shopId?: number;
    stationSearchVO?: {
      stationId?: number;
    };
  }>;
};
```

### Java 后端：普通订单提交

- Method：`POST`
- Path：`/p/order/submit`
- 鉴权：`Authorization: <mallToken>`
- 来源：H5 BFF 对 Java / mall 后端统一注入请求头 `source: 1`
- 幂等性：否，会创建订单

#### Body

```ts
type JavaOrderSubmitRequest = {
  isScorePay: 0;
  orderFlowLogParam: {
    bizData?: string;
    bizType?: number;
    pageId?: number;
    prevPageId?: number;
    step: number;
    systemType: number; // H5 浏览器环境为 2，App WebView Android 为 4，iOS 为 5
    uuid: string;
    uuidSession: string;
    visitType: 1;
  };
  orderInvoiceList: null;
  orderSelfStationDto: {
    stationId: 0;
    stationTime: "";
    stationUserMobile: "";
    stationUserName: "";
  };
  orderShopParams: Array<{
    remarks: "";
    shopId: number;
    stationId: 0;
  }>;
  virtualRemarkList: [];
};
```

#### `orderFlowLogParam` 来源

H5 客户端持久化旧 uni-app 同名上下文键：`bbcUuid`、`bbcUuidSession`、`bbcStep`、`bbcSessionTimeStamp` 和 `bbcFlowAnalysisLogDto`。

- 进入商品详情 `/product/[id]`：记录 `pageId=3`、`bizType=0`、`bizData=<productId>`，并递增 `step`。
- 进入订单确认 `/order-confirm`：记录 `prevPageId` 为上一页 `pageId`，但不新增订单页 `pageId`，保持旧 uni-app `submit-order` 的行为。
- 点击提交订单：再次递增 `step`，将最新对象作为 `/api/bff/order-submit` 的 `orderFlowLogParam` 传给 BFF，再由 BFF 透传 Java `/p/order/submit`。
- 超过 30 分钟无操作时刷新 `uuidSession` 并重置 `step`。

#### Response 关键字段

```ts
type JavaOrderSubmitInfo = {
  duplicateError?: number;
  orderNumbers?: string;
};
```

### Java 后端：收银台订单支付信息

- Method：`GET`
- Path：`/p/order/getOrderPayInfoByOrderNumber`
- 鉴权：`Authorization: <mallToken>`
- 来源：H5 BFF 对 Java / mall 后端统一注入请求头 `source: 1`

#### Query

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `orderNumbers` | string | 是 | 待支付订单号。 |

#### Response 关键字段

```ts
type JavaOrderPayInfo = {
  endTime?: string;
  status?: number; // 1 待付款；2/3/4/5/7 按旧页面视为已支付或后续状态
  totalFee?: number;
  totalScore?: number;
};
```

### Java 后端：系统支付开关

- Method：`GET`
- Path：`/sys/config/info/getSysPaySwitch`
- 鉴权：`Authorization: <mallToken>`
- 来源：H5 BFF 对 Java / mall 后端统一注入请求头 `source: 1`

```ts
type JavaPaymentSwitchInfo = {
  aliPaySwitch?: boolean;
  wxPaySwitch?: boolean;
  balancePaySwitch?: boolean;
  payPalSwitch?: boolean;
};
```

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
    orderConfirm?: JavaOrderConfirmInfo;
    productInfo: JavaProductInfo;
    scoreInfo?: JavaScoreInfo;
    selectedSku: JavaProductSku;
    userAddress?: JavaUserAddress;
  };
  debugRaw?: {
    orderConfirm?: JavaEnvelope<JavaOrderConfirmInfo>;
    prodInfo: JavaEnvelope<JavaProductInfo>;
  };
};
```

```ts
type JavaScoreInfo = {
  score?: number;
};
```

### H5 BFF 订单提交响应

```ts
type OrderSubmitBffData = {
  view: {
    message: "订单已创建，等待支付。";
    orderNumbers: string;
    status: "created";
  };
  modules: {
    orderConfirm?: JavaOrderConfirmInfo;
    orderSubmit: JavaOrderSubmitInfo;
    productInfo: JavaProductInfo;
    selectedSku: JavaProductSku;
    userAddress: JavaUserAddress;
  };
  debugRaw?: {
    orderConfirm?: JavaEnvelope<JavaOrderConfirmInfo>;
    orderSubmit?: JavaEnvelope<JavaOrderSubmitInfo>;
    prodInfo?: JavaEnvelope<JavaProductInfo>;
  };
};
```

### H5 BFF 收银台响应

```ts
type OrderPayInfoData = {
  view: {
    amountText: string;
    defaultPayType: 7 | 8;
    dvyType: string;
    endTime: string;
    isPurePoints: boolean;
    methods: Array<{
      id: "aliPay" | "wechatPay";
      label: string;
      payType: 7 | 8;
    }>;
    orderNumbers: string;
    orderType?: string;
    ordermold?: string;
    status: "failed" | "paid" | "pending" | "unknown";
    statusText: string;
    totalAmount: number;
    totalScore: number;
  };
  modules: {
    orderPayInfo: JavaOrderPayInfo;
    paySwitch?: JavaPaymentSwitchInfo;
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
| `HTTP_ERROR` | 409 | SKU 不存在、库存不足、无收货地址或 Java 提交失败。 | 停留在订单确认页，提示用户返回商品详情重新选择或稍后重试。 |

## H5 兜底策略

- 商品详情接口失败：展示错误态，不白屏。
- 商品不存在或字段不足：展示商品暂时不可见。
- 图片缺失：使用现有商品图占位组件。
- 富文本缺失：展示详情描述兜底。
- 富文本包含危险标签、事件属性或 `javascript:` 链接：H5 清洗后再渲染。
- SKU 缺失或库存为 0：禁用购买确认。
- 订单确认实时校验失败：不展示可提交状态。
- 订单提交前重新校验 SKU 和库存，不信任 URL 参数。
- 订单提交失败：停留在订单确认页展示错误，不跳支付，不伪造订单号。
- 订单提交成功但缺少 `orderNumbers`：按解析错误处理，不进入支付。
- 收银台支付信息失败：停留在 `/pay-way` 展示可恢复错误，不调用支付接口。
- 收银台点击“确定支付”：本期仅提示“已发起支付”，不调用 `/p/order/pay`，不接支付 Bridge，不进入支付结果页。
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
- H5 验证：打开 `/product/1000054` 和 `/order-confirm?productId=1000054&skuId=<skuId>&quantity=1&addrId=<addrId>`，点击提交订单后确认页面展示 `orderNumbers`；未传 `addrId` 时需能通过 `/p/address/addrInfo/0` 解析默认地址。
- 契约测试：覆盖 mapper、图片 URL、SKU 默认选择、库存不足和错误 envelope。
- 联调环境：`JAVA_API_BASE_URL=https://test.aigcpop.com/mini_h5`。

## 变更流程

1. 更新本契约。
2. 后端确认旧接口字段。
3. H5 更新 BFF 和 mapper。
4. 联调验证。
5. 更新工作项和对接说明。

## 回滚方式

H5 异常时回滚到本任务前版本。后端旧接口不做变更，无后端回滚动作。回滚后 `/api/bff/order-submit` 不再可用，订单确认页恢复为不可正式提交。已经通过 Java `/p/order/submit` 创建的订单属于后端真实订单，不能通过 H5 回滚自动撤销。
