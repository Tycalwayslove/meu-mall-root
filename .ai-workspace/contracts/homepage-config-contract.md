# 首页配置跨项目契约

## 状态

ready

## 适用范围

本契约定义 MeuMall 首页配置在 `server-meumall`、`admin-meumall` 和 `hybird-meumall` 之间的接口、数据结构和兼容规则。

## 参与项目

- 提供方：`server-meumall`
- 管理方：`admin-meumall`
- 消费方：`hybird-meumall`

## 设计原则

- 首页配置独立于 manifest 和 release。
- H5 只消费 active 配置，不感知草稿、归档和后台管理字段。
- 配置结构必须版本化，新增字段默认向后兼容。
- 首页不得新增购物车入口。
- 图片 URL 第一版由管理端录入，后续可切换为素材库或 CDN。

## 状态流转

首页配置状态：

```text
draft -> active -> archived
```

规则：

- `draft` 可以编辑和删除。
- `active` 不允许直接删除。
- 同一 `environment` 只能有一个 `active`。
- 发布新的 `active` 时，旧的 `active` 自动变为 `archived`。
- `archived` 只读保留，作为回溯和排障依据。

## 管理端接口

### 查询配置列表

```http
GET /api/home/configs?environment=prod&status=draft
```

查询参数：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `environment` | string | 否 | `dev`、`staging`、`prod` |
| `status` | string | 否 | `draft`、`active`、`archived` |

响应：

```json
{
  "items": [
    {
      "id": "home-prod-20260601",
      "name": "生产首页配置 2026-06-01",
      "environment": "prod",
      "status": "draft",
      "configVersion": "2026.06.01-001",
      "createdAt": "2026-06-01T00:00:00Z",
      "updatedAt": "2026-06-01T00:00:00Z",
      "publishedAt": null
    }
  ]
}
```

### 创建配置

```http
POST /api/home/configs
```

请求：

```json
{
  "name": "生产首页配置 2026-06-01",
  "environment": "prod",
  "configVersion": "2026.06.01-001",
  "config": {},
  "source": "admin",
  "createdBy": "codex",
  "notes": "首页配置第一版"
}
```

响应状态：`201 Created`

### 获取配置详情

```http
GET /api/home/configs/{id}
```

响应：

```json
{
  "id": "home-prod-20260601",
  "name": "生产首页配置 2026-06-01",
  "environment": "prod",
  "status": "draft",
  "configVersion": "2026.06.01-001",
  "config": {},
  "source": "admin",
  "createdBy": "codex",
  "notes": "首页配置第一版",
  "createdAt": "2026-06-01T00:00:00Z",
  "updatedAt": "2026-06-01T00:00:00Z",
  "publishedAt": null
}
```

### 更新配置

```http
PUT /api/home/configs/{id}
```

规则：

- 只允许更新 `draft`。
- `active` 和 `archived` 返回 `409 Conflict`。

### 删除草稿

```http
DELETE /api/home/configs/{id}
```

规则：

- 只允许删除 `draft`。
- `active` 和 `archived` 返回 `409 Conflict`。

### 发布配置

```http
POST /api/home/configs/{id}/publish
```

规则：

- 发布目标必须是 `draft`。
- 发布成功后目标状态变为 `active`。
- 同一环境旧 `active` 自动变为 `archived`。

## H5 接口

### 获取当前 active 首页配置

```http
GET /api/h5/home/config/active?environment=prod
```

响应直接返回 H5 可消费配置 body，不包裹后台管理字段：

```json
{
  "schemaVersion": "1.0",
  "pageId": "home",
  "configVersion": "2026.06.01-001",
  "generatedAt": "2026-06-01T00:00:00Z",
  "cache": {
    "ttlSeconds": 300,
    "staleWhileRevalidateSeconds": 1800
  },
  "performance": {
    "requestTimeoutMs": 4000,
    "skeletonMinMs": 200,
    "preloadImageCount": 1,
    "lcpCandidateModuleId": "home-banner",
    "telemetrySampleRate": 1
  },
  "modules": []
}
```

无 active 配置时返回：

```json
{
  "code": "HOME_CONFIG_NOT_FOUND",
  "message": "No active home config for environment"
}
```

HTTP 状态：`404 Not Found`

## 页面配置结构

### HomeConfig

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `schemaVersion` | string | 是 | 第一版固定为 `1.0` |
| `pageId` | string | 是 | 固定为 `home` |
| `configVersion` | string | 是 | 配置版本号 |
| `generatedAt` | string | 是 | ISO 时间 |
| `cache` | object | 是 | H5 缓存策略 |
| `performance` | object | 否 | H5 性能策略 |
| `modules` | array | 是 | 首页模块列表 |

### CachePolicy

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `ttlSeconds` | number | 是 | 本地缓存新鲜期 |
| `staleWhileRevalidateSeconds` | number | 否 | 可降级使用的过期缓存窗口 |

### PerformancePolicy

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `requestTimeoutMs` | number | 否 | 首页配置请求超时 |
| `skeletonMinMs` | number | 否 | 骨架屏最短展示时间 |
| `preloadImageCount` | number | 否 | 首屏预加载图片数量 |
| `lcpCandidateModuleId` | string | 否 | LCP 候选模块 ID |
| `telemetrySampleRate` | number | 否 | 性能采样率，范围 0 到 1 |

## 模块结构

所有模块共享字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 是 | 模块唯一 ID |
| `type` | string | 是 | 模块类型 |
| `enabled` | boolean | 是 | 是否启用 |
| `sortOrder` | number | 是 | 排序值，越小越靠前 |

### Banner 模块

`type` 为 `banner_carousel`。

```json
{
  "id": "home-banner",
  "type": "banner_carousel",
  "enabled": true,
  "sortOrder": 10,
  "items": [
    {
      "id": "banner-1",
      "title": "会员日",
      "imageUrl": "https://cdn.example.com/banner.png",
      "alt": "会员日活动",
      "event": {
        "type": "h5_route",
        "target": "/activity/member-day",
        "params": {
          "source": "home_banner"
        }
      },
      "trackingId": "home_banner_member_day",
      "priority": true,
      "enabled": true,
      "sortOrder": 10
    }
  ]
}
```

### 分类入口模块

`type` 为 `category_grid`。

```json
{
  "id": "home-category",
  "type": "category_grid",
  "enabled": true,
  "sortOrder": 20,
  "columns": 4,
  "rows": 2,
  "items": [
    {
      "id": "cat-beauty",
      "name": "美妆个护",
      "iconUrl": "https://cdn.example.com/cat-beauty.png",
      "event": {
        "type": "h5_route",
        "target": "/category/beauty",
        "params": {
          "categoryId": "beauty"
        }
      },
      "enabled": true,
      "sortOrder": 10
    }
  ]
}
```

规则：

- `columns` 范围为 2 到 5。
- `rows` 范围为 1 到 3。
- H5 按 `columns * rows` 控制首屏展示数量，超出部分后续可扩展为分页或横滑。

### 活动模块

`type` 为 `activity_section`。

```json
{
  "id": "home-activity",
  "type": "activity_section",
  "enabled": true,
  "sortOrder": 30,
  "title": "限时活动",
  "displayMode": "card_grid",
  "items": [
    {
      "id": "act-1",
      "kind": "promotion",
      "title": "新人专享",
      "subtitle": "首单立减",
      "imageUrl": "https://cdn.example.com/activity.png",
      "badge": "NEW",
      "startsAt": "2026-06-01T00:00:00Z",
      "endsAt": "2026-06-30T23:59:59Z",
      "event": {
        "type": "h5_route",
        "target": "/activity/new-user",
        "params": {}
      },
      "enabled": true,
      "sortOrder": 10
    }
  ]
}
```

规则：

- `enabled=false` 时 H5 不渲染该模块或条目。
- 当前时间不在 `startsAt` 和 `endsAt` 范围内时，H5 不渲染该活动条目。

## 事件结构

第一版事件结构只定义数据，不强制一次实现所有行为。

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `type` | string | 是 | `h5_route`、`external_url`、`native_bridge` |
| `target` | string | 是 | 路由、URL 或 Bridge action |
| `params` | object | 否 | 事件参数 |

规则：

- `h5_route` 只能跳转 H5 已知页面。
- `external_url` 必须是 `https`。
- `native_bridge` 必须由 H5 现有 Bridge 能力支持。
- 不允许配置购物车目标。

## 校验规则

后端必须校验：

- `schemaVersion` 为 `1.0`。
- `pageId` 为 `home`。
- `modules` 是数组。
- 模块 ID 在同一配置中唯一。
- 启用的图片项必须有 `imageUrl`。
- 启用的分类项必须有 `name`。
- `columns`、`rows` 和性能数值在允许范围内。
- 事件目标不得指向购物车。

管理端必须校验：

- 必填字段不为空。
- 图片 URL 格式合法。
- 分类列数和行数在允许范围内。
- 发布前至少有一个启用模块。

H5 必须处理：

- 接口 404。
- 请求超时。
- JSON 解析失败。
- 模块类型未知。
- 单个模块配置异常。

## 缓存规则

H5 只缓存公共首页配置，不缓存用户 token、价格、库存、资格和支付相关数据。

缓存键建议：

```text
meumall:home-config:{environment}:{schemaVersion}
```

缓存命中规则：

- 在 `ttlSeconds` 内直接可用。
- 超过 `ttlSeconds` 但未超过 `staleWhileRevalidateSeconds` 时，可以作为远端失败兜底。
- 超过 stale 窗口后丢弃。

## 兼容规则

- 新增可选字段必须向后兼容。
- 删除字段或改变字段语义必须提升 `schemaVersion`。
- H5 遇到未知模块类型应跳过，并记录 telemetry。
- 后端可以保留旧配置，但只允许发布当前支持 schema 的配置。

## 验收要求

- 后端接口、管理端 API 封装和 H5 渲染逻辑都必须有测试。
- H5 active 接口返回结构必须与本契约一致。
- 发布流程必须保证同环境 active 唯一。
- 首页无 active 配置、接口失败或配置部分异常时，H5 不白屏。
- 新增配置不得出现购物车入口。
