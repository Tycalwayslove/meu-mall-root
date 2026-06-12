# TASK-2026-0612-012-mine-secondary-pages

## 状态

verified

## 目标

按 Figma 参考先实现个人中心二级页的静态高保真 H5 页面：钱包、我的收藏、我的足迹、编辑态、我的优惠券和订单列表。

## 背景

`/mine` 已完成主页面骨架和入口，但个人中心二级页仍多为旧低保真占位。用户提供了钱包、收藏、足迹、编辑态、优惠券和订单列表的 Figma 节点，需要先完成静态 mock 页面，供后续真实接口接入前验证页面路径和视觉结构。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 新增 `/wallet`、`/footprints`、`/coupons` 页面。
- 重做 `/favorites/products` 和 `/orders` 为 Figma 对应样式。
- 收藏和足迹共用商品横卡与编辑态。
- 订单页支持 status query 初始 tab 和空状态。
- `/mine` 钱包余额、我的足迹、优惠券入口跳转到对应二级页。

不包含：

- 不接真实后端接口。
- 不实现提现、删除、下单、联系商家等真实业务动作。
- 不修改商品详情、订单确认、BFF、Native Bridge、manifest 或发布链路。
- 不实现店铺收藏页重做。

## 责任边界

`hybird-meumall`：

- 负责 H5 静态页面、mock 数据、路由和本地验证。

其它项目：

- 无需变更。

## 契约影响

- 是否影响跨项目契约：否
- 契约文档路径：无
- 是否向后兼容：是
- 是否需要迁移：否
- 是否需要灰度：否

## 对接说明

- 是否需要对接说明：否
- 对接说明路径：无
- 需要确认的角色：无
- 当前确认状态：无需确认

## 对方责任

后端：

- 无

原生 App：

- 无

管理后台：

- 无

CI 或发布：

- 无

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/mine-secondary/mock/data.ts`
- 测试接口环境：无
- App 测试包版本：无
- 管理后台测试入口：无
- 联调步骤：本地打开 `/hybird/wallet`、`/hybird/favorites/products`、`/hybird/footprints`、`/hybird/coupons`、`/hybird/orders`。
- H5 fallback：暂无真实接口依赖，页面全部使用本地 mock。

## 实现计划

1. 先写 `mine-secondary` 页面渲染测试，并确认缺组件失败。
2. 新增 mock 数据和四类页面组件。
3. 新增/替换对应 App Router 路由。
4. 更新 `/mine` 入口链接。
5. 跑 focused test、typecheck 和本地 HTTP smoke。

## 验收标准

- [x] 钱包页展示余额卡、提现按钮、结算 tab、筛选和流水列表。
- [x] 我的收藏页展示 Figma 横向商品卡，并支持编辑态底部操作条。
- [x] 我的足迹页复用同款横向商品卡，并支持编辑态。
- [x] 我的优惠券页展示可使用数量和三张券卡。
- [x] 订单页展示搜索、五个状态 tab、订单卡片和空状态。
- [x] `/mine` 钱包余额可进入钱包页。
- [x] 不触碰商品详情相关实现文件。
- [x] 最小验证命令通过，或失败原因已记录。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/features/mine-secondary/mine-secondary-pages.test.tsx src/lib/assets/asset-url.test.ts
pnpm typecheck
```

## 发布影响

- 是否需要发布：需要随 H5 常规发版进入对应环境。
- 发布项目：`hybird-meumall`
- 是否需要灰度：否
- 回滚目标：回滚到上一版 H5 SSR 产物。
- smoke check：打开个人中心二级页路由并检查页面 200 和首屏内容。

## 风险和阻塞

- 当前只是静态 mock；后续接真实接口时需要补 API 契约、loading/error/empty 和真实状态映射。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-12 | in_progress | 创建任务，开始静态高保真实现。 |
| 2026-06-12 | verified | 已完成钱包、收藏、足迹、优惠券和订单静态页面，focused test、typecheck、HTTP smoke 和 Chrome 截图检查通过。 |
