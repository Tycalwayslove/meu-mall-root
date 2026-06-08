# TASK-2026-0605-003 H5 商品详情页

## 状态

verified

## 目标

按 Figma `喵呜APP` 文件 `bNdmC9k76qgoZtYCdYSemL` 的节点 `174:1944`，在 `hybird-meumall` 实现 H5 商品详情页高保真首版，并单独提交本任务变更。

## 背景

当前 `hybird-meumall/src/app/product/[id]/page.tsx` 仍是早期模拟电商骨架。商品详情页属于喵呜购买链路核心页面，路径为“商品详情 -> 立即购买 -> 订单确认”，且 H5 不负责绘制原生底部 Tab、iOS 状态栏和 Home Indicator。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- `/product/[id]` 商品详情页 H5 页面结构、样式和 mock 数据。
- 商品图、价格条、服务信息、规格/配送/地址、评价、详情内容、底部咨询和立即购买入口。
- 商品详情页 loading、error 或 empty 相关可恢复状态的 H5 侧兜底。
- 商品详情页相关测试和验证记录。

不包含：

- 真实商品、评价、库存、订单、支付或咨询 API。
- 真实商品图片资产接入。
- 原生底部 Tab、状态栏、Home Indicator、支付 Bridge 或 IM 咨询实现。
- 首页、分类页、搜索页、推广页、我的页等无关页面改造。

## 责任边界

`hybird-meumall`：

- 负责商品详情 H5 页面、mock 数据、展示状态、H5 路由跳转和验证记录。
- 通过现有页面入口跳转 `/consult` 和 `/order-confirm`，不实现原生支付或 IM 能力。

后端：

- 本任务无后端实现责任；真实商品接口后续另建契约。

原生 App：

- 本任务无原生实现责任；H5 不重复绘制原生 Tab、状态栏和 Home Indicator。

管理后台：

- 本任务无管理后台实现责任；商品图与运营素材后续由真实接口或 CMS/CDN 提供。

CI 或发布：

- 本任务不修改 CI 或发布链路。

## 契约影响

- 是否影响跨项目契约：否。
- 契约文档路径：无。
- 是否向后兼容：是，仅替换既有 H5 商品详情 mock 页面。
- 是否需要迁移：否。
- 是否需要灰度：否，后续随 H5 正常发版策略处理。

## 对接说明

- 是否需要对接说明：否，本轮只做 H5 mock 高保真页面，不新增跨端依赖。
- 对接说明路径：无。
- 需要确认的角色：无。
- 当前确认状态：无需确认。

## 对方责任

后端：

- 无。

原生 App：

- 无。

管理后台：

- 无。

CI 或发布：

- 无。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/product/mock/product-detail.ts`。
- 测试接口环境：无，当前不请求真实接口。
- App 测试包版本：无。
- 管理后台测试入口：无。
- 联调步骤：浏览器打开 `/hybird/product/p-1001` 或本地 dev 环境下 `/product/p-1001` 检查页面。
- H5 fallback：未知商品 ID 展示未找到状态；页面资源使用 CSS 占位块，不依赖 Figma 临时图片 URL。

## 实现计划

1. 增加商品详情页行为测试，先验证当前低保真页面未满足 Figma 核心结构。
2. 新建 `src/features/product` 类型、mock、server service 和页面组件。
3. 将 `src/app/product/[id]/page.tsx` 改为薄入口，按 ID 取 mock 数据并渲染高保真页。
4. 补充任务记录、验证记录和项目状态摘要。
5. 运行 `pnpm test`、`pnpm typecheck`、`pnpm lint`，并做本地浏览器截图检查。

## 验收标准

- [x] 商品详情页不绘制原生底部 Tab、iOS 状态栏和 Home Indicator，顶部导航考虑 safe area。
- [x] 成功态包含 Figma 核心内容：商品图占位、`V3达人专享价`、`￥2898`、商品标题、服务标签、选择/配送/地址、评价、商品详情、底部咨询输入和立即购买。
- [x] `立即购买` 跳转 `/order-confirm`，咨询输入跳转 `/consult`。
- [x] 未知商品 ID 展示可恢复的未找到状态，不白屏。
- [x] 业务组件不写死 `/assets/...`，不使用 Figma 临时图片 URL 作为正式资产。
- [x] `pnpm test`、`pnpm typecheck`、`pnpm lint` 通过，浏览器或截图检查有记录。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm test src/features/product/product-detail.test.tsx
pnpm typecheck
pnpm lint
pnpm test
```

## 发布影响

- 是否需要发布：需要随 H5 后续常规发版。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：本任务不单独要求。
- 回滚目标：回滚到本 commit 前的 H5 商品详情页版本。
- smoke check：打开 `/product/p-1001` 检查页面首屏、底部操作栏和跳转入口。

## 风险和阻塞

- 当前只使用 H5 mock 数据，不代表真实商品接口、实时价格、库存、购买资格或评价规则已完成。
- Figma 商品图资源未作为正式资产接入，页面使用 CSS 占位图块；后续真实图片应由接口或 CDN 返回完整 URL。
- 咨询入口按占位页跳转，不实现 IM 或客服能力。
- Chrome dev 截图中存在 Next dev indicator 浮层，生产构建不包含该浮层。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-05 | in_progress | 创建任务，确认本轮只做 H5 商品详情 mock 高保真页面，不新增跨项目契约。 |
| 2026-06-05 | verified | 完成商品详情页 H5 mock 高保真实现、专项/全量测试、类型检查、lint 和 375 移动端 CDP 截图验证。 |
