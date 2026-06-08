# TASK-2026-0605-001 H5 我的页高保真化

## 状态

verified

## 目标

按 Figma `喵呜APP` 中 `node-id=21:1167` 的“我的”页，将 `hybird-meumall` 现有 `/mine` 低保真骨架完善为接近设计稿的 H5 页面。

## 背景

- 当前 `/mine` 页面仍使用模拟色块 icon 和低保真样式。
- 用户已提供本次页面所需静态 PNG 资源。
- “我的”页除设置外的二级页面暂定 H5；本次只做主页面静态展示和现有路由跳转，不新增后端、Native Bridge 或管理后台依赖。

## 涉及项目

- `hybird-meumall`

## 范围

- 包含：
  - 注册“我的”页本地静态资源。
  - 新增 `src/features/mine` 页面数据、组件和样式。
  - 替换 `/mine` 页面低保真实现。
  - 保留 H5 页面安全区和 WebView 宽度适配。
- 不包含：
  - 新增真实用户、订单、钱包、优惠券接口。
  - 新增 Native Bridge、支付、分享或设置页原生跳转。
  - 重复绘制原生状态栏、底部 Tab 和 Home Indicator。

## 责任边界

- H5 负责页面结构、静态展示、现有 H5 路由跳转和本地资源兜底。
- 原生 App 负责主 Tab、状态栏、Home Indicator、设置页最终归属和系统级能力。
- 后端暂不参与；页面数据继续使用本地 mock。

## 契约影响

- API 契约：无影响。
- Native Bridge 契约：无影响。
- Admin Config 契约：无影响。
- manifest / release：无 schema 影响，仅新增随 H5 发版的本地图片资源。

## 对接说明

无跨项目对接说明。本次是 H5 内部静态 UI 高保真化。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/mine/mock/data.ts`
- 本地资源位置：`hybird-meumall/public/assets/mine/`
- 联调方式：本地启动 H5 后访问 `/mine`。

## 验收标准

- [x] `/mine` 成功态展示用户信息、达人权益卡、订单状态、活动 banner、服务与工具。
- [x] 页面不再使用临时色块作为订单和工具 icon。
- [x] 本地资源通过 `localAssetUrl()` 注册解析，不在业务组件写死 `/assets/...`。
- [x] H5 不重复绘制原生状态栏、底部 Tab 和 Home Indicator。
- [x] 常见 WebView 宽度下文案不溢出、主要模块不重叠。
- [x] `pnpm typecheck` 通过。
- [x] 至少完成一次本地页面截图验证。

## 验证命令

- `pnpm typecheck`
- `pnpm lint`
- 本地浏览器或 WebView 访问 `/mine` 截图检查

## 验证结果

- 2026-06-05：`pnpm typecheck` 通过。
- 2026-06-05：`pnpm lint` 通过；剩余 4 个 warning 来自既有推广组件 `<img>` 用法，本次 `/mine` 新增组件无 lint warning。
- 2026-06-05：本地 dev 服务 `http://127.0.0.1:3109`，实际 basePath 路径 `http://localhost:3109/hybird/mine` 通过浏览器检查。
- 2026-06-05：375x812 截图检查通过，15 张本地图片全部加载成功，无坏图。
- 2026-06-05：320x812 窄屏检查通过，无坏图，未检测到文本横向溢出。
- 2026-06-05：替换顶部背景和右侧角色图片后复验通过，`hero-bg.png` 按 375x250 展示，`hero-role.png` 按 116x70 展示，无坏图。

## 发布影响

- 随 H5 SSR 版本发布新增静态资源。
- 不影响 manifest schema、灰度规则或回滚流程。
- 回滚目标为上一版 H5 SSR 产物。

## 风险和阻塞

- 当前仍使用本地 mock 数据，真实钱包、优惠券、订单和用户信息字段后续需要后端契约确认。
- Figma 中头像和右侧角色形象未在本次本地资源清单中提供，首版使用 H5 内部视觉兜底。

## 变更记录

- 2026-06-05：创建任务并进入实现。
- 2026-06-05：完成 `/mine` 高保真化、资源注册和本地浏览器验证，状态流转为 `verified`。
- 2026-06-05：按补充静态资源替换顶部背景和右侧卡通人物。
