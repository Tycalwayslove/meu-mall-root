# TASK-2026-0605-003 H5 搜索页

## 状态

verified

## 目标

按 Figma `喵呜APP` 搜索页节点 `95:1318` 实现 H5 搜索页 `/search`，提供搜索输入区域、AI 导购入口、热门搜索、搜索历史和喵呜热榜商品推荐的首版高保真静态体验。

## 背景

- 设计来源：`https://www.figma.com/design/bNdmC9k76qgoZtYCdYSemL/%E5%96%B5%E5%91%9CAPP?node-id=95-1318&t=5XHufdnHYAZAv5sB-4`
- Figma 文件 key：`bNdmC9k76qgoZtYCdYSemL`
- Figma node id：`95:1318`
- 页面归属：H5。
- 当前阶段没有搜索后端接口、AI 导购 Native Bridge 或管理后台配置契约，首版基于本地 mock 和 CSS 占位图块完成页面展示。

## 涉及项目

- `hybird-meumall`：新增 H5 搜索页路由、feature 组件、mock 数据和验证记录。
- 根级 `.ai-workspace`：新增本工作项。

## 范围

- 新增 `src/app/search/page.tsx`。
- 新增 `src/features/search/**`，包含页面组件、类型、mock 和渲染测试。
- 搜索页顶部适配 H5 safe area，不重复绘制原生状态栏、底部 Tab Bar 或 Home Indicator。
- 商品图使用 CSS 占位图块，不引入真实商品图片。
- 页面内交互先使用本地链接和表单语义，不接真实搜索接口。

## 不包含

- 不实现真实搜索 API、联想词 API、搜索历史持久化或热榜接口。
- 不实现 AI 导购真实对话或 Native Bridge 能力。
- 不修改首页、分类页、商品详情页、推广页、我的页等其它页面。
- 不新增依赖。

## 责任边界

- H5 负责当前页面结构、静态 mock、响应式展示和 fallback 视觉。
- 后端暂无责任，后续真实搜索结果和热榜接口需另行建立 API 契约。
- 原生 App 暂无责任，AI 导购入口首版仅作为 H5 页面内入口占位。
- 管理后台暂无责任，热门词、历史词和热榜配置首版不接后台。

## 契约影响

- 后端 API：无影响。
- Native Bridge：无影响。
- 管理后台配置：无影响。
- manifest / release / CI：无影响。

## 对接说明

本任务不涉及跨端对接，暂不创建 integration brief。后续接入真实搜索、AI 导购或后台配置时，需要新建对接说明和对应契约。

## 对方责任

- 后端：无。
- 原生 App：无。
- 管理后台：无。
- CI/发布：无。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/search/mock/search-page-data.ts`。
- 联调方式：当前无外部联调；本地启动 H5 后访问 `/hybird/search` 进行页面检查。
- 替换真实接口的位置：后续可在 `src/features/search` 下补充 server service / BFF route。

## 验收标准

- [x] `/search` 页面能在 Next App Router 下正常渲染。
- [x] 页面顶部按 H5 safe area 适配，不绘制原生状态栏和底部 Home Indicator。
- [x] 热门搜索、搜索历史、热榜 tabs、榜单提示条和商品卡片与 Figma 主结构一致。
- [x] 商品图片使用 CSS 占位图块，不引入真实商品图片。
- [x] 业务组件不写死 `/assets/...` 本地资源路径。
- [x] `pnpm typecheck` 通过。
- [x] `pnpm lint` 通过。
- [x] 相关测试通过。
- [x] 本地页面截图或浏览器检查完成并记录结果。

## 验证命令

```bash
pnpm typecheck
pnpm lint
pnpm test src/features/search/search.test.tsx
```

如本地服务可用，补充：

```bash
H5_BASE_PATH=/hybird NEXT_PUBLIC_H5_BASE_PATH=/hybird pnpm dev
```

访问 `/hybird/search` 做浏览器检查。

## 发布影响

- 不涉及 manifest schema、release API、CI 流程或灰度策略变更。
- 页面随 H5 SSR 版本发布；回滚方式沿用 H5 版本回滚。

## 风险和阻塞

- 当前 Figma 仍按实验稿处理，首版只保证结构和视觉接近，不代表最终产品验收。
- 真实搜索接口、热榜刷新规则、搜索历史来源和 AI 导购能力尚未确认。

## 实现结果

- 新增 H5 路由 `/search`，入口为 `hybird-meumall/src/app/search/page.tsx`。
- 新增 `src/features/search`，包含搜索页 mock 数据、类型、CSS module、高保真页面组件和渲染测试。
- 页面按 Figma 节点拆除原生状态栏、Home Indicator 和底部 Tab，只保留 H5 顶部 safe area 适配与页面内容。
- 商品图使用 CSS 占位，不使用 Figma 临时图片或真实商品图资源。

## 验证结果

- `pnpm test src/features/search/search.test.tsx`：通过，1 个测试文件、2 个用例通过。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，无 error；存在 4 个既有推广模块 `<img>` warning，非本任务引入。
- `curl -I http://localhost:3109/hybird/search`：返回 `HTTP/1.1 200 OK`。
- Chrome headless 截图：`hybird-meumall/.ai/test-reports/screenshots/2026-06-05-h5-search-page.png`。
- 验证记录：`hybird-meumall/.ai/test-reports/2026-06-05-h5-search-page.md`。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-05 | ready | 创建搜索页 H5 实现任务，确认首版无外部契约影响。 |
| 2026-06-05 | verified | 完成 `/search` 页面、搜索 feature、定向测试和验证记录。 |
