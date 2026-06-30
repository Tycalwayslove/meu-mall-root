# H5 推广激励活动真实接口契约

## 契约名称

H5 Promotion Incentive Activities Real API Contract

## 提供方

Java 业务后端，Apifox 项目 `4403987` main 分支，“喵呜商城/APP接口/达人激励活动接口”。

## 消费方

`hybird-meumall` H5 BFF 与页面：

- `/promotion/activities`
- `/promotion/activities/[id]`

## 适用环境

- H5 本地、测试、正式环境。
- Java 测试环境当前为 `https://test.aigcpop.com/mini_h5`。

## 版本策略

- H5 BFF 新增路由，向后兼容。
- Java 字段新增可选字段向后兼容；删除字段、修改枚举或 envelope 结构需要先更新本契约。

## 鉴权

- H5 BFF 从 Cookie/调试配置读取 `mallToken`。
- 调 Java 时写入 `Authorization: <mallToken>`，不加 `Bearer`。
- BFF 对 Java 调用继续注入 `source: 1`。

## 请求格式

### 活动分页

```http
GET /p/app/distribution/incentive/page?current=1&size=10&orderBy=-createTime
```

参数：

| 字段 | 位置 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- | --- |
| `current` | query | integer | 否 | 当前页，默认 1 |
| `size` | query | integer | 否 | 每页条数，默认 10 |
| `orderBy` | query | string | 否 | 排序字段，例如 `+createTime,-sales` |

H5 BFF：

```http
GET /api/bff/promotion/activities?current=1&size=10
```

### 活动详情

```http
GET /p/app/distribution/incentive/detail/{id}
```

H5 BFF：

```http
GET /api/bff/promotion/activities/{id}
```

### 奖励详情

```http
GET /p/app/distribution/incentive/reward/detail/{id}
```

H5 BFF：

```http
GET /api/bff/promotion/activities/{id}/reward
```

### 领取奖励

```http
PATCH /p/app/distribution/incentive/reward/receive/{recordId}
Content-Type: application/json

{
  "addressId": 123
}
```

H5 BFF：

```http
PATCH /api/bff/promotion/activities/rewards/{recordId}/receive
```

`addressId` 仅实物奖励快递配送时必填。

## 响应格式

Java 使用统一 envelope：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `code` | string | 状态码 |
| `msg` | string | 信息 |
| `data` | object/null | 数据 |
| `success` | boolean | 是否成功，部分接口返回 |
| `timestamp` | integer | 时间戳 |

H5 BFF 使用统一 envelope：

```ts
type H5BffResult<T> =
  | { success: true; data: T; requestId: string }
  | { success: false; code: string; message: string; requestId?: string; recoverable: boolean };
```

## 核心字段

活动卡片 `DistributionIncentiveCardPageVO`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | integer | 活动 ID |
| `title` | string | 活动标题 |
| `description` | string | 活动描述 |
| `incentiveType` | integer | 1 销量达标，2 GMV 达标，3 销量排行，4 GMV 排行 |
| `displayState` | integer | 0 已暂停，1 未开始，2 进行中，3 待结算，4 领奖中，5 已结束 |
| `currentProgress` | integer | 达标类活动进度百分比 |
| `saleCount` | integer | 销量达标累计销量 |
| `gmv` | number | GMV 达标累计 GMV |
| `saleRank` | integer | 销量排行当前名次 |
| `gmvRank` | integer | GMV 排行当前名次 |
| `rankThresholdVal` | integer | 排行类最次排名阈值 |

活动详情 `DistributionIncentiveAppDetailVO`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id/title/description/incentiveType/startTime/endTime/displayState/banner/ruleSummary/ruleContent` | mixed | 活动基础信息 |
| `targetGroup` | integer | 1 全部达人，2 指定等级达人 |
| `targetLevels` | array | 指定等级列表 |
| `rewards` | array | 奖励节点列表 |
| `progress` | object | 当前达人进度 |
| `completedDistributorCount` | integer | 已完成达人数 |

奖励详情 `DistributionIncentiveAppRewardRecordVO`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | integer | 活动 ID |
| `rewardId` | integer | 奖励节点 ID |
| `isAwarded` | integer | 是否获奖 |
| `details` | array | 奖励明细，含 `id/prizeName/prizeType/deliverState/address` 等 |

## 错误格式

- Java `success === false` 或业务 code 失败时，H5 BFF 映射为 `AUTH_FAILED`、`HTTP_ERROR`、`PARSE_ERROR` 等统一错误。
- HTTP 401 用于 token 缺失或鉴权失败。
- HTTP 502 用于网络、解析或 Java envelope 异常。

## 兼容性要求

- H5 不依赖平台端接口。
- `banner/ruleContent/reward details` 缺失时页面展示文本规则和占位，不拼接 mock 活动。
- 活动列表空数组时展示空态。

## 测试方式

- Mapper 单测覆盖四类 `incentiveType`。
- 页面渲染测试覆盖列表和详情。
- BFF route 通过 typecheck 和 lint。
- App token 联调访问 `/hybird/promotion/activities`。

## 变更流程

1. Apifox 字段变更。
2. 更新本契约和 brief。
3. 更新 H5 mapper 和测试。
4. 记录验证结果。

## 回滚方式

回滚到上一 H5 SSR release；Java 接口无需变更。
