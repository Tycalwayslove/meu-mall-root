# TASK-2026-0630-001 H5 卖手活动真实接口联调

## 状态

verified

## 目标

在 `hybird-meumall` 中实现卖手活动 H5 页面和真实 BFF 联调链路，覆盖营销活动入口、活动商品配置列表、批量状态操作、选择推广商品和活动商品配置保存。

## 背景

智能体入口由原生 App 实现。用户从原生“营销活动”入口进入 H5 后，需要查看平台配置的可参加卖手活动，并对某个活动下的商品做上架、暂停、删除和价格配置。

## 涉及项目

- `hybird-meumall`：页面、BFF、API adapter、状态和测试。
- Java 后端：提供卖手活动接口和推广商品分页接口。
- `app-meumall`：只负责原生智能体入口跳转到 H5 `/seller/activities`，本任务不实现原生入口。

## 范围

- 新增 `/seller/activities` 营销活动入口页。
- 新增 `/seller/activities/[activityId]` 活动商品配置页。
- 新增 `/seller/activities/[activityId]/products` 新增活动商品选择页。
- 新增 `/seller/activities/[activityId]/products/[prodId]` 商品活动设置页。
- 接入 `GET /p/sellerActivity/availableList`、`GET /p/sellerActivity/page`、`GET /p/sellerActivity/detail`、`POST /p/sellerActivity/saveOrUpdate`、`POST /p/sellerActivity/batchStatus`。
- 复用推广商品来源 `GET /p/distribution/prod/productPage`。
- 页面首屏和切换状态使用骨架/空态/错误态，联调阶段不回退本地 mock 业务数据。

## 不包含

- 原生智能体入口页面。
- 管理后台活动配置能力。
- 秒杀资格、库存锁定和订单交易闭环。
- 活动海报、分享、活动效果统计。

## 责任边界

- H5 负责页面路由、交互状态、BFF mapper、错误/空态展示和表单提交。
- 后端负责接口字段、鉴权、活动状态、批量操作结果和数据一致性。
- 原生 App 负责从智能体入口打开 H5 `/seller/activities`，并注入有效 `mallToken`。

## 契约影响

- API 契约：`.ai-workspace/contracts/api/h5-seller-activities-real-api-contract.md`
- Native Bridge：无新增，原生入口使用既有 H5 WebView 打开能力。
- Admin Config：无新增，平台活动配置由后端/后台既有能力提供。

## 对接说明

- `.ai-workspace/integration-briefs/BRIEF-2026-0630-001-h5-seller-activities-real-api.md`

## 对方责任

- Java 后端确认 Apifox 字段、状态枚举和错误码稳定。
- 原生 App 确认入口跳转 URL 为 `/seller/activities`，并在 WebView Cookie 中注入 `mallToken`。

## Mock 和联调方式

- Mock 数据不作为页面兜底，仅用于单测 fixture。
- 本地和测试环境通过 H5 BFF 调 Java 测试环境。
- 无 token、接口失败或业务失败时展示错误/重试，不拼接本地数据。

## 验收标准

- [ ] `/seller/activities` 能展示可用营销活动，空数组展示空态。
- [ ] 活动卡点击进入对应活动配置页，不依赖路由 query 切 tab。
- [ ] 配置页支持“进行中/已暂停”tab，切换时使用骨架态并请求 `status=1/0`。
- [ ] 批量编辑支持全选、取消、删除、暂停和开始；进行中橙色按钮为“暂停”，已暂停橙色按钮为“开始”。
- [ ] 选择商品页使用推广商品分页接口，可按关键词搜索并进入设置页。
- [ ] 商品设置页读取详情，支持限购数量、活动时间和 SKU 活动价保存。
- [ ] 所有真实接口联调页面不回退本地 mock 业务数据。
- [ ] BFF mapper 和 API adapter 有测试覆盖。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/features/seller-activity/seller-activity.test.tsx
pnpm typecheck
pnpm exec eslint src/features/seller-activity src/app/seller src/app/api/bff/seller-activities
pnpm run ai:check-docs-sync --strict
```

## 发布影响

- 新增 H5 页面和 BFF 路由，不改变 manifest schema、Native Bridge 协议、支付或发布脚本。
- 发布后需要 App 跳转入口指向 `/seller/activities`。
- 回滚方式：回退 H5 版本或原生入口临时隐藏。

## 风险和阻塞

- 活动详情接口对未配置商品可能返回空 data；H5 需要允许从选择商品进入新增模式。
- SKU 活动价校验规则由后端最终负责，H5 只做非空和数字合法性校验。
- 活动时间目前仅按接口字段透传，是否仅限秒杀必填由后端校验。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-30 | in_progress | 用户确认路由和批量操作语义后进入实现。 |
| 2026-06-30 | verified | 已完成页面、BFF、API adapter、测试和文档同步；真实 App token 联调后继续记录接口数据风险。 |
