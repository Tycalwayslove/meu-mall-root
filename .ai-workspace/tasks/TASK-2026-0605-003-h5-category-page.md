# TASK-2026-0605-003：H5 商品分类页

## 状态

verified

## 目标

按 Figma `喵呜APP` 节点 `98:1584` 实现 H5 商品分类页 `/category` 首版高保真结构。

## 背景

- 来源设计：https://www.figma.com/design/bNdmC9k76qgoZtYCdYSemL/%E5%96%B5%E5%91%9CAPP?node-id=98-1584
- Figma 文件 key：`bNdmC9k76qgoZtYCdYSemL`
- Figma node id：`98:1584`
- 当前 H5 已有 `/category` 低保真 mock 页面，需要替换为分类页布局。
- 当前 Figma 为实验稿，分类真实业务字段和图片资产尚未确认。

## 涉及项目

- `hybird-meumall`

## 范围

- 包含：
  - `src/app/category/page.tsx`
  - `src/app/category/page.test.tsx`
  - `src/features/category/**`
  - `hybird-meumall/.ai/test-reports/2026-06-05-h5-category-page.md`
- 不包含：
  - 首页、我的页、商品详情页、搜索页、促销页和推广页改动。
  - 真实后端分类接口、BFF route、Native Bridge、manifest 和发布链路改动。
  - 真实商品分类图片资源制作。

## 责任边界

- H5 负责页面结构、视觉还原、mock 数据、占位态和 WebView 宽度适配。
- 后端暂不负责提供接口。
- 原生 App 负责底部 Tab、系统状态栏、Home Indicator 和 WebView 容器。
- 管理后台暂不负责分类配置。

## 契约影响

- API 契约：无影响，本次只使用 H5 本地 mock。
- Native Bridge 契约：无影响。
- Admin Config 契约：无影响。
- Manifest / release：无 schema 影响，后续上线仍走既有 H5 发布链路。

## 对接说明

- 不需要单独 integration brief。本任务不涉及后端、原生 App、管理后台或 CI/发布协作。

## 对方责任

- 后端：无。
- 原生 App：继续承载底部 Tab、状态栏和 Home Indicator。
- 管理后台：无。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/category/category-data.ts`
- 联调方式：首版仅本地 H5 页面和浏览器截图验证。
- 后续真实接口迁移时需新增 API 契约和 BFF。

## 验收标准

- [x] `/category` 展示白底商品分类页，顶部只绘制 H5 导航内容并考虑 safe area。
- [x] H5 不重复绘制原生底部 Tab、状态栏图标和 Home Indicator。
- [x] 左侧一级分类列表和右侧二级/三级分类网格符合 Figma 主结构。
- [x] 分类图片资源未提供时使用 CSS 占位图块，不写死 `/assets/...`。
- [x] 不引入新依赖，不改无关页面。
- [x] `pnpm test src/app/category/page.test.tsx` 通过。
- [x] `pnpm typecheck`、`pnpm lint` 和相关测试通过或记录限制。
- [x] 已完成浏览器/截图检查并记录验证结果。

## 验证命令

- `pnpm test src/app/category/page.test.tsx`
- `pnpm test`
- `pnpm typecheck`
- `pnpm lint`
- 本地启动并访问 `/hybird/category` 做浏览器截图检查。

## 发布影响

- 不修改 manifest schema、不新增 release API、不改变 SSR 发布链路。
- 页面上线可随下一次 H5 SSR 版本发布；回滚目标为上一版 H5 SSR。

## 风险和阻塞

- 真实分类名称、排序、图片和点击目标尚未由后端/后台确认；首版使用 H5 本地 mock 和 CSS 占位。
- 当前工作树存在其他 agent/用户未提交改动，本任务提交必须只包含分类页相关文件。
- 全量 `pnpm test` 当前被商品详情页既有测试失败阻塞，失败文件为 `src/features/product/product-detail.test.tsx`，不在本任务变更范围。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-05 | in_progress | 创建任务并开始 H5 商品分类页实现。 |
| 2026-06-05 | verified | 完成分类页实现、单测、类型检查、lint 和浏览器检查；全量测试旁路失败已记录到验证报告。 |
