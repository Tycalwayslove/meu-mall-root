# 对接说明：推广模块首批 H5 页面与 BFF Mock

## 基本信息

- 编号：BRIEF-2026-0604-002
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0604-002-promotion-pages-bff-foundation.md`
- 状态：h5-verified
- H5 负责人：待补充
- 后端负责人：待确认
- 原生 App 负责人：待确认
- 管理后台负责人：待确认
- 目标联调时间：待排期
- 目标上线环境：测试环境

## 需求背景

推广模块需要开始正式页面开发，但真实后端服务尚未完成。H5 侧先基于 Figma 最新设计和 BFF mock 实现高保真页面，同时把后续后端、原生 App、管理后台需要关注的边界提前说明清楚。

## H5 侧目标

首批完成推广首页和关键二级页面的高保真 H5 实现。页面需要能在 App WebView 中通过 active manifest 拼接后的 URL 打开，首屏通过 SSR 渲染 mock 数据，页面内交互通过 H5 路由和 BFF mock 完成。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 推广首页 | `/promotion` | H5 | 五档达人等级主题，高保真完整实现。 |
| 活动中心 | `/promotion/activities` | H5 | 展示奖励活动列表。 |
| 榜单中心 | `/promotion/rank-center` | H5 | 展示达人榜、战队榜入口。 |
| 达人销量榜 | `/promotion/ranking/sales` | H5 | 独立榜单详情路由。 |
| 达人销售额榜 | `/promotion/ranking/amount` | H5 | 独立榜单详情路由。 |
| 达人权益中心 | `/promotion/benefits?level=v1` | H5 | query 控制 V1-V5，方便调试。 |

## 数据流

```text
App 读取 active manifest
  -> App 拼接 H5 URL
  -> WebView 打开 H5 路由
  -> Next SSR 调用 H5 server service
  -> 当前读取 BFF mock 数据
  -> 后续切换为 Java / Python 后端接口
  -> H5 渲染页面和 fallback
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 后续需要 | 当前 H5 先用 mock，后续需要真实推广首页、活动、榜单、权益接口。 | `.ai-workspace/contracts/api/promotion-bff-mock-contract.md` |
| 调整接口 | 否 | 当前没有既有推广接口。 | 无 |
| 鉴权 | 是 | 后续正式接口由 H5 BFF 将 `pythonToken` / `mallToken` 转为 `Authorization`。 | `h5-bff-http-auth-contract.md` |
| 缓存策略 | 是 | 推广首页和权益为用户态 no-store，榜单可短 TTL，首版先 no-store。 | 待后端确认 |
| 错误码 | 是 | 后续需要后端提供业务错误码，H5 当前先按 BFF 统一错误处理。 | 待后端确认 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本批页面首版不新增 Bridge 能力。 | 无 |
| 原生页面跳转 | 是 | App 只需要按路由打开 H5。 | 既有 H5 路由接入说明 |
| 登录态 | 是 | App 继续写入 `pythonToken`、`mallToken`、`statusHeight` Cookie。 | `h5-bff-http-auth-contract.md` |
| 最低 App 版本 | 待确认 | 只依赖现有 WebView 和 Cookie 注入能力。 | 待确认 |
| fallback | 是 | H5 自身处理错误态；App 只需处理 H5 URL 打不开时的通用错误。 | 待确认 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 后续可能 | 活动入口、工具入口、权益规则未来可能运营配置。 | 后续新增 |
| 素材管理 | 后续可能 | 等级徽章、活动图标后续可能由资产体系管理。 | 后续新增 |
| 上下线开关 | 后续可能 | 活动中心和入口卡可能需要上下线。 | 后续新增 |
| 排序规则 | 后续可能 | 工具入口、活动卡、榜单入口可能需要排序。 | 后续新增 |
| 灰度规则 | 否 | 页面发布灰度由 H5 manifest 管控。 | release governance |

## H5 侧责任

- [x] 页面结构和状态。
- [x] H5 BFF mock 和 server service。
- [x] loading、error、empty、未登录状态。
- [x] 数据模型和 mock 数据。
- [x] 本地验证。

## 对方责任

### 后端

- [ ] 后续确认推广模块真实 API 的字段、错误码、鉴权和测试数据。
- [ ] 确认榜单刷新周期、榜单维度、隐私脱敏规则。
- [ ] 确认达人等级、佣金比例、权益和升级规则。

### 原生 App

- [ ] 按 active manifest 拼接并打开 H5 路由。
- [ ] 继续提供 Cookie 登录态和状态栏高度。
- [ ] 确认底部 Tab 仍由原生渲染。

### 管理后台

- [ ] 当前无必须交付项。
- [ ] 后续确认活动、权益和工具入口是否需要后台配置。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/promotion/mock/`。
- 测试接口环境：当前为 H5 BFF mock。
- App 测试包版本：待原生同事提供。
- 管理后台测试入口：当前无。
- 联调步骤：
  1. H5 本地或测试环境部署 candidate。
  2. App 读取 active manifest 并打开 `/promotion`。
  3. 分别打开活动中心、榜单中心、销量榜、销售额榜和权益页。
  4. 对照 Figma 和 mock 数据检查 UI、跳转、状态。
  5. 后端接口 ready 后，将 BFF mock 替换为后端调用并复测。

## H5 兜底策略

- 接口失败：展示错误态和重试按钮。
- 空列表：展示空态，不隐藏页面主体。
- 未登录或 token 缺失：展示登录态异常提示，后续可通过 App 登录能力恢复。
- 等级未知：降级到 V1 新锐达人主题。
- 素材缺失：使用占位组件。
- App 底部 Tab：H5 不渲染，避免与原生重复。

## 验收标准

- [x] H5 页面成功状态可用。
- [x] H5 页面 loading、error、empty 状态可用。
- [x] BFF mock 契约与文档一致。
- [x] 后续对接方责任已明确。
- [x] 本地 `pnpm test`、`pnpm typecheck`、`pnpm build` 通过。
- [x] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 推广模块首批页面会先基于 mock 开发，不阻塞后端。

App 侧需要关注：
1. 继续通过 active manifest 拼接 H5 URL。
2. 本批 H5 路由包括 /promotion、/promotion/activities、/promotion/rank-center、/promotion/ranking/sales、/promotion/ranking/amount、/promotion/benefits?level=v1。
3. 底部 Tab 仍由原生负责，H5 不绘制底部 Tab。
4. Cookie 继续提供 pythonToken、mallToken、statusHeight。

后端侧后续需要确认：
1. 推广首页、活动、榜单、权益和达人等级真实接口。
2. 榜单刷新周期、隐私脱敏、错误码和缓存策略。
3. 达人等级佣金比例、福利、升级规则。

当前契约文档：
.ai-workspace/contracts/api/promotion-bff-mock-contract.md
```

## 确认记录

| 日期 | 角色 | 结论 |
| --- | --- | --- |
| 2026-06-04 | H5 | 首批页面、BFF mock、server service、状态兜底、测试和构建已完成；后续等待真实后端接口、达人规则和 App 联调确认。 |

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-04 | H5 | 暂用 mock | 用户确认路由方案、query 调试权益页、榜单独立路由和 mock 字段可先由 H5 补齐。 |
