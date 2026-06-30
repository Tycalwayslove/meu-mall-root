# 对接说明：H5 卖手活动真实接口联调

## 基本信息

- 编号：BRIEF-2026-0630-001
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0630-001-h5-seller-activities-real-api.md`
- 状态：verified
- H5 负责人：hybird-meumall
- 后端负责人：Java 后端
- 原生 App 负责人：iOS / Android
- 管理后台负责人：无新增
- 目标联调时间：2026-06-30 起
- 目标上线环境：测试环境先行

## 需求背景

原生智能体页提供“营销活动”入口，H5 负责承载卖手活动列表和商品配置流程。用户需要查看平台活动、进入某个活动、对活动商品做暂停、开始、删除和配置。

## H5 侧目标

用户路径：

```text
原生智能体入口 -> /seller/activities -> 活动配置页 -> 选择商品 -> 商品设置 -> 保存回活动配置页
```

配置页支持“进行中/已暂停”两个 tab。进行中 tab 的批量橙色操作为“暂停”，已暂停 tab 的批量橙色操作为“开始”。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 营销活动 | `/seller/activities` | H5 | 展示可参加的卖手活动 |
| 活动商品配置 | `/seller/activities/[activityId]` | H5 | 展示进行中/已暂停商品，支持批量编辑 |
| 选择商品 | `/seller/activities/[activityId]/products` | H5 | 从推广商品分页列表选择商品 |
| 商品活动设置 | `/seller/activities/[activityId]/products/[prodId]` | H5 | 新增或修改活动商品配置 |
| 智能体营销入口 | 原生 App | App | 本任务不实现 |

## 数据流

```text
用户操作 -> H5 页面 -> /api/bff/seller-activities/** -> Java 接口 -> H5 渲染/跳转/兜底
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 否 | 使用 Apifox 已有卖手活动接口 | `.ai-workspace/contracts/api/h5-seller-activities-real-api-contract.md` |
| 调整接口 | 否 | 若字段变化需先更新契约 | 同上 |
| 鉴权 | 是 | H5 BFF 通过 `mallToken` 转 `Authorization` | 同上 |
| 缓存策略 | 是 | 用户私有配置默认 no-store | 同上 |
| 错误码 | 是 | BFF 按 Java envelope 归一化为 H5 error | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本需求不新增 Bridge | 无 |
| 原生页面跳转 | 是 | 原生智能体入口打开 H5 `/seller/activities` | 复用既有 WebView 打开能力 |
| 登录态 | 是 | App 需注入 `mallToken` Cookie | 既有 H5 鉴权约定 |
| 最低 App 版本 | 待确认 | 取决于原生入口上线版本 | 无新增 |
| fallback | 是 | 入口未上线时 H5 页面可独立访问调试 | 无新增 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 否 | 平台活动配置由后端既有能力提供 | 无 |
| 素材管理 | 否 | 活动图由接口返回 | 无 |
| 上下线开关 | 否 | H5 只消费可用活动列表 | 无 |
| 排序规则 | 否 | H5 按接口返回顺序展示 | 无 |
| 灰度规则 | 否 | 无新增 | 无 |

## H5 侧责任

- [x] 页面结构和状态。
- [x] API client 和 BFF 调用边界。
- [x] 骨架/loading、error、empty、未登录状态。
- [x] Mock 数据仅用于单测 fixture，联调阶段不作为页面兜底。
- [ ] 联调验证。

## 对方责任

### 后端

- [ ] 确认 `/p/sellerActivity/*` 和 `/p/distribution/prod/productPage` 字段、状态枚举、分页规则。
- [ ] 确认 `batchStatus` 的 `-1/0/1` 语义和批量部分失败策略。
- [ ] 确认 `saveOrUpdate` 对活动时间、限购和 SKU 活动价的校验规则。

### 原生 App

- [ ] 智能体“营销活动”入口打开 H5 `/seller/activities`。
- [ ] WebView 注入有效 `mallToken`。

### 管理后台

- [x] 无新增责任。

## Mock 和联调方式

- Mock 数据位置：仅测试文件内 fixture。
- Mock 使用阶段：仅限单测。
- 测试接口环境：H5 BFF -> Java 测试环境。
- App 测试包版本：待原生提供。
- 管理后台测试入口：无新增。
- 联调步骤：打开 `/seller/activities`，进入活动配置页，切换 tab，执行批量暂停/开始/删除，选择商品并保存 SKU 活动价。
- 联调阶段是否已移除页面 mock 兜底：是。

## 真实接口渲染规则

- 首屏展示骨架屏或 loading，不展示 mock 业务数据。
- 接口成功后只渲染真实接口返回并经过 mapper 处理的数据。
- 活动、商品列表为空时展示通用 `EmptyState` 或业务空态组件。
- 接口失败、超时、鉴权失败时展示 error 或重试，不回退 mock。
- BFF mapper 可以跳过字段不完整且无法展示的记录，但不能用本地 mock 补齐列表或详情。

## H5 兜底策略

- 缺少 `mallToken`：BFF 返回鉴权错误，页面展示失败/重试，不展示 mock。
- 活动列表为空：展示营销活动空态。
- 活动商品为空：展示“暂无商品，快去新增活动商品吧~”并保留新增按钮。
- 活动详情为空：按新增模式展示商品设置页，商品基础信息来自选择商品列表可后续补充；保存由后端最终校验。
- 批量操作失败：保留当前选择，展示失败提示并允许重试。

## 验收标准

- [ ] H5 页面成功状态可用。
- [ ] H5 页面 loading、error、empty 状态可用。
- [ ] 首屏骨架/loading、接口成功、空数据空态、失败/重试状态均已验证。
- [ ] 联调阶段未渲染或拼接 mock 业务数据。
- [ ] API 契约与文档一致。
- [ ] 对方交付事项已确认。
- [ ] 联调环境验证通过。
- [ ] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 卖手活动需求需要后端确认：
1. /p/sellerActivity/availableList 活动入口列表。
2. /p/sellerActivity/page 活动商品分页，status=1 进行中，status=0 已暂停。
3. /p/sellerActivity/detail 与 /p/sellerActivity/saveOrUpdate 的新增/编辑字段。
4. /p/sellerActivity/batchStatus 的 -1 删除、0 暂停、1 开始语义。
5. /p/distribution/prod/productPage 作为新增活动商品来源。

原生 App 需要确认：
1. 智能体营销活动入口打开 H5 /seller/activities。
2. WebView 注入 mallToken。

契约文档：.ai-workspace/contracts/api/h5-seller-activities-real-api-contract.md
联调方式：使用 App 测试包或浏览器调试 token 访问 /seller/activities。
验收口径：成功、空态、失败、批量操作和保存链路均可验证。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-30 | 产品/H5 | 已确认 | 路由采用 `/seller/activities`；进行中橙色按钮为暂停，已暂停橙色按钮为开始。 |
| 2026-06-30 | H5 | 已验证 | H5 页面、BFF、API adapter、单测、类型检查、eslint 和文档同步已完成；真实 App token 联调待继续。 |
