# 对接说明：H5 我的收藏与我的足迹真实接口迁移

## 基本信息

- 编号：BRIEF-2026-0627-005
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-005-h5-favorites-footprints-real-api.md`
- 状态：implemented
- H5 负责人：H5
- 后端负责人：Java 业务后端
- 原生 App 负责人：App WebView
- 管理后台负责人：无
- 目标联调时间：2026-06-27 起
- 目标上线环境：测试环境优先

## 需求背景

H5 个人中心二级页“我的收藏”和“我的足迹”当前仍展示本地 mock。订单链路已进入真实接口迁移阶段，收藏和足迹也需要同步接入旧 Java 接口，避免用户看到静态样例数据或无法执行删除操作。

## H5 侧目标

用户从 `/mine` 进入收藏或足迹页面后，页面请求真实 BFF，展示真实商品列表；进入编辑态后可以选择、全选并删除记录。接口失败时展示可恢复错误态，空数据展示统一空态。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 我的收藏-商品 | `/favorites/products` | H5 | 商品收藏列表、取消收藏 |
| 我的足迹 | `/footprints` | H5 | 浏览足迹列表、批量删除 |

## 数据流

```text
用户进入页面 -> H5 feature API -> H5 BFF -> Java 旧接口 -> BFF mapper -> H5 渲染
用户编辑删除 -> H5 feature API -> H5 BFF -> Java 删除/取消接口 -> H5 刷新列表
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 否 | 沿用旧 Java 接口 | `.ai-workspace/contracts/api/h5-favorites-footprints-real-api-contract.md` |
| 调整接口 | 否 | 本期不要求后端改造 | 同上 |
| 鉴权 | 是 | App 写入 `mallToken`，H5 BFF 转 `Authorization: <mallToken>` | `docs/05_API_SPEC.md` |
| 缓存策略 | 是 | 用户私有数据，H5 按 no-store 处理 | 同上 |
| 错误码 | 是 | Java envelope 失败由 BFF 转统一错误 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本期不新增 Bridge | 无 |
| 原生页面跳转 | 否 | 商品详情仍使用现有 H5 路由 | 无 |
| 登录态 | 是 | App WebView 需注入 `mallToken` Cookie | `docs/05_API_SPEC.md` |
| 最低 App 版本 | 否 | 无新增原生能力 | 无 |
| fallback | 是 | 缺 token 展示错误态，不展示 mock | 同上 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 否 | 无后台配置 | 无 |
| 素材管理 | 否 | 商品图来自 Java/OSS | 无 |
| 上下线开关 | 否 | 无 | 无 |
| 排序规则 | 否 | 沿用 Java 分页返回顺序 | 无 |
| 灰度规则 | 否 | 跟随 H5 release | 无 |

## H5 侧责任

- [x] 页面结构和状态。
- [x] API client 或 Bridge adapter 调用。
- [x] 骨架/loading、error、empty、未登录状态。
- [x] Mock 数据仅用于原型或单测，联调阶段不作为页面兜底。
- [ ] 联调验证。

## 对方责任

### 后端

- [ ] 保持旧 Java 接口路径、分页参数、删除参数和响应 envelope 可用。

### 原生 App

- [ ] 在 WebView 中继续写入有效 `mallToken` Cookie。

### 管理后台

- [x] 无需配合。

## Mock 和联调方式

- Mock 数据位置：仅单测 fixture。
- Mock 使用阶段：仅限单测。
- 测试接口环境：`https://test.aigcpop.com/mini_h5`
- App 测试包版本：沿用当前测试包。
- 联调步骤：
  1. App WebView 打开 `/hybird/favorites/products`。
  2. 验证 `GET /api/bff/favorites/products` 和 Java `/p/user/collection/prods`。
  3. 进入编辑态取消收藏，验证 `POST /p/user/collection/addOrCancel` body 为商品 ID。
  4. App WebView 打开 `/hybird/footprints`。
  5. 验证 `GET /api/bff/footprints` 和 Java `/p/prodBrowseLog/page`。
  6. 进入编辑态删除足迹，验证 `DELETE /p/prodBrowseLog` body 为足迹 ID 数组。
- 联调阶段是否已移除页面 mock 兜底：是。

## 真实接口渲染规则

- 首屏展示 loading，不展示 mock 业务数据。
- 接口成功后只渲染真实接口返回并经过 mapper 处理的数据。
- 商品列表为空时展示通用 `EmptyState`。
- 接口失败、超时或鉴权失败时展示 error 和重试，不回退 mock。
- BFF mapper 可以跳过缺少 `prodId` 的异常记录，但不能用本地 mock 补齐商品。

## H5 兜底策略

- 未登录或 token 缺失：展示接口错误态，提示重试或重新进入 App。
- 列表为空：展示通用空态。
- 商品图缺失：使用 `ProductImagePlaceholder`。
- 删除失败：保留当前列表并提示失败。

## 验收标准

- [ ] H5 页面成功状态可用。
- [ ] H5 页面 loading、error、empty 状态可用。
- [ ] 首屏 loading、接口成功、空数据空态、失败/重试状态均已验证。
- [ ] 联调阶段未渲染或拼接 mock 业务数据。
- [ ] API 契约与文档一致。
- [ ] 对方交付事项已确认。
- [ ] 联调环境验证通过。
- [ ] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 将“我的收藏-商品”和“我的足迹”从本地 mock 迁移到旧 Java 接口。
需要后端确认旧接口继续可用：
1. GET /p/user/collection/prods?current=<n>&size=<n>
2. POST /p/user/collection/addOrCancel，body 为 prodId
3. GET /p/prodBrowseLog/page?current=<n>&size=<n>
4. DELETE /p/prodBrowseLog，body 为 prodBrowseLogId 数组

App 侧只需继续注入 mallToken Cookie；本期不新增 Native Bridge。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-27 | H5 | 已整理 | 旧接口来自 uni-app 迁移梳理，待 App token 联调验证。 |
| 2026-06-27 | H5 | H5 已实现 | BFF、页面和本地验证已完成；待 App WebView 真实 `mallToken` 联调。 |
