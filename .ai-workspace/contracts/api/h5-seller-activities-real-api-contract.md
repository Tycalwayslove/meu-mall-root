# H5 卖手活动真实接口契约

## 契约名称

H5 Seller Activities Real API Contract

## 提供方

Java 后端。

## 消费方

`hybird-meumall` H5 BFF 和页面。

## 适用环境

- local：H5 BFF 指向 Java 测试环境。
- test：H5 BFF 指向 Java 测试环境。
- prod：待正式 Java 域名确认后切换 profile，不改变页面调用方式。

## 版本策略

- 新增可选字段向后兼容。
- 删除字段、改变字段类型、改变状态枚举或错误 envelope 不兼容，必须先更新本契约和对接说明。
- H5 BFF 只暴露页面所需 view model，保留 `modules/debugRaw` 便于联调。

## 鉴权

H5 浏览器端只请求自身 `/api/bff/seller-activities/**`。Next BFF 从 Cookie 读取 `mallToken`，请求 Java 后端时设置：

```text
Authorization: <mallToken>
source: 1
x-request-id: <requestId>
```

缺少 token 时 BFF 返回 `TOKEN_MISSING`，页面展示错误态，不回退 mock 数据。

## 请求格式

### 查询可用营销活动

```http
GET /p/sellerActivity/availableList
```

H5 BFF：

```http
GET /api/bff/seller-activities
```

核心响应字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | number | 平台活动配置 ID |
| `activityCode` | string | 活动编码 |
| `activityName` | string | 活动名称 |
| `activityImg` | string | 活动图 |
| `activityDesc` | string | 活动描述 |
| `seq` | number | 排序 |
| `status` | number | `-1` 删除，`0` 禁用，`1` 启用 |
| `runningProductCount` | number | 正在参与活动的商品数 |
| `orderCount` | number | 订单数 |

### 查询卖手配置的活动

```http
GET /p/sellerActivity/page?activityId=<id>&status=<0|1>&current=<n>&size=<n>
```

H5 BFF：

```http
GET /api/bff/seller-activities/:activityId/products?status=<0|1>&current=<n>&size=<n>
```

`status=1` 对应“进行中”，`status=0` 对应“已暂停”。

### 查询卖手活动详情

```http
GET /p/sellerActivity/detail?activityId=<id>&prodId=<prodId>
```

H5 BFF：

```http
GET /api/bff/seller-activities/:activityId/products/:prodId
```

### 新增或修改卖手活动

```http
POST /p/sellerActivity/saveOrUpdate
Content-Type: application/json
```

H5 BFF：

```http
POST /api/bff/seller-activities/save-or-update
```

Body：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `id` | number | 否 | 编辑时传卖手活动配置 ID |
| `activityId` | number | 是 | 平台活动配置 ID |
| `prodId` | number | 是 | 商品 ID |
| `activityStartTime` | string | 条件 | 活动开始时间，限时秒杀必填 |
| `activityEndTime` | string | 条件 | 活动结束时间，限时秒杀必填 |
| `limitNum` | number | 是 | 每人限购数量 |
| `skuList` | array | 是 | SKU 活动价列表 |

`skuList[]`：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `skuId` | number | 是 | SKU ID |
| `activityPrice` | number | 是 | 活动价 |

### 批量更新卖手活动状态

```http
POST /p/sellerActivity/batchStatus
Content-Type: application/json
```

H5 BFF：

```http
POST /api/bff/seller-activities/batch-status
```

Body：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `ids` | number[] | 是 | 卖手活动配置 ID 列表 |
| `status` | number | 是 | `-1` 删除，`0` 暂停/下架，`1` 开始/上架 |

交互语义：

- “进行中”tab：橙色按钮“暂停”，提交 `status=0`。
- “已暂停”tab：橙色按钮“开始”，提交 `status=1`。
- 删除按钮提交 `status=-1`，需要二次确认。

### 新增活动商品来源

```http
GET /p/distribution/prod/productPage?current=<n>&size=<n>&keyword=<keyword>&categoryId=<id>&orderBy=<sort>&incentiveId=<activityId>
```

H5 BFF：

```http
GET /api/bff/seller-activities/:activityId/available-products
```

核心响应字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `prodId` | number | 商品 ID |
| `pic` | string | 商品图 |
| `prodName` | string | 商品名称 |
| `price` | number | 到手价 |
| `originalPrice` | number | 原价 |
| `soldNum` | number | 销量 |
| `commissionAmount` | number | 佣金金额 |

## 响应格式

Java 后端 envelope：

```json
{
  "code": "00000",
  "msg": "success",
  "data": {},
  "version": "...",
  "timestamp": 0,
  "sign": "..."
}
```

H5 BFF 成功 envelope：

```json
{
  "success": true,
  "data": {},
  "requestId": "..."
}
```

H5 BFF 失败 envelope：

```json
{
  "success": false,
  "code": "AUTH_FAILED",
  "message": "Unauthorized",
  "requestId": "...",
  "recoverable": true
}
```

## 错误格式

- Java `success=false` 或业务失败码：BFF 转为 H5 `ApiError`。
- HTTP 401/403：`AUTH_FAILED`。
- token 缺失：`TOKEN_MISSING`。
- 响应结构缺失必要 `data`：`PARSE_ERROR`。
- 网络或超时：`NETWORK_ERROR` / `TIMEOUT`。

## 兼容性要求

- H5 对缺失的图片、描述、销量、佣金做展示兜底，但不补业务列表。
- 活动和商品记录缺少主键时，BFF mapper 可跳过该记录。
- 列表空数组必须传递为空态，不允许拼接 mock。

## 测试方式

```bash
cd hybird-meumall
pnpm exec vitest run src/features/seller-activity/seller-activity.test.tsx
pnpm typecheck
pnpm exec eslint src/features/seller-activity src/app/seller src/app/api/bff/seller-activities
```

## 变更流程

1. Apifox 或后端字段变化先更新本契约。
2. 同步更新 integration brief 和 H5 项目 API 文档。
3. 修改 BFF mapper 和测试。
4. 与 App/后端重新联调。

## 回滚方式

- H5 版本回滚到不包含 `/seller/activities` 的版本。
- 原生入口临时隐藏或回退到旧页面。
