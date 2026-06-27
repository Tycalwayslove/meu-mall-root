# TASK-2026-0627-002-h5-mine-benefits-real-api

## 状态

implemented

## 目标

将 H5 `/mine` 我的页面和 `/promotion/benefits` 权益中心切入 Apifox 当前真实接口，进入联调口径。

## 背景

`/mine` 此前为静态高保真 mock。用户要求使用 Apifox“喵呜达人个人中心接口 / 个人中心页数据”作为我的页数据源；点击权益中心后进入权益中心，权益中心使用 Apifox“达人等级接口”中的“查询我的达人等级”和“达人等级列表”，并支持切换查看不同等级。

## 涉及项目

- `hybird-meumall`
- `.ai-workspace`

## 范围

包含：

- `/mine` 接入 Java `GET /p/app/profile/summary`。
- `/mine` 同步读取 Java `GET /p/daren/level/myLevel` 用于当前达人等级和权益中心入口。
- `/promotion/benefits` 聚合 Java `GET /p/daren/level/myLevel` 与 `GET /p/daren/level/list`。
- 权益中心继续支持左右滑、箭头和等级轨道切换。
- 接口失败或 token 缺失时展示错误态，不回退 mock。

不包含：

- 不接钱包流水、优惠券列表、订单列表、收藏和足迹真实接口。
- 不新增 Native Bridge 或管理后台配置。

## 责任边界

`hybird-meumall`：

- 通过 H5 BFF 请求 Java 接口并映射页面 view model。
- 处理 loading、error、空字段和 token 缺失。
- 联调阶段不使用本地 mock 业务数据兜底。

后端：

- 按 Apifox 契约提供个人中心概览、我的等级和等级列表。
- 确认接口 path 与描述中旧 `/p/distribution/...` path 的差异，以 OpenAPI 当前 path 为准。

原生 App：

- 继续写入有效 `mallToken` Cookie。
- 继续承载 `/mine` Tab 根 WebView 和新开权益中心 H5 WebView。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-mine-benefits-real-api-contract.md`。
- 是否向后兼容：新增 H5 BFF 真实消费契约，页面 UI 结构兼容现有实现。
- 是否需要迁移：是，`/mine` 与 `/promotion/benefits` 从 mock 迁移到真实接口。
- 是否需要灰度：H5 发布时建议走 candidate 后切 active。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0627-002-h5-mine-benefits-real-api.md`。
- 需要确认的角色：后端 / 原生 App / 测试。
- 当前确认状态：接口已在 Apifox released，H5 已实现，待 App token 联调验证。

## 对方责任

后端：

- 提供测试环境有效数据。
- 确认钱包余额、今年已省、可用券、等级权益、达人权益展示条目的字段口径。

原生 App：

- 提供有效 `mallToken`。
- 确认从 `/mine` 点击权益中心新开 H5 WebView 可正常打开 `/promotion/benefits?level=<v>`。

管理后台：

- 当前无必须交付项。

CI 或发布：

- 后续发布 H5 candidate，并 smoke `/mine`、`/promotion/benefits` 和对应 BFF。

## Mock 和联调方式

- Mock 数据位置：旧 mock 保留给未迁移页面和历史单测；本次页面联调不使用 mock 兜底。
- 测试接口环境：Java `https://test.aigcpop.com/mini_h5`。
- App 测试包版本：待 App 联调时记录。
- 联调步骤：App 写入有效 `mallToken` -> 打开 `/mine` -> 查看真实钱包/今年已省/优惠券 -> 点击权益中心 -> 查看当前等级并切换其他等级。
- H5 fallback：错误态；头像/文案缺失使用安全占位；数值字段缺失展示 0，不拼接 mock。

## 实现计划

1. 查询 Apifox 当前接口和 DTO。
2. 新增 mine summary 和 promotion level 聚合 service。
3. 切换 `/mine`、`/api/bff/mine/summary`、`/promotion/benefits`、`/api/bff/promotion/benefits`。
4. 补测试和文档记录。

## 验收标准

- [x] `/api/bff/mine/summary` 请求 `/p/app/profile/summary` 和 `/p/daren/level/myLevel`。
- [x] `/mine` 不再直接渲染静态 `minePageData`。
- [x] `/api/bff/promotion/benefits` 请求 `/p/daren/level/myLevel` 和 `/p/daren/level/list`。
- [x] `/promotion/benefits` 权益中心使用真实等级列表，支持切换不同等级。
- [x] 接口失败或 token 缺失不回退 mock。
- [ ] App WebView 有效 token 联调通过。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/features/mine/mine-real-api.test.tsx src/features/promotion/promotion-service.test.ts src/features/promotion/api.test.ts
pnpm typecheck
```

## 发布影响

- 是否需要发布：需要 H5 发版后生效。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：建议 candidate 验证后切 active。
- 回滚目标：上一版 `/mine` 和 `/promotion/benefits` mock 页面 active H5。
- smoke check：`GET /api/health`、`GET /mine`、`GET /promotion/benefits`、`GET /api/bff/mine/summary`、`GET /api/bff/promotion/benefits`。

## 风险和阻塞

- 尚未在真实 App WebView 中用有效 `mallToken` 完成接口返回验证。
- Apifox 接口 description 中写了旧 `/p/distribution/level/...`，OpenAPI path 当前为 `/p/daren/level/...`，H5 按 OpenAPI path 实现。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-27 | implemented | `/mine` 和 `/promotion/benefits` 已切真实接口，聚焦测试和类型检查通过；待 App token 联调。 |
