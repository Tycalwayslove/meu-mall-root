# TASK-2026-0627-003-h5-promotion-ranking-real-api

## 状态

implemented

## 目标

将 H5 推广排行榜中的达人销量榜和达人销售额榜接入 Apifox 当前真实接口；达人激励榜本阶段暂未开放真实展示，先落对应空态页面。

## 背景

排行榜此前为静态高保真 mock。用户要求使用 Apifox“达人推广排行榜接口”目录下的“推广排行榜接口”进行联调；当前只展示自由销量榜和销售额榜，激励榜暂时使用空态组件。

## 涉及项目

- `hybird-meumall`
- `.ai-workspace`

## 范围

包含：

- `/promotion/ranking/sales` 接入 Java `GET /p/distribution/rank/list?rankType=1`，我的排名使用响应内 `myRank`。
- `/promotion/ranking/amount` 接入 Java `GET /p/distribution/rank/list?rankType=2`，我的排名使用响应内 `myRank`。
- 支持 `period=day|week|month` 映射 Apifox `period=1|2|3`，并透传可选 `statPeriod`。
- `/promotion/ranking/incentive` 展示空态，不请求 `rankType=4`。
- 接口失败或 token 缺失时展示错误态，不回退 mock 榜单数据。

不包含：

- 不接战队榜。
- 不接激励榜真实数据。
- 不新增排行榜规则说明或分享战报页面。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-promotion-ranking-real-api-contract.md`。
- 是否向后兼容：新增 H5 BFF 真实消费契约；激励榜保留空态。
- 是否需要灰度：H5 发布时建议走 candidate 后切 active。

## 对接说明

- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0627-003-h5-promotion-ranking-real-api.md`。
- 需要确认的角色：后端 / 原生 App / 测试。
- 当前确认状态：接口已在 Apifox released，H5 已实现，待 App token 联调验证。

## 验收标准

- [x] `/api/bff/promotion/rankings/sales` 请求 `/p/distribution/rank/list?period=<1|2|3>&rankType=1`。
- [x] `/api/bff/promotion/rankings/amount` 请求 `/p/distribution/rank/list?period=<1|2|3>&rankType=2`。
- [x] 我的排名来自 `/p/distribution/rank/list` 响应内 `myRank`。
- [x] 榜单类型和周期切换只更新页面 state 与 BFF 请求，不追加 WebView 路由历史。
- [x] 销量榜单位展示为“单”，销售额榜单位展示为“元”。
- [x] 真实接口空数组展示空态，不拼接 mock 榜单。
- [x] 达人激励榜进入 `/promotion/ranking/incentive` 并展示空态。
- [ ] App WebView 有效 token 联调通过。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/features/promotion/promotion-service.test.ts src/features/promotion/api.test.ts
pnpm typecheck
```

## 风险和阻塞

- 尚未在真实 App WebView 中用有效 `mallToken` 完成接口返回验证。
- Apifox `DistributionRankPageDto.rankType` 已预留 3 收益、4 激励；本阶段 H5 不请求激励榜，避免误绑定未开放展示。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-27 | implemented | 销量榜和销售额榜已切真实接口；激励榜展示空态；测试和类型检查通过。 |
