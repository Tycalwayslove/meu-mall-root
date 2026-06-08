# TASK-2026-0605-002 H5 首页高保真化

## 状态

verified

## 目标

按 Figma `喵呜APP` 中 `node-id=2:651` 的首页设计，将 `hybird-meumall` 现有首页低保真骨架完善为接近设计稿的 H5 页面。

## 背景

- 当前首页仍包含调试面板直出、低保真分类占位和临时模块展示。
- 用户已提供首页所需静态 PNG 资源。
- 顶部 logo、搜索栏和消息入口需要滚动吸顶，并考虑状态栏高度。

## 涉及项目

- `hybird-meumall`

## 范围

- 包含：
  - 注册首页本地静态资源。
  - 新增首页高保真数据、组件和 CSS module 样式。
  - 替换首页低保真骨架展示。
  - 首页顶部 header 使用 `position: sticky` 并通过 `env(safe-area-inset-top)` 和 `--meu-status-bar-height` 适配状态栏。
  - 推荐商品 mock 扩展到 10 条，方便滚动检查。
  - 将原首页调试内容收纳到默认折叠的 Debug 浮动面板。
- 不包含：
  - 新增真实首页运营配置接口。
  - 新增真实商品、价格、库存接口。
  - 新增 Native Bridge 契约。
  - 重复绘制原生底部 Tab、状态栏和 Home Indicator。

## 责任边界

- H5 负责页面结构、静态展示、吸顶交互、Debug 面板收纳和本地资源兜底。
- 原生 App 负责主 Tab、状态栏、Home Indicator 和系统级 WebView 容器。
- 后端暂不参与；页面数据继续使用本地 mock。

## 契约影响

- API 契约：无影响。
- Native Bridge 契约：无影响。
- Admin Config 契约：无影响。
- manifest / release：无 schema 影响，仅新增随 H5 发版的本地图片资源。

## 对接说明

无跨项目对接说明。本次是 H5 内部静态 UI 高保真化。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/home/mock/home-page-data.ts`
- 本地资源位置：`hybird-meumall/public/assets/home/`
- 联调方式：本地启动 H5 后访问 `/`，实际 basePath 路径为 `/hybird`。

## 验收标准

- [x] 首页展示 logo、搜索栏、消息入口、banner、分类宫格、活动卡和推荐商品。
- [x] 顶部 logo 和搜索栏滚动时固定在顶部，并考虑状态栏高度。
- [x] 分类图片使用可见的灰色占位图块。
- [x] `seckill-label` 不出现在活动卡，作为推荐商品中的秒杀标签展示。
- [x] 推荐商品 mock 为 10 条，页面可滚动。
- [x] 原首页调试日志和展示默认收起，通过 Debug 图标展开面板。
- [x] 本地资源通过 `localAssetUrl()` 注册解析，不在业务组件写死 `/assets/...`。
- [x] H5 不重复绘制原生底部 Tab、状态栏和 Home Indicator。
- [x] `pnpm typecheck` 通过。
- [x] `pnpm test -- src/features/home/home.test.tsx` 通过。
- [x] `pnpm lint` 通过。
- [x] 至少完成一次本地页面截图验证。

## 验证命令

- `pnpm typecheck`
- `pnpm test -- src/features/home/home.test.tsx`
- `pnpm lint`
- 本地浏览器访问 `/hybird` 截图检查

## 验证结果

- 2026-06-05：`pnpm typecheck` 通过。
- 2026-06-05：`pnpm test -- src/features/home/home.test.tsx` 通过；实际运行 23 个测试文件、123 个用例，全部通过。
- 2026-06-05：`pnpm lint` 通过；剩余 4 个 warning 来自既有推广组件 `<img>` 用法，本次首页新增组件无 lint warning。
- 2026-06-05：375x812 浏览器检查通过，首页滚动到 520px 时 header 仍为 `sticky` 且 `top=0`。
- 2026-06-05：375x812 浏览器检查通过，推荐商品为 10 条，页面高度 1882px，可滚动。
- 2026-06-05：375x812 浏览器检查通过，分类占位 10 个，首个占位为 50x50 灰色渐变图块。
- 2026-06-05：375x812 浏览器检查通过，推荐商品中检测到 5 个 `seckill-label` 图片，活动卡中未检测到 `seckill-label`。
- 2026-06-05：375x812 浏览器检查通过，Debug 面板默认收起，点击图标后展开并包含原生传参和 Hybrid Bridge 调试。
- 2026-06-05：320x700 窄屏检查通过，无坏图、无横向溢出，滚动后 header 保持 `top=0`。

## 发布影响

- 随 H5 SSR 版本发布新增静态资源。
- 不影响 manifest schema、灰度规则或回滚流程。
- 回滚目标为上一版 H5 SSR 产物。

## 风险和阻塞

- 页面仍使用本地 mock 数据；真实商品、分类、运营活动、推荐流字段后续需要后端或运营配置契约确认。
- 推荐商品图当前按用户要求使用占位图块，后续接真实商品图时需补资源字段和图片加载兜底。

## 变更记录

- 2026-06-05：创建任务并完成首页高保真化、资源注册和本地浏览器验证，状态流转为 `verified`。
- 2026-06-05：按反馈补充分类灰色占位、推荐商品 10 条、商品内秒杀标签和默认收起的 Debug 面板。
