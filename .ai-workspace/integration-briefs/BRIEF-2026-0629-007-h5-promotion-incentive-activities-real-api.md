# 对接说明：H5 推广激励活动真实接口联调

## 基本信息

- 编号：BRIEF-2026-0629-007
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0629-007-h5-promotion-incentive-activities-real-api.md`
- 状态：verified
- H5 负责人：hybird-meumall
- 后端负责人：Java 业务后端
- 原生 App 负责人：无新增依赖
- 管理后台负责人：无新增依赖
- 目标联调时间：2026-06-29
- 目标上线环境：H5 测试环境，随后按 H5 release 灰度

## 需求背景

推广活动中心目前仍是本地 mock。后端已在 Apifox “达人激励活动接口”目录提供 APP 侧活动列表、详情、奖励详情和领取接口，H5 需要切换为真实数据联调。

## H5 侧目标

- `/promotion/activities` 展示当前达人可参与或待领奖的激励活动列表。
- `/promotion/activities/[id]` 展示活动详情、个人进度、奖励规则和奖励领取入口。
- 活动列表、详情、奖励详情失败时展示可恢复错误态，不拼接本地 mock。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 活动中心 | `/promotion/activities` | H5 | 活动列表，入口来自推广首页 |
| 活动详情 | `/promotion/activities/[id]` | H5 | 活动规则、个人进度、奖励节点 |

## 数据流

```text
用户进入活动中心 -> H5 BFF -> Java 达人激励活动 APP 接口 -> H5 mapper -> 页面真实数据/空态/错态
用户进入活动详情 -> H5 BFF detail + reward detail -> H5 mapper -> 详情页
用户领取奖励 -> H5 BFF PATCH -> Java receive 接口 -> H5 刷新详情或展示结果
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 是 | 使用 Apifox 已存在 APP 侧四个接口 | `.ai-workspace/contracts/api/h5-promotion-incentive-activities-real-api-contract.md` |
| 调整接口 | 否 | H5 不要求改 Java 接口 | 同上 |
| 鉴权 | 是 | 使用 `mallToken` 转 Java `Authorization` | 同上 |
| 缓存策略 | 是 | 用户进度和奖励状态按 no-store | 同上 |
| 错误码 | 是 | Java envelope 业务失败映射 H5 BFF 错误态 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 无新增 Bridge | 无 |
| 原生页面跳转 | 否 | 仍使用现有 H5 WebView 路由策略 | 无 |
| 登录态 | 是 | App 继续注入 `mallToken` Cookie | `h5-bff-http-auth-contract.md` |
| 最低 App 版本 | 否 | 无新增能力 | 无 |
| fallback | 否 | Bridge 不涉及 | 无 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 否 | 本期只消费 Java 活动接口 | 无 |
| 素材管理 | 否 | 活动 banner 由 Java 接口返回 | 无 |
| 上下线开关 | 否 | 生命周期由 Java 返回 | 无 |
| 排序规则 | 否 | H5 传 `orderBy` 或使用后端默认 | 无 |
| 灰度规则 | 否 | 随 H5 release | 无 |

## H5 侧责任

- [x] 页面结构和状态。
- [x] API client 与 BFF 调用。
- [x] loading、error、empty、未登录状态。
- [x] Mock 数据仅用于单测，联调阶段不作为页面兜底。
- [x] 联调验证记录。

## 对方责任

### 后端

- [ ] 确认 `/p/app/distribution/incentive/page` 返回当前达人活动卡片。
- [ ] 确认 `/p/app/distribution/incentive/detail/{id}` 返回活动完整详情和个人进度。
- [ ] 确认 `/p/app/distribution/incentive/reward/detail/{id}` 返回当前达人奖励记录详情。
- [ ] 确认 `/p/app/distribution/incentive/reward/receive/{recordId}` 的实物奖励地址规则。

### 原生 App

- [ ] 无新增事项，继续注入有效 `mallToken`。

### 管理后台

- [ ] 无新增事项。

## Mock 和联调方式

- Mock 数据位置：H5 单测 fixture。
- Mock 使用阶段：仅限单测。
- 测试接口环境：Java `https://test.aigcpop.com/mini_h5`
- App 测试包版本：沿用当前 WebView 调试包。
- 联调步骤：
  1. 写入或注入有效 `mallToken`。
  2. 打开 `/hybird/promotion/activities`。
  3. 点击活动进入 `/hybird/promotion/activities/<id>`。
  4. 对有可领取奖励的记录调用领取接口。
- 联调阶段是否已移除页面 mock 兜底：是。

## 真实接口渲染规则

- 首屏展示骨架或 loading，不展示 mock 业务数据。
- 接口成功后只渲染真实接口返回并经过 mapper 处理的数据。
- 列表为空展示业务空态。
- 接口失败、超时、鉴权失败展示错误态或未登录态，不回退 mock。
- BFF mapper 可以跳过字段不完整的奖励明细，但不能补齐本地活动。

## H5 兜底策略

- 缺少 token：BFF 返回鉴权错误，页面展示错误态。
- 列表为空：展示“暂无活动”。
- 详情缺失或非法 id：详情页 not found 或错误态。
- 奖励领取失败：返回 BFF 错误，页面后续交互展示失败提示。

## 验收标准

- [ ] H5 页面成功状态可用。
- [ ] H5 页面 loading、error、empty 状态可用。
- [ ] 首屏 loading、接口成功、空数据空态、失败/重试状态均已验证。
- [ ] 联调阶段未渲染或拼接 mock 业务数据。
- [ ] API 契约与文档一致。
- [ ] 对方交付事项已确认或风险已记录。
- [ ] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 活动中心接入达人激励活动 APP 接口，需要后端确认：
1. 列表、详情、奖励详情、领取奖励四个接口在测试环境可用。
2. displayState、incentiveType、progress、rewards、details 字段口径与 Apifox 一致。
3. 实物奖励领取时 addressId 的必填条件和业务错误码。

契约文档：
.ai-workspace/contracts/api/h5-promotion-incentive-activities-real-api-contract.md

联调方式：
App 或 debug-login 注入 mallToken 后访问 /hybird/promotion/activities。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-29 | H5 | 已完成 H5 侧实现与本地验证 | 后端真实 token 联调仍需在 App WebView 中确认 |
