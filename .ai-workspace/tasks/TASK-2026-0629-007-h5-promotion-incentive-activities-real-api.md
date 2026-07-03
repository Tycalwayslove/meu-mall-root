# TASK-2026-0629-007 H5 推广激励活动真实接口联调

## 状态

verified

## 目标

将 H5 推广活动中心 `/promotion/activities`、历史活动 `/promotion/activities/history`、活动详情 `/promotion/activities/[id]` 和活动规则 `/promotion/activities/[id]/rules` 从本地 mock 切换到 Apifox “达人激励活动接口” APP 侧接口，支持真实活动列表、历史活动列表、活动详情、规则内容、奖励详情和领取奖励入口。

## 背景

推广首页、我的页、权益中心和排行榜已进入真实 BFF 联调阶段；活动中心仍使用本地 mock。Apifox 项目 `4403987` main 分支已提供 APP 侧达人激励活动接口，H5 需要接入真实数据并保留 loading、empty、error 状态。

## 涉及项目

- `hybird-meumall`：实现 H5 BFF、mapper、页面渲染、测试和项目文档。
- Java 业务后端：提供达人激励活动 APP 接口。

## 范围

- 包含：
  - `/api/bff/promotion/activities` 调 Java `/p/app/distribution/incentive/page`。
  - 活动中心首屏两次查询：`displayStates=[1,2,3,4]` 获取进行中，`displayStates=[0]` 获取已暂停。
  - 历史活动页 `/promotion/activities/history` 查询 `displayStates=[6]`。
  - `/api/bff/promotion/activities/[id]` 调 Java `/p/app/distribution/incentive/detail/{id}`。
  - 活动规则页 `/promotion/activities/[id]/rules` 复用详情 BFF，展示 `ruleContent`。
  - `/api/bff/promotion/activities/[id]/reward` 调 Java `/p/app/distribution/incentive/reward/detail/{id}`。
  - `/api/bff/promotion/activities/rewards/[recordId]/receive` 转发领取奖励 PATCH。
  - `/promotion/activities` 和 `/promotion/activities/[id]` 使用真实 BFF 数据。
  - 补充契约、对接说明、项目状态和测试报告。
- 不包含：
  - 平台端活动创建、编辑、暂停、删除、导出。
  - 奖励记录列表页 `/promotion/activities/reward-records` 真实接口。
  - 实物奖励地址选择完整交互；本期只预留 BFF 领取参数。

## 责任边界

- H5 负责页面状态、BFF 聚合、字段映射、空/错态和领取入口调用边界。
- Java 后端负责活动生命周期、达人进度、奖励记录、领取状态和业务错误码。
- 原生 App 不新增 Bridge 能力。
- 管理后台不在本任务范围内。

## 契约影响

- 新增契约：`.ai-workspace/contracts/api/h5-promotion-incentive-activities-real-api-contract.md`
- 向后兼容：新增 H5 BFF 路由，不改现有 Java 接口。
- 灰度：随 H5 SSR release 灰度。

## 对接说明

- `.ai-workspace/integration-briefs/BRIEF-2026-0629-007-h5-promotion-incentive-activities-real-api.md`

## 对方责任

- Java 后端确认四个 APP 接口在测试环境可用，并保持 Apifox 字段口径。
- Java 后端确认奖励领取的实物地址 `addressId` 必填规则和业务失败码。

## Mock 和联调方式

- Mock 仅保留单测 fixture，不作为页面兜底。
- H5 BFF 调用测试 Java 域名，使用 App 注入或调试 Cookie 中的 `mallToken`。
- 列表、详情、奖励详情接口失败时页面展示错误态，不回退本地活动 mock。

## 验收标准

- [ ] `/promotion/activities` 首屏使用真实 BFF，成功、空数据、失败状态均可展示。
- [ ] `/promotion/activities/history` 使用真实 BFF，成功、空数据、失败和分页加载更多状态均可展示。
- [ ] `/promotion/activities/[id]` 使用真实详情和奖励信息，非法 id 或接口失败不渲染 mock。
- [ ] `/promotion/activities/[id]/rules` 展示真实 `ruleContent`，从详情页右上角“活动规则”进入。
- [ ] 领取奖励 BFF 支持 PATCH 转发 `addressId`。
- [ ] 接口 mapper 覆盖销量达标、GMV 达标、销量排行、GMV 排行四类活动字段。
- [ ] `pnpm typecheck` 通过。
- [ ] 相关 Vitest 用例通过。
- [ ] 项目文档、契约和测试报告同步。

## 验证命令

- `pnpm exec vitest run src/features/promotion/promotion-incentive-activities-real-service.test.ts src/features/promotion/promotion-service.test.ts`
- `pnpm exec vitest run src/features/promotion/promotion-incentive-activities-real-service.test.ts src/features/promotion/api.test.ts src/features/promotion/promotion-service.test.ts`
- `pnpm typecheck`
- `pnpm lint -- src/features/promotion/server/promotion-incentive-activities-real-service.ts src/features/promotion/components/PromotionActivitiesScreen.tsx src/features/promotion/components/PromotionActivityDetailScreen.tsx`
- `pnpm run ai:check-docs-sync --strict`

## 发布影响

- 需要发布 `hybird-meumall` SSR。
- 不影响 manifest schema、Native Bridge、管理后台和 CI 流程。
- 回滚方式：回滚到上一 H5 SSR release。
- smoke check：使用有效 `mallToken` 访问 `/hybird/promotion/activities` 和某个真实活动详情。

## 风险和阻塞

- 真实奖励领取如果是实物奖励，可能需要用户选择地址；本期只保留 BFF 参数能力，页面领取交互按后续产品确认补齐。
- Apifox path 参数同时出现 query 描述，H5 按 path 参数调用，必要时可后续兼容 query。

## 变更记录

- 2026-06-29：创建任务，依据 Apifox main 分支达人激励活动 APP 接口进入实现。
- 2026-06-29：完成 H5 BFF、列表页、详情页、奖励详情和领取奖励接口接入；验证命令通过，状态更新为 `verified`。`pnpm lint -- ...` 会受仓库既有订单/收藏页面 react-hooks 错误影响，已用 `pnpm exec eslint <本次文件>` 精确验证本次文件，0 errors、2 个活动页既有 `<img>` warnings。
- 2026-07-02：按新分页口径更新活动中心：进行中 `[1,2,3,4]`、已暂停 `[0]`、历史活动 `[6]`；新增历史活动页、底部入口、骨架屏、空态和加载更多。
- 2026-07-02：活动详情右上角入口改为“活动规则”，新增 `/promotion/activities/[id]/rules` 展示详情接口 `ruleContent`。
