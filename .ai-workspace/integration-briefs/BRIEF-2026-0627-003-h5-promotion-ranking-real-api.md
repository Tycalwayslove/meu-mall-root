# 对接说明：推广排行榜真实接口联调

## 基本信息

- 编号：BRIEF-2026-0627-003
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-003-h5-promotion-ranking-real-api.md`
- 状态：implemented，待 App token 联调验证
- 目标联调时间：2026-06-27 起
- 目标上线环境：测试环境

## 需求背景

推广排行榜此前为 H5 静态 mock。后端已在 Apifox 项目 `4403987` main 分支发布“推广排行榜接口”，H5 需要先完成销量榜和销售额榜真实联调；达人激励榜暂时只展示空态。榜单页我的排名来自排行榜接口响应内 `myRank`。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 达人销量榜 | `/promotion/ranking/sales` | H5 | Java `rankType=1`，展示订单数 |
| 达人销售额榜 | `/promotion/ranking/amount` | H5 | Java `rankType=2`，展示 GMV |
| 达人激励榜 | `/promotion/ranking/incentive` | H5 | 本阶段不请求接口，展示空态 |

## 数据流

```text
App WebView 写入 mallToken Cookie
  -> H5 SSR /promotion/ranking/sales 或 /promotion/ranking/amount
  -> H5 BFF /api/bff/promotion/rankings/{sales|amount}
  -> Java /p/distribution/rank/list
  -> H5 渲染榜单、我的排名或空态
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 推广排行榜接口 | 已有 | `GET /p/distribution/rank/list`，`rankType=1/2` | `.ai-workspace/contracts/api/h5-promotion-ranking-real-api-contract.md` |
| 鉴权 | 是 | H5 BFF 用 `mallToken` 转 Java `Authorization` | `h5-bff-http-auth-contract.md` |

## H5 侧责任

- [x] 销量榜和销售额榜 BFF 接真实 Java。
- [x] 周期切换映射 `period=1/2/3`。
- [x] 我的排名使用排行榜接口响应内 `myRank`。
- [x] 榜单类型和周期切换不修改路由，不污染 WebView 返回栈。
- [x] 真实空数组展示空态。
- [x] 激励榜展示空态，不拼接 mock。
- [x] 接口失败、token 缺失不回退 mock。

## 对方责任

后端：

- [ ] 提供测试环境有效榜单数据。
- [ ] 确认 `score` 在销量榜为订单数、销售额榜为 GMV。
- [ ] 确认后续是否单独接“我的排行榜战报”用于分享战报，不作为当前榜单页依赖。

原生 App：

- [ ] 打开排行榜前写入 `mallToken` Cookie。
- [ ] 确认榜单中心到三个榜单页面的 WebView 打开行为正常。

## Mock 和联调方式

- Mock 数据位置：旧 `promotion/mock/rankings.ts` 保留给历史测试和未迁移入口，不作为本次联调兜底。
- 联调步骤：打开 `/promotion/rank-center` -> 进入销量榜和销售额榜 -> 切换日/周/月 -> 验证列表、前三名、我的排名和空态。
- 激励榜：进入 `/promotion/ranking/incentive`，应看到空态。

## 验收标准

- [x] 销量榜和销售额榜使用真实接口。
- [x] 空榜不展示 mock 姓名或 mock 数值。
- [x] 激励榜不请求 `rankType=4`，只展示空态。
- [x] API 契约与 Apifox 当前接口一致。
- [ ] App WebView 有效 token 联调通过。

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-27 | H5 | 已实现，待联调 | Apifox 项目 `4403987` main 分支，接口状态 released。 |
