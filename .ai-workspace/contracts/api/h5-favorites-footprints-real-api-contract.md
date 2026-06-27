# API 契约：H5 我的收藏与我的足迹真实接口

## 基本信息

- 契约编号：API-2026-0627-005
- 状态：implemented
- 提供方：Java 业务后端
- 消费方：`hybird-meumall`
- 适用环境：dev / test / prod
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-005-h5-favorites-footprints-real-api.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0627-005-h5-favorites-footprints-real-api.md`

## 背景

H5 需要将个人中心二级页“我的收藏-商品”和“我的足迹”接入真实用户数据，并复刻旧 uni-app 的取消收藏、删除足迹行为。

## 接口定义

### H5 BFF

| Method | Path | 用途 | Java 依赖 |
| --- | --- | --- | --- |
| `GET` | `/api/bff/favorites/products` | 商品收藏分页 | `GET /p/user/collection/prods` |
| `POST` | `/api/bff/favorites/products/cancel` | 取消商品收藏 | `POST /p/user/collection/addOrCancel` |
| `GET` | `/api/bff/footprints` | 足迹分页 | `GET /p/prodBrowseLog/page` |
| `DELETE` | `/api/bff/footprints/delete` | 批量删除足迹 | `DELETE /p/prodBrowseLog` |

### Java 接口

| Method | Path | 鉴权 | 幂等性 | 缓存策略 | 超时时间 |
| --- | --- | --- | --- | --- | --- |
| `GET` | `/p/user/collection/prods` | 用户登录态 | 读接口 | no-store | 10s |
| `POST` | `/p/user/collection/addOrCancel` | 用户登录态 | 切换型接口，H5 本期只用于取消 | no-store | 10s |
| `GET` | `/p/prodBrowseLog/page` | 用户登录态 | 读接口 | no-store | 10s |
| `DELETE` | `/p/prodBrowseLog` | 用户登录态 | 删除接口 | no-store | 10s |

H5 BFF 调 Java 时统一由 backend client 注入 `Authorization: <mallToken>`、`source: 1`、`x-request-id` 和客户端上下文 header。

## 请求参数

### 商品收藏分页

Java `GET /p/user/collection/prods`

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | number | 否 | `1` | 页码 |
| `size` | number | 否 | `20` | 每页数量 |

### 取消商品收藏

Java `POST /p/user/collection/addOrCancel`

Body 为原始商品 ID：

```json
1000054
```

H5 BFF 对浏览器端接收：

```json
{
  "prodId": "1000054"
}
```

### 足迹分页

Java `GET /p/prodBrowseLog/page`

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | number | 否 | `1` | 页码 |
| `size` | number | 否 | `20` | 每页数量 |

### 批量删除足迹

Java `DELETE /p/prodBrowseLog`

Body 为足迹 ID 数组：

```json
[123, 456]
```

H5 BFF 对浏览器端接收：

```json
{
  "ids": [123, 456]
}
```

## 响应结构

### BFF 列表响应

```json
{
  "success": true,
  "data": {
    "view": {
      "items": [
        {
          "id": "1000054",
          "prodId": "1000054",
          "title": "商品名称",
          "imageUrl": "https://example.com/a.png",
          "priceText": "¥39.90",
          "salesText": "已售: 100",
          "detailHref": "/product/1000054"
        }
      ],
      "page": {
        "current": 1,
        "size": 20,
        "pages": 1,
        "total": 1,
        "hasNext": false
      }
    },
    "modules": {}
  },
  "requestId": "req_xxx"
}
```

足迹项会额外返回：

```json
{
  "browseLogId": "123",
  "browseTime": "2026-06-27 10:00:00",
  "groupLabel": "2026-06-27"
}
```

### BFF 操作响应

```json
{
  "success": true,
  "data": {
    "ok": true
  },
  "requestId": "req_xxx"
}
```

## 字段说明

| 字段 | 类型 | 必填 | 说明 | 兼容规则 |
| --- | --- | --- | --- | --- |
| `prodId` | string | 是 | 商品 ID | Java 数字或字符串均转字符串 |
| `browseLogId` | string | 足迹页是 | 足迹记录 ID | 删除时转回 Java 可接受的 ID |
| `title` | string | 是 | 商品名称 | 缺失时使用“未命名商品” |
| `imageUrl` | string | 否 | 商品图 URL | 相对路径拼接 `JAVA_OSS_ASSET_BASE_URL` |
| `priceText` | string | 是 | 展示价格 | 缺失时展示 `¥0.00` |
| `salesText` | string | 否 | 销量文案 | 缺失时不展示 |
| `detailHref` | string | 是 | H5 商品详情路径 | 固定 `/product/<prodId>` |

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `AUTH_FAILED` | 401 | token 缺失或 Java 未授权 | 展示错误态，不回退 mock |
| `HTTP_ERROR` | 4xx/5xx | Java 业务失败或网络失败 | 展示错误和重试 |
| `PARSE_ERROR` | 400 | H5 BFF 入参非法 | 操作失败提示 |

## H5 兜底策略

- 接口不可用：展示错误态和重试按钮。
- 字段缺失：跳过缺少 `prodId` 的异常商品；其他字段使用保守默认展示。
- 返回空数据：展示通用 `EmptyState`。
- 用户未登录：展示错误态，依赖 App 重新注入 token 或重新进入页面。

## Mock 数据

仅用于单元测试 fixture，不作为页面兜底。

## 兼容性要求

- 新增字段：H5 忽略未知字段。
- 删除字段：删除 `prodId` / `prodBrowseLogId` 会影响渲染或删除能力，需提前通知 H5。
- 字段类型变化：H5 对 ID、金额、销量做字符串/数字兼容解析。
- 默认值：`current=1`，`size=20`。

## 测试方式

- 后端验证：使用 App 注入的 `mallToken` 调用 Java 旧接口。
- H5 验证：打开 `/favorites/products` 和 `/footprints`，验证列表、空态、错误态和删除操作。
- 契约测试：Vitest 覆盖 BFF service 和 feature API adapter。
- 联调环境：`https://test.aigcpop.com/mini_h5`

## 变更流程

1. 更新本契约。
2. 后端确认或调整。
3. H5 更新消费逻辑。
4. 联调验证。
5. 更新工作项、对接说明和飞书知识库。

## 回滚方式

如接口异常影响用户，回滚 H5 release 到上一稳定版本；后端接口不需要回滚。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-27 | implemented | H5 已新增收藏/足迹 BFF、mapper、页面真实接口渲染和删除动作；待 App WebView 真实 token 联调。 |
