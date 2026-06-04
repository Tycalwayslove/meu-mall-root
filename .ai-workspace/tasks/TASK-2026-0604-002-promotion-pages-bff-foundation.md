# TASK-2026-0604-002-promotion-pages-bff-foundation

## 状态

verified

## 目标

为推广模块首批高保真页面建立正式开发入口，包括页面范围、路由、BFF mock 契约、渲染策略、设计来源、资产占位规则和验收标准。后续实现应基于本任务推进，而不是继续沿用现有低保真页面骨架。

## 背景

当前 `hybird-meumall` 已存在 `/promotion`、`/promotion/ranking`、`/promotion/benefits` 等低保真占位页面，但真实后端服务尚未完成。用户希望优先开发样式变化较多、业务后端依赖较轻的推广模块页面，并通过 H5 BFF mock 先稳定页面数据结构，等后端完成后再迁移到真实业务接口。

2026-06-04 已重新获取 Figma 最新设计图。推广首页按 V1-V5 五个达人等级分别提供设计稿，二级页面包括活动中心、榜单中心、达人销量榜、达人销售额榜和达人权益页。达人等级规则当前只作为展示参考，升级门槛、GMV 阈值和福利细则后续继续确认。

## 涉及项目

- `hybird-meumall`
- 根级 AI 工作区 `.ai-workspace`

## 范围

包含：

- 明确首批推广页面路由。
- 明确页面 SSR / CSR / ISR 策略。
- 定义 H5 BFF mock 数据契约。
- 定义推广首页五档主题与权益等级数据模型。
- 定义活动中心、榜单中心、榜单详情、权益中心的 mock 字段。
- 定义图片、icon、等级徽章的首版占位和后续替换规则。
- 创建页面开发总则，放入 `hybird-meumall/src/features/promotion/PAGE_DEVELOPMENT_GUIDE.md`。

不包含：

- 不接入真实 Java / Python 后端接口。
- 不实现管理后台配置页面。
- 不下载 Figma 临时图片 URL 作为正式资产。
- 不实现原生 App 底部 Tab。
- 不确定最终达人升级销量、GMV 或福利细则。

## 责任边界

`hybird-meumall`：

- 实现推广页面 UI、路由、状态、H5 BFF mock、加载态、空态、错误态和 fallback。
- 通过 BFF / server service 读取 Cookie token 后再调用后端，浏览器端不直接持有 token。
- 只消费 Native 提供的 WebView 容器、登录态和状态栏高度，不实现原生登录、底部 Tab 或原生页面。

后端：

- 后续提供正式推广首页、活动、榜单、权益和达人等级接口。
- 确认真实字段、错误码、鉴权、缓存策略和测试数据。

原生 App：

- 继续负责底部 Tab、WebView 打开 H5 URL、Cookie 注入和状态栏高度传递。
- 不需要为本批页面新增 Native Bridge 能力。

管理后台：

- 后续如需配置推广活动、榜单入口、工具入口或权益规则，再建立管理后台配置契约。
- 当前阶段 H5 使用 mock 默认配置，不要求后台先完成。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/api/promotion-bff-mock-contract.md`。
- 是否向后兼容：新增 H5 BFF mock 契约，向后兼容。
- 是否需要迁移：后续从 mock 迁移到真实后端时需要更新契约。
- 是否需要灰度：页面正式发布时建议走 H5 candidate，再由 manifest 切 active。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0604-002-promotion-pages-bff-foundation.md`。
- 需要确认的角色：后端 / 原生 App / 管理后台 / 测试。
- 当前确认状态：暂用 mock。

## 对方责任

后端：

- 暂不阻塞 H5 高保真开发。
- 后续确认推广模块真实 API、字段、鉴权、缓存、错误码和测试数据。

原生 App：

- 确认本批 H5 路由由 App 通过 active manifest 拼接后打开。
- 确认底部 Tab 由原生负责，H5 页面不绘制底部 Tab。
- 继续通过 Cookie 提供 `pythonToken`、`mallToken`、`statusHeight`。

管理后台：

- 当前无必须交付项。
- 后续若活动、工具入口和权益规则需要运营配置，再按配置契约实现。

CI 或发布：

- 后续页面实现完成后构建 H5 candidate，测试通过后再切 active。

## Mock 和联调方式

- Mock 数据位置：建议 `hybird-meumall/src/features/promotion/mock/`。
- BFF 路由位置：建议 `hybird-meumall/src/app/api/bff/promotion/**/route.ts`。
- 测试接口环境：当前无真实后端，使用 H5 BFF mock。
- App 测试包版本：沿用当前测试环境 App WebView 壳。
- 管理后台测试入口：当前无。
- 联调步骤：
  1. App 读取 active manifest。
  2. App 拼接并打开 `/promotion` 或对应二级 H5 路由。
  3. H5 SSR 读取 BFF mock 数据渲染首屏。
  4. 页面内点击活动、榜单、权益和工具入口完成 H5 内跳转。
  5. 后端接口完成后，将 BFF mock service 替换为 backend client 调用。
- H5 fallback：
  - BFF 异常：展示错误态和重试。
  - 数据为空：展示空态，不白屏。
  - 等级未知：降级为 V1 新锐达人主题。
  - 素材缺失：使用占位组件，不请求 Figma 临时 URL。

## 页面与路由

| 页面 | 路由 | 渲染策略 | 说明 |
| --- | --- | --- | --- |
| 推广首页 | `/promotion` | SSR dynamic | 五档达人等级数据驱动主题，高保真完整实现。 |
| 活动中心 | `/promotion/activities` | SSR dynamic | 展示奖励活动列表和活动状态。 |
| 榜单中心 | `/promotion/rank-center` | SSR dynamic | 展示达人榜、战队榜入口。 |
| 达人销量榜 | `/promotion/ranking/sales` | SSR dynamic + CSR tab | 独立路由，支持日榜/周榜/月榜切换。 |
| 达人销售额榜 | `/promotion/ranking/amount` | SSR dynamic + CSR tab | 独立路由，支持日榜/周榜/月榜切换。 |
| 达人权益中心 | `/promotion/benefits?level=v1` | SSR dynamic | 使用 query 方便调试 V1-V5，不拆五个页面。 |

## Figma 来源

| 页面 | Figma node |
| --- | --- |
| 推广首页 V1 新锐 | `238:5541` |
| 推广首页 V2 白银 | `210:4048` |
| 推广首页 V3 黄金 | `205:2892` |
| 推广首页 V4 星钻 | `211:4223` |
| 推广首页 V5 至尊 | `211:4398` |
| 达人徽章切图参考 | `241:5762` |
| 活动中心 | `253:5369` |
| 榜单中心 | `253:5747` |
| 达人销量榜 | `270:5973` |
| 达人销售额榜 | `277:6570` |
| 权益中心 V1 | `253:3892` |
| 权益中心 V2 | `253:3652` |
| 权益中心 V3 | `253:3406` |
| 权益中心 V4 | `253:3156` |
| 权益中心 V5 | `61:483` |

## 实现计划

1. 已建立 `src/features/promotion/` 目录结构、类型、mock 数据和 server service。
2. 已增加 `/api/bff/promotion/home`、`/activities`、`/rank-center`、`/rankings/sales`、`/rankings/amount`、`/benefits` mock BFF。
3. 已重写 `/promotion` 为高保真 SSR 页面，并移除设计稿中的原生底部 Tab。
4. 已实现活动中心、榜单中心、销量榜、销售额榜和权益中心高保真页面。
5. 已为 BFF mock、数据映射和关键状态增加测试。
6. 已运行 typecheck、test、build 和本地路由 smoke。

## 验收标准

- [x] `/promotion` 可根据 mock 用户等级展示 V1-V5 不同主题。
- [x] `/promotion/activities` 高保真还原活动中心，并支持 loading、empty、error。
- [x] `/promotion/rank-center` 高保真还原榜单中心。
- [x] `/promotion/ranking/sales` 和 `/promotion/ranking/amount` 独立路由可访问，榜单 tab 交互可用。
- [x] `/promotion/benefits?level=v1-v5` 可调试五档权益主题。
- [x] 页面不绘制原生底部 Tab，不保留 Figma Home Indicator。
- [x] Figma 临时图片 URL 不进入正式代码，图片和 icon 先使用可替换的占位组件或本地资产入口。
- [x] BFF mock 响应结构符合 `.ai-workspace/contracts/api/promotion-bff-mock-contract.md`。
- [x] 私有数据页面默认 no-store，不使用 ISR。
- [x] `pnpm test`、`pnpm typecheck`、`pnpm build` 通过。

## 验证命令

```bash
cd hybird-meumall
pnpm test
pnpm typecheck
pnpm build
```

## 发布影响

- 是否需要发布：页面实现完成后需要。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：建议先发布 candidate，测试通过后切 active。
- 回滚目标：上线前的 active H5 版本。
- smoke check：
  - `GET /api/health`
  - `GET /promotion`
  - `GET /promotion/activities`
  - `GET /promotion/rank-center`
  - `GET /promotion/ranking/sales`
  - `GET /promotion/ranking/amount`
  - `GET /promotion/benefits?level=v1`

## 风险和阻塞

- 真实后端接口未完成，当前只能完成 H5 mock 阶段，不能声称真实业务联调完成。
- 达人等级升级门槛、月销量、月 GMV 和福利细则仍未最终确认，首版只做展示参考。
- Figma 中存在原生状态栏和底部 Tab 元素，H5 实现时必须按 App/H5 职责剥离。
- V5 首页存在极大金额样例，正式实现需要处理长数字溢出。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-04 | ready | 创建推广模块首批页面、BFF mock 和开发总则任务。 |
| 2026-06-04 | verified | 完成推广首页、活动中心、榜单中心、榜单详情、权益中心、BFF mock、单测、类型检查、构建和本地路由 smoke。 |
