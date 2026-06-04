# API 契约：推广模块 H5 BFF Mock

## 基本信息

- 契约编号：API-2026-0604-002
- 状态：implemented
- 提供方：`hybird-meumall` H5 BFF mock
- 消费方：`hybird-meumall`
- 适用环境：dev / test
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0604-002-promotion-pages-bff-foundation.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0604-002-promotion-pages-bff-foundation.md`

## 背景

推广模块真实后端接口尚未完成。H5 需要先实现高保真页面，并保证后续替换真实接口时不会大面积重写页面组件。因此先建立 H5 BFF mock 契约，页面只依赖 H5 server service 返回的数据结构。

## 通用约定

- 所有接口均走 H5 自身 `/api/bff/promotion/**`。
- 浏览器端不得直接请求 Java / Python 后端。
- 当前 mock 全部 `no-store`。
- 响应使用 H5 BFF 统一结构。

```ts
type H5BffResult<T> =
  | { success: true; data: T; requestId: string }
  | {
      success: false;
      code: string;
      message: string;
      requestId?: string;
      recoverable: boolean;
    };
```

## 领域枚举

```ts
type TalentLevel = "v1" | "v2" | "v3" | "v4" | "v5";

type RankingPeriod = "day" | "week" | "month";

type ActivityStatus = "claiming" | "active" | "ended";
```

## 达人等级展示规则

| level | 名称 | 佣金分成 | 展示定位 | 主题 |
| --- | --- | --- | --- | --- |
| `v1` | 新锐达人 | 基础佣金 | 私域新手，刚建社群 / 朋友圈带货，重点孵化拉新。 | peach |
| `v2` | 白银达人 | 基础 * 120% | 固定私域社群、稳定出单，能做基础复购转化。 | blue |
| `v3` | 黄金达人 | 基础 * 150% | 多社群运营、私域裂变强、复购高。 | gold |
| `v4` | 星钻达人 | 基础 * 180% | 多社群运营、私域裂变强、复购高。 | purple |
| `v5` | 至尊达人 | 基础 * 200% | 私域头部 IP、自有圈层资源、可裂变招商、带团队孵化。 | blackPurple |

月带货销量、月带货 GMV 和额外福利当前只用于展示草案，不能作为最终升级规则。

## 接口：推广首页

- Method：`GET`
- Path：`/api/bff/promotion/home`
- 鉴权：用户登录态，当前 mock 可不校验。
- 幂等性：是。
- 缓存策略：`no-store`。
- 超时时间：`8000ms`。

### Query

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `level` | `TalentLevel` | 否 | 当前用户等级，mock 默认为 `v3` | 用于调试 V1-V5 主题。 |

### 响应结构

```json
{
  "profile": {
    "nickname": "深圳喵小猫",
    "avatar": null,
    "level": "v3",
    "levelName": "黄金达人",
    "progress": {
      "current": 238,
      "target": 500,
      "unit": "growth"
    }
  },
  "theme": {
    "name": "gold",
    "accentColor": "#FFC039",
    "textOnHero": "dark",
    "badgeAssetKey": "talent-badge-v3"
  },
  "summary": {
    "totalCommission": 383,
    "totalSalesAmount": 683,
    "currency": "CNY"
  },
  "quickEntries": [
    {
      "id": "activities",
      "title": "奖励活动",
      "subtitle": "3个进行中",
      "iconKey": "promotion-gift",
      "href": "/promotion/activities"
    },
    {
      "id": "rank-center",
      "title": "排行榜",
      "subtitle": "看看谁是第一",
      "iconKey": "promotion-rank",
      "href": "/promotion/rank-center"
    }
  ],
  "metrics": [
    { "id": "todayVisits", "label": "今日店铺访问", "value": "+45" },
    { "id": "todayOrders", "label": "今日带货订单", "value": "+27" },
    { "id": "todayIncome", "label": "今日带货收益", "value": "¥83" },
    { "id": "totalVisits", "label": "累计店铺访问", "value": "3678" },
    { "id": "totalOrders", "label": "累计带货订单", "value": "893" },
    { "id": "totalFavorites", "label": "累计店铺收藏", "value": "5683" }
  ],
  "tools": [
    { "id": "products", "title": "商品推广", "iconKey": "promotion-tool-product", "href": "/promotion/products" },
    { "id": "guide", "title": "赚钱攻略", "iconKey": "promotion-tool-guide", "href": "/promotion/activities" },
    { "id": "analytics", "title": "访客分析", "iconKey": "promotion-tool-analytics", "href": "/promotion/rank-center" },
    { "id": "card", "title": "推广名片", "iconKey": "promotion-tool-card", "href": "/promotion/card" }
  ]
}
```

## 接口：活动中心

- Method：`GET`
- Path：`/api/bff/promotion/activities`
- 鉴权：用户登录态。
- 缓存策略：`no-store`。

### 响应结构

```json
{
  "couponSummary": "可使用优惠券3个",
  "rewardRecordHref": "/promotion/activities",
  "items": [
    {
      "id": "monthly-2026-07",
      "tag": "月度激励",
      "title": "7月订单激励活动",
      "status": "claiming",
      "description": "完成指定订单目标即可领取奖励",
      "periodText": "活动时间：2026.7.1-2026.7.31",
      "progressLabel": "目前进度",
      "progressValue": "90%"
    }
  ]
}
```

## 接口：榜单中心

- Method：`GET`
- Path：`/api/bff/promotion/rank-center`
- 鉴权：用户登录态。
- 缓存策略：`no-store`，后续可改短 TTL。

### 响应结构

```json
{
  "sections": [
    {
      "id": "talent",
      "title": "达人榜",
      "items": [
        {
          "id": "talent-sales",
          "title": "达人销量榜",
          "subtitle": "每日更新",
          "href": "/promotion/ranking/sales",
          "theme": "blue"
        },
        {
          "id": "talent-amount",
          "title": "达人销售额榜",
          "subtitle": "每日更新",
          "href": "/promotion/ranking/amount",
          "theme": "gold"
        }
      ]
    }
  ]
}
```

## 接口：榜单详情

- Method：`GET`
- Path：
  - `/api/bff/promotion/rankings/sales`
  - `/api/bff/promotion/rankings/amount`
- 鉴权：用户登录态。
- 缓存策略：`no-store`，后续可改短 TTL。

### Query

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `period` | `RankingPeriod` | 否 | `day` | 日榜 / 周榜 / 月榜。 |

### 响应结构

```json
{
  "rankingType": "sales",
  "activePeriod": "day",
  "periodText": "榜单周期：2026.7.1-2026.7.31",
  "tabs": [
    { "id": "sales", "title": "达人销量榜", "href": "/promotion/ranking/sales" },
    { "id": "amount", "title": "达人销售额榜", "href": "/promotion/ranking/amount" }
  ],
  "rows": [
    {
      "rank": 1,
      "name": "深圳喵小猫",
      "avatar": null,
      "value": "9621374",
      "unit": "单"
    }
  ],
  "currentUser": {
    "rank": 23,
    "name": "深圳喵小猫",
    "avatar": null,
    "value": "137",
    "unit": "单",
    "onList": true
  }
}
```

## 接口：达人权益中心

- Method：`GET`
- Path：`/api/bff/promotion/benefits`
- 鉴权：用户登录态。
- 缓存策略：`no-store`。

### Query

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `level` | `TalentLevel` | 否 | 当前用户等级，mock 默认为 `v3` | 用于调试权益页 V1-V5。 |

### 响应结构

```json
{
  "profile": {
    "nickname": "深圳喵小猫",
    "avatar": null,
    "level": "v5",
    "levelName": "至尊达人",
    "progress": {
      "current": 438,
      "target": 500,
      "nextTip": "本月再完成10单即可升级",
      "unlockText": "400可解锁"
    }
  },
  "commission": {
    "label": "基础 * 200%",
    "description": "V5 至尊达人佣金分成"
  },
  "exclusiveBenefits": [
    {
      "id": "commission-boost",
      "title": "佣金膨胀20%",
      "description": "V5至尊达人专享佣金比例",
      "iconKey": "benefit-money"
    }
  ],
  "memberBenefits": [
    {
      "id": "agent-custom",
      "title": "个性化智能体定制服务",
      "description": "描述文案描述内容",
      "iconKey": "benefit-agent"
    }
  ]
}
```

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `PROMOTION_MOCK_NOT_FOUND` | 404 | mock 数据不存在。 | 展示空态或降级默认数据。 |
| `PROMOTION_INVALID_LEVEL` | 400 | level 参数非法。 | 降级到 V1，并记录安全日志。 |
| `TOKEN_MISSING` | 401 | 登录态缺失。 | 展示登录态异常，后续接入 App 登录恢复。 |
| `PROMOTION_SERVICE_ERROR` | 500 | BFF 或后端异常。 | 展示错误态和重试。 |

## H5 兜底策略

- 等级字段缺失或非法：降级为 `v1`。
- 列表为空：展示空态。
- 图标和徽章缺失：使用占位组件。
- V5 大额金额超长：前端必须支持缩小字号、换行或紧凑格式，不能溢出容器。
- BFF 失败：页面不白屏，展示错误态。

## 兼容性要求

- 新增字段：允许，H5 忽略未知字段。
- 删除字段：不允许，必须先提供默认值。
- 字段类型变化：不兼容，必须更新契约和测试。
- 默认值：H5 必须保留安全默认值。

## 测试方式

- H5 验证：
  - BFF mock service 单元测试。
  - 页面数据映射测试。
  - 五档权益和首页主题快照或 DOM 断言。
- 契约测试：
  - 校验 BFF mock 返回字段完整。
  - 校验非法 `level` fallback。
- 联调环境：
  - 真实后端完成后再补充。

## 变更流程

1. 更新本契约。
2. H5 更新 mock 和 server service。
3. 页面使用 server service，不直接使用裸 mock。
4. 后端接口 ready 后，H5 server service 切换为 backend client。
5. 联调验证并更新工作项和对接说明。

## 回滚方式

页面异常时通过 H5 manifest 回滚到上一 active 版本。接口异常时 H5 BFF 可临时切回 mock 或展示 fallback，但不得伪造真实交易数据。
