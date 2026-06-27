# API 契约：H5 推广排行榜真实接口

## 基本信息

- 契约编号：API-2026-0627-003
- 状态：implemented，待联调验证
- 提供方：Java 后端
- 消费方：`hybird-meumall`
- Apifox 项目：`4403987`，branch `main`
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-003-h5-promotion-ranking-real-api.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0627-003-h5-promotion-ranking-real-api.md`

## 接口定义

### 推广排行榜接口

- Method：`GET`
- Java Path：`/p/distribution/rank/list`
- H5 BFF Path：`/api/bff/promotion/rankings/sales`、`/api/bff/promotion/rankings/amount`
- 鉴权：用户登录态；H5 BFF 使用 `mallToken` 作为 Java `Authorization`

| 参数 | 类型 | 必填 | 说明 | H5 口径 |
| --- | --- | --- | --- | --- |
| `period` | integer | 是 | `1` 日榜，`2` 周榜，`3` 月榜 | H5 `day/week/month` 映射为 `1/2/3` |
| `rankType` | integer | 否 | `1` 销量，`2` GMV，`3` 收益，`4` 激励 | 本阶段只请求 `1/2` |
| `statPeriod` | string | 否 | 日 `yyyy-MM-dd`、周 `yyyy-Wxx`、月 `yyyy-MM` | H5 有 query 时透传 |

## 字段说明

| DTO | 字段 | 类型 | H5 映射 |
| --- | --- | --- | --- |
| `DistributionRankPageDto` | `rankList` | array | 榜单前三和列表 |
| `DistributionRankPageDto` | `myRank` | object | 底部我的排名 |
| `DistributionRankPageDto` | `startTime/endTime/statPeriod` | string | 榜单周期文案 |
| `DistributionRankDto` | `rankNo/nickName/pic/score` | mixed | 名次、昵称、头像、排行分值 |

## H5 兜底策略

- `rankList` 为空：展示榜单空态，不拼接 mock 排名。
- `myRank.onRank=false`：底部展示“您未上榜”。
- `nickName` 为空：展示“喵呜达人”兜底文案。
- `pic` 为空：使用现有渐变头像占位。
- 接口失败、超时、鉴权失败或 token 缺失：展示错误态，不回退 mock。
- `/promotion/ranking/incentive`：本阶段固定空态，不请求 `rankType=4`。
- 榜单类型和周期切换：页面内 state + BFF 请求，不修改 URL，不追加 WebView history。

## 测试方式

- H5 验证：`/promotion/ranking/sales`、`/promotion/ranking/amount`、`/promotion/ranking/incentive`。
- BFF 验证：`/api/bff/promotion/rankings/sales?period=week`、`/api/bff/promotion/rankings/amount?period=month`。
- 契约测试：`pnpm exec vitest run src/features/promotion/promotion-service.test.ts src/features/promotion/api.test.ts`。

## 回滚方式

H5 发布异常时回滚 active manifest 到上一版 H5；代码层不在真实接口失败时自动回退 mock，避免联调误判。
