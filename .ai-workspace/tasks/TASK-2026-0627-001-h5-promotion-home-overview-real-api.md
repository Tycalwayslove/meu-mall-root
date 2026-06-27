# TASK-2026-0627-001-h5-promotion-home-overview-real-api

## 状态

implemented

## 目标

将 H5 `/promotion` 推广首页从本地 mock 切换到 Apifox“达人主页接口 / 推广页概览”真实接口，进入联调口径。

## 背景

推广首页此前由 `TASK-2026-0604-002-promotion-pages-bff-foundation` 完成高保真和 BFF mock。当前 Apifox 项目 `4403987` main 分支已发布 `GET /p/distribution/home/overview`，返回用户信息、达人等级、我的带货和六宫格数据。

## 涉及项目

- `hybird-meumall`
- `.ai-workspace`

## 范围

包含：

- `/api/bff/promotion/home` 调 Java `/p/distribution/home/overview`。
- `/promotion` SSR 首屏使用真实接口结果。
- 真实接口失败、token 缺失或鉴权失败时展示错误态，不回退 mock。
- 更新 API 契约、对接说明、页面清单和 H5 项目状态。

不包含：

- 不接推广活动、榜单、权益、佣金明细和名片的真实接口。
- 不新增 Native Bridge 或管理后台配置。

## 责任边界

`hybird-meumall`：

- 消费 Java 概览接口并映射为现有推广首页 view model。
- 处理 loading、error、token 缺失和字段缺失。
- 联调阶段不使用本地 mock 业务数据兜底。

后端：

- 按 Apifox 契约提供 `GET /p/distribution/home/overview`。
- 确认测试环境 token、字段含义、空值策略和业务错误码。

原生 App：

- 继续在 WebView H5 域名写入 `mallToken` Cookie。
- 继续由原生 Tab WebView 承载 `/promotion`。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/h5-promotion-home-overview-real-api-contract.md`。
- 是否向后兼容：新增 H5 BFF 真实消费契约，页面内部 view model 兼容现有 UI。
- 是否需要迁移：是，`/promotion` 从 mock 迁移到真实接口。
- 是否需要灰度：H5 发布时建议走 candidate 后切 active。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0627-001-h5-promotion-home-overview-real-api.md`。
- 需要确认的角色：后端 / 原生 App / 测试。
- 当前确认状态：接口已在 Apifox released，H5 已实现，待 App token 联调验证。

## 对方责任

后端：

- 提供测试环境可用数据。
- 确认 `currentLevelValue`、收益、访问、订单和收藏统计口径。

原生 App：

- 提供有效 `mallToken`。
- 打开 `/promotion` 后确认 Cookie 可被 H5 SSR/BFF 读取。

管理后台：

- 当前无必须交付项。

CI 或发布：

- 后续发布 H5 candidate，并 smoke `/promotion` 与 `/api/bff/promotion/home`。

## Mock 和联调方式

- Mock 数据位置：旧 mock 保留用于未迁移二级页和既有单测；`/promotion` 联调阶段不再使用 mock 兜底。
- 测试接口环境：Java `https://test.aigcpop.com/mini_h5`，path `/p/distribution/home/overview`。
- App 测试包版本：待 App 联调时记录。
- 管理后台测试入口：无。
- 联调步骤：App 写入有效 `mallToken` -> 打开 `/promotion` -> H5 请求 Java 概览 -> 展示真实昵称、头像、等级、累计佣金、累计带货金额和六宫格。
- H5 fallback：错误态；头像缺失用 H5 默认头像；数值字段缺失展示 0，不拼接 mock。

## 实现计划

1. 查询 Apifox 当前接口和 DTO。
2. 新增真实接口 service 和 mapper。
3. 切换 BFF route 与 `/promotion` 页面。
4. 补测试和文档记录。

## 验收标准

- [x] `/api/bff/promotion/home` 请求 Java `/p/distribution/home/overview`。
- [x] `/promotion` 首屏不再调用 `getPromotionHome()` mock。
- [x] 成功态映射真实昵称、头像、等级、累计佣金、累计带货金额和六宫格。
- [x] 接口失败或 token 缺失不回退 mock。
- [x] 相关契约、对接说明、页面清单和项目状态已更新。
- [ ] App WebView 有效 token 联调通过。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/features/promotion/promotion-service.test.ts src/features/promotion/api.test.ts src/features/promotion/promotion-products.test.tsx
pnpm typecheck
```

## 发布影响

- 是否需要发布：需要 H5 发版后生效。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：建议 candidate 验证后切 active。
- 回滚目标：上一版 `/promotion` mock 页面 active H5。
- smoke check：`GET /api/health`、`GET /promotion`、`GET /api/bff/promotion/home`。

## 风险和阻塞

- 尚未在真实 App WebView 中用有效 `mallToken` 完成接口返回验证。
- 二级推广页仍有 mock，需后续按接口逐个迁移。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-27 | implemented | `/promotion` 和 `/api/bff/promotion/home` 已切真实概览接口，聚焦测试和类型检查通过；待 App token 联调。 |
