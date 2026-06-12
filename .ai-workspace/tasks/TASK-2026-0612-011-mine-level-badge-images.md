# TASK-2026-0612-011-mine-level-badge-images

## 状态

verified

## 目标

将 H5 我的页 `/mine` 用户昵称后的达人等级从文字样式改为对应的 V1-V5 图片徽章。

## 背景

当前 `/mine` 的用户信息区在昵称后用文字拼接 `levelCode + levelLabel` 展示达人等级，例如 `V3黄金达人`。设计素材已提供五档图片徽章，需要在个人中心中按等级展示图片。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 新增我的页等级徽章本地 PNG 资源。
- 将资源注册到 H5 local asset registry。
- `/mine` 用户昵称后展示对应图片徽章，并保留可访问文本。
- 补充资源 URL 回归验证。

不包含：

- 不修改商品详情、订单确认或其它页面。
- 不新增或调整后端接口。
- 不修改 Native Bridge、manifest、发布链路或管理后台配置。
- 不调整达人等级规则。

## 责任边界

`hybird-meumall`：

- 负责本地静态资源接入和 `/mine` 页面展示。

`server-meumall`：

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

- Mock 数据位置：`hybird-meumall/src/features/mine/mock/data.ts`
- 测试接口环境：无
- App 测试包版本：无
- 管理后台测试入口：无
- 联调步骤：本地打开 `/hybird/mine` 查看昵称后的等级图片。
- H5 fallback：资源仍通过 `localAssetUrl()` 拼接 basePath；缺少真实等级接口时继续使用当前 mock 等级。

## 实现计划

1. 将 V1-V5 等级图片复制到 `hybird-meumall/public/assets/mine/level-badges/`。
2. 在 `src/lib/assets/local-assets.ts` 注册 `mine.levelBadge.v1-v5`。
3. 扩展我的页 profile 数据结构并在 `/mine` 展示图片徽章。
4. 运行资源和页面相关验证。

## 验收标准

- [x] `/mine` 用户昵称后的等级展示为图片，不再是文字胶囊。
- [x] V1-V5 图片资源均通过 `localAssetUrl()` 解析，带 basePath 时路径正确。
- [x] 不触碰商品详情相关实现文件。
- [x] 最小验证命令通过，或失败原因已记录。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/lib/assets/asset-url.test.ts
pnpm typecheck
```

## 发布影响

- 是否需要发布：需要随 H5 常规发版进入对应环境。
- 发布项目：`hybird-meumall`
- 是否需要灰度：否
- 回滚目标：回滚到上一版 H5 SSR 产物。
- smoke check：打开 `/hybird/mine` 检查等级图片展示和资源 200。

## 风险和阻塞

- 当前 `/mine` 仍使用 mock 用户数据，真实用户等级接口接入后需要继续映射同一资源 key 或同等字段。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-12 | ready | 创建任务，确认无跨项目契约影响。 |
| 2026-06-12 | verified | 已接入 `/mine` 等级横条图片资源，并通过资源单测、类型检查、本地 HTTP smoke 和 Chrome headless 截图检查。 |
