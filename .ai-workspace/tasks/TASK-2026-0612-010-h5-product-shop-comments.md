# TASK-2026-0612-010 H5 商品详情店铺与评论概要

## 状态

verified

## 目标

继续补齐迁移向导“第一步：搭建只读商品详情”中尚未接入的评论概要和详情页展示逻辑。商品详情页通过现有 H5 BFF 聚合 Java 商品详情、店铺头部、评论统计和前两条评论；店铺头部仅保留在 BFF modules 供后续链路使用，页面中该位置展示评价模块。

## 背景

当前商品详情已接入 `/prod/prodInfo`、SKU、立即购买、订单确认和 `content` 富文本，但迁移向导第一阶段还要求展示店铺和评论概要。旧 uni-app 商品详情首屏会调用：

- `GET /shop/headInfo?shopId=<shopId>`
- `GET /prod/prodCommData?prodId=<prodId>&stationId=`
- `GET /prod/prodCommPageByProd?prodId=<prodId>&size=10&current=1&evaluate=-1&stationId=`

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 扩展 `/api/bff/product-detail?prodId=<prodId>` 聚合店铺和评论概要。
- 店铺接口失败不拖垮商品详情主数据。
- 评论接口失败不拖垮商品详情主数据。
- 商品详情页不展示店铺卡片，该位置展示评价数量、好评率、评价标签和最多前两条评论。
- 商品主图支持旧项目 `prod-imgs-video` 语义：视频首帧 + 图片混合轮播、切换和预览播放。
- 商品主图轮播支持触屏横滑和鼠标拖拽切换。
- 商品主图轮播支持横向轨道切换动画。
- 售后保障按 `afterSaleType`、`afterSaleContent` 映射；无字段时不展示静态兜底。
- 资质条按 `prodCertificateRecordDtoList` 映射。
- 评论图片相对路径按 `JAVA_OSS_ASSET_BASE_URL` 拼接。
- 补充测试、API 文档、任务和验证记录。

不包含：

- 店铺详情页路由。
- 评论完整列表页或弹层分页。
- 店铺收藏、进店、客服、推荐商品。
- 秒杀、拼团、自提、同城、正式下单和支付。

## 责任边界

`hybird-meumall`：

- 负责 BFF 聚合、mapper、页面展示和兜底。
- 浏览器端仍只请求 H5 BFF，不直接请求 Java 后端。

后端：

- 继续提供旧 Java 接口。
- 不需要新增接口。

原生 App：

- 无新增依赖。

管理后台：

- 无新增依赖。

## 契约影响

- 是否影响跨项目契约：是，扩展商品详情 BFF 的 `modules` 和 `view` 字段。
- 契约文档路径：`.ai-workspace/contracts/api/h5-product-detail-real-flow-contract.md`
- 是否向后兼容：是，新增可选字段。
- 是否需要迁移：否。
- 是否需要灰度：随 H5 常规灰度。

## 对接说明

- 是否需要对接说明：复用 `.ai-workspace/integration-briefs/BRIEF-2026-0611-008-h5-product-detail-real-flow.md`。
- 需要确认的角色：后端 / QA。
- 当前确认状态：H5 侧按旧接口兼容字段实现；字段差异在联调中回写契约。

## 对方责任

后端：

- 确认 `/shop/headInfo`、`/prod/prodCommData` 和 `/prod/prodCommPageByProd` 在测试环境可用。
- 保持 Java `Authorization: <mallToken>` 鉴权方式。

原生 App：

- 无。

管理后台：

- 无。

## Mock 和联调方式

- 测试接口环境：`JAVA_API_BASE_URL=https://test.aigcpop.com/mini_h5`
- 联调步骤：
  1. 打开 `/hybird/product/1000054`。
  2. 检查 BFF 日志包含商品详情、店铺头部、评论统计和评论分页请求。
  3. 检查商品详情页展示店铺名称和评论概要。
  4. 任一辅助接口失败时，商品主信息仍可展示。

## 验收标准

- [x] `/api/bff/product-detail` 成功响应包含店铺 view 数据。
- [x] `/api/bff/product-detail` 成功响应包含评论统计和最多前两条评论。
- [x] 店铺或评论接口失败不导致商品详情主数据失败。
- [x] 浏览器端仍只请求 H5 BFF。
- [x] 商品详情页不展示店铺卡片，评论概要模块固定展示。
- [x] 商品主图支持视频和图片混合轮播、切换、预览和播放。
- [x] 商品主图支持触屏横滑和鼠标拖拽切换。
- [x] 商品主图切换有横向滑动动画。
- [x] 售后保障和资质条按旧项目字段逻辑映射。
- [x] 评论图片相对路径按 OSS base URL 拼接。
- [x] `pnpm test`、`pnpm typecheck`、`pnpm lint`、`pnpm run build` 通过或限制已记录。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/product/product-real-flow.test.tsx src/features/product/product-detail.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
curl http://localhost:3109/hybird/api/bff/product-detail?prodId=1000054\&addrId=0\&dvyType=1
Browser: http://localhost:3109/hybird/product/1000054
```

## 发布影响

- 是否需要发布：需要随 H5 常规发版。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：建议按 H5 常规灰度。
- 回滚目标：回滚到本任务前无店铺和评论概要的商品详情页。
- smoke check：打开 `/hybird/product/1000054`，确认店铺卡片不可见、评论概要可见、主图可切换。

## 风险和阻塞

- 旧接口字段在不同商品或店铺类型下可能不一致，H5 mapper 需要保守兼容。
- 真实成功态仍依赖有效 `mallToken`。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-12 | ready | 继续补齐迁移向导第一步中的店铺信息和评论概要。 |
| 2026-06-12 | verified | 已扩展商品详情 BFF 聚合店铺头部、评论统计和评论分页；页面不再展示店铺卡片，改为按 Figma 展示评论概要。 |
| 2026-06-12 | verified | 已迁移旧 `prod-imgs-video`、售后保障和资质条展示逻辑到当前 Next.js 商品详情页。 |

## 验证结果

验证记录：`hybird-meumall/.ai/test-reports/2026-06-12-product-shop-comments.md`

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/product/product-real-flow.test.tsx src/features/product/product-detail.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
```

结果：

- 商品相关测试：2 files / 13 tests 通过。
- 全量测试：43 files / 218 tests 通过。
- TypeScript：通过。
- ESLint：0 errors，4 warnings；warning 均为 promotion 模块既有 `<img>` 规则提示，不属于本次商品详情改造。
- Next build：通过，构建产物包含 `/api/bff/product-detail` 和 `/product/[id]`。
- 本地 BFF smoke：`/hybird/api/bff/product-detail?prodId=1000054&addrId=0&dvyType=1` 返回 200，包含店铺和评论数据。
- 本地浏览器 smoke：`/hybird/product/1000054` 渲染真实商品、评价数量、好评率、前两条评论和富文本详情图；店铺卡片不可见；点击主图下一张后角标从 `1/6` 切到 `2/6`。
- 本地浏览器 drag smoke：在主图真实坐标内鼠标左滑后，角标从 `1/6` 切到 `2/6`。
- 本地浏览器 animation smoke：媒体轨道存在 transform transition，切换后轨道平移到 `-430px`。

## 已知限制

- 真实 App WebView 注入上下文仍需端上联调确认。
- 本期只展示首屏评论概要，不实现店铺详情跳转、评论完整列表或店铺收藏。
