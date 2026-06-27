# API 契约：H5 推广首页概览真实接口

## 基本信息

- 契约编号：API-2026-0627-001
- 状态：implemented，待联调验证
- 提供方：Java 后端
- 消费方：`hybird-meumall`
- 适用环境：dev / test / prod
- Apifox 项目：`4403987`，branch `main`
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-001-h5-promotion-home-overview-real-api.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0627-001-h5-promotion-home-overview-real-api.md`

## 背景

推广首页 `/promotion` 需要从 H5 mock 切换到真实达人主页概览数据。Apifox“喵呜商城 / APP接口 / 达人主页接口 / 推广页概览”已提供接口。

## 接口定义

- Method：`GET`
- Java Path：`/p/distribution/home/overview`
- H5 BFF Path：`/api/bff/promotion/home`
- 鉴权：用户登录态；H5 BFF 使用 `mallToken` 作为 Java `Authorization`
- 幂等性：是
- 缓存策略：no-store

## 请求参数

### Header

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `Authorization` | `string` | 是 | Java 用户 Token，由 H5 BFF 从 `mallToken` Cookie 转换 |

### Query

无。

### Body

无。

## 响应结构

Java 响应 envelope：

```json
{
  "code": "00000",
  "msg": "ok",
  "data": {
    "userInfo": {},
    "level": {},
    "mySales": {},
    "salesStats": {},
    "ongoingIncentiveCount": 0
  },
  "version": "string",
  "timestamp": 0,
  "sign": "string"
}
```

## 字段说明

| 字段 | 类型 | 说明 | H5 映射 |
| --- | --- | --- | --- |
| `data.userInfo.nickName` | string | 分销员昵称 | `profile.nickname` |
| `data.userInfo.pic` | string | 头像 | `profile.avatar`，相对路径拼 `JAVA_OSS_ASSET_BASE_URL` |
| `data.userInfo.cardNo` | string | 分销员卡号 | 保留在 `modules.overview` |
| `data.userInfo.state` | integer | 分销员状态 | 保留在 `modules.overview` |
| `data.level.levelInfo.currentLevelValue` | integer | 当前档位 1-5 | `profile.level` 映射为 `v1-v5` |
| `data.level.levelInfo.currentLevelName` | string | 当前等级名称 | `profile.levelName` |
| `data.level.levelInfo.nextUpgradeOrderCount` | integer | 下一档升级所需销量 | 进度目标 |
| `data.level.levelInfo.gapOrderCount` | integer | 距下一档还差订单量 | 进度当前值 |
| `data.level.levelInfo.nextUpgradeGmv` | number | 下一档升级所需 GMV | 无订单目标时作为进度目标 |
| `data.level.levelInfo.gapGmv` | number | 距下一档还差 GMV | 无订单目标时作为进度当前值 |
| `data.mySales.totalCommission` | number | 累计佣金 | `summary.totalCommission` |
| `data.mySales.totalOrderAmount` | number | 累计带货金额 | `summary.totalSalesAmount` |
| `data.mySales.totalOrderCount` | integer | 累计带货订单数 | 保留，当前 UI 六宫格使用 `salesStats.totalPromotionOrderCount` |
| `data.salesStats.todayShopVisitCount` | integer | 今日店铺访问次数 | 六宫格“今日店铺访问” |
| `data.salesStats.todayPromotionOrderCount` | integer | 今日带货订单数 | 六宫格“今日带货订单” |
| `data.salesStats.todayPromotionIncome` | number | 今日带货收益 | 六宫格“今日带货收益” |
| `data.salesStats.totalShopVisitCount` | integer | 累计店铺访问次数 | 六宫格“累计店铺访问” |
| `data.salesStats.totalPromotionOrderCount` | integer | 累计带货订单数 | 六宫格“累计带货订单” |
| `data.salesStats.totalShopFavoriteCount` | integer | 累计店铺收藏 | 六宫格“累计店铺收藏” |
| `data.ongoingIncentiveCount` | integer | 进行中的激励活动数量 | 奖励活动入口副标题 |

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `A00004` | 401 | 未授权 / token 无效 | 展示错误态，不回退 mock |
| `A00005` | 5xx | Java 服务异常 | 展示错误态，不回退 mock |
| `TOKEN_MISSING` | 401 | H5 未读取到 `mallToken` | 展示错误态，等待 App 登录态 |
| `PARSE_ERROR` | 502 | `data` 缺失或不可解析 | 展示错误态 |

## H5 兜底策略

- 成功但头像为空：展示 H5 默认头像占位。
- 成功但等级为空：主题降级为 V1。
- 成功但收益或统计字段为空：展示 0，不从 mock 补业务值。
- token 缺失、鉴权失败、接口失败：展示错误态，不展示 mock 推广首页数据。

## 测试方式

- 后端验证：Apifox 或测试环境直接请求 `/p/distribution/home/overview`。
- H5 验证：`/promotion`、`/api/bff/promotion/home`。
- 契约测试：`pnpm exec vitest run src/features/promotion/promotion-service.test.ts`。
- 联调环境：Java test `https://test.aigcpop.com/mini_h5`。

## 回滚方式

H5 发布异常时回滚 active manifest 到上一版 H5；代码层不在真实接口失败时自动回退 mock，避免联调误判。
