# TASK-2026-0627-005 H5 我的收藏与我的足迹真实接口迁移

## 状态

implemented

## 目标

将 `hybird-meumall` 当前 `/favorites/products` 和 `/footprints` 从本地 mock 页面迁移为真实 Java 接口渲染，并复刻旧 uni-app 的商品收藏、浏览足迹列表和删除逻辑。

## 背景

个人中心二级页中“我的收藏”和“我的足迹”仍使用本地 mock。用户要求与订单列表迁移一起补齐收藏和足迹，让页面使用旧项目同一套 Java 接口。

## 涉及项目

- `hybird-meumall`：页面、BFF、mapper、feature API adapter、测试和项目文档。
- Java 业务后端：沿用旧接口，不新增接口。

## 范围

- 包含：
  - `/favorites/products` 商品收藏列表。
  - `/footprints` 浏览足迹列表。
  - 商品收藏取消。
  - 足迹批量删除。
  - loading、empty、error 和重试态。
  - BFF 契约测试和 mapper 单测。
  - 仓库事实源和飞书知识库同步。
- 不包含：
  - `/favorites/shops` 店铺收藏。
  - 商品详情页内收藏状态切换。
  - 浏览足迹写入接口。
  - 收藏/足迹搜索、筛选或复杂分组改版。

## 责任边界

- H5 负责调用 BFF、展示真实接口数据、删除操作、失败兜底和客户端交互。
- Java 后端负责旧接口数据、鉴权、分页、删除和取消收藏语义。
- 原生 App 只需继续向 H5 写入有效 `mallToken`；本任务不新增 Native Bridge。

## 契约影响

- 新增 API 契约：`.ai-workspace/contracts/api/h5-favorites-footprints-real-api-contract.md`
- H5 BFF 新增：
  - `GET /api/bff/favorites/products`
  - `POST /api/bff/favorites/products/cancel`
  - `GET /api/bff/footprints`
  - `DELETE /api/bff/footprints/delete`
- Java 接口沿用：
  - `GET /p/user/collection/prods`
  - `POST /p/user/collection/addOrCancel`
  - `GET /p/prodBrowseLog/page`
  - `DELETE /p/prodBrowseLog`

## 对接说明

- `.ai-workspace/integration-briefs/BRIEF-2026-0627-005-h5-favorites-footprints-real-api.md`

## 对方责任

- Java 后端保持旧接口入参、响应和鉴权口径可用。
- App WebView 注入 `mallToken` Cookie。

## Mock 和联调方式

- 页面联调阶段不再使用 mock 数据兜底。
- 单测可使用 fixture 模拟 Java envelope。
- 浏览器独立调试可通过 `/debug-login` 写入调试 token。

## 验收标准

- [ ] `/favorites/products` 首屏 loading 后只渲染真实收藏数据；空数组展示通用空态。
- [ ] `/footprints` 首屏 loading 后只渲染真实足迹数据；空数组展示通用空态。
- [ ] 收藏页编辑态支持选择、全选、取消收藏，并按旧接口 `POST /p/user/collection/addOrCancel` 传商品 ID。
- [ ] 足迹页编辑态支持选择、全选、删除，并按旧接口 `DELETE /p/prodBrowseLog` 传足迹 ID 数组。
- [ ] 商品卡点击进入 `/product/<prodId>`。
- [ ] 接口失败展示错误和重试，不回退本地 mock。
- [ ] BFF 到 Java 的路径、query/body 与旧 uni-app 流程一致。
- [ ] 本地文档与飞书知识库同步完成。

## 验证命令

```bash
cd hybird-meumall
pnpm exec vitest run src/features/mine-secondary/collections-real-service.test.ts src/features/mine-secondary/collections-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx
pnpm typecheck
git diff --check
```

## 发布影响

- 需要发布 `hybird-meumall` SSR 版本。
- 不影响 manifest schema。
- 不新增 Native Bridge。
- 不新增后端接口。
- 回滚方式：回滚 H5 release 到上一稳定版本。

## 风险和阻塞

- 真实数据依赖 App 注入有效 `mallToken`；无 token 时 Java 会返回未授权。
- 旧收藏接口响应结构为 `records[0].products`，若后端结构变化，BFF mapper 需要同步调整。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-27 | in_progress | 创建工作项，进入 H5 实现。 |
| 2026-06-27 | implemented | 已完成 H5 BFF、service、feature API adapter、页面真实接口迁移和本地验证；待 App WebView 真实 `mallToken` 联调。 |

## 验证记录

| 日期 | 命令 | 结果 |
| --- | --- | --- |
| 2026-06-27 | `pnpm exec vitest run src/features/mine-secondary/collections-real-service.test.ts src/features/mine-secondary/collections-api.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx` | 通过，3 files / 12 tests |
| 2026-06-27 | `pnpm typecheck` | 通过 |
| 2026-06-27 | `git diff --check` | 通过 |
| 2026-06-27 | `curl -I http://localhost:3109/hybird/favorites/products` | 200 OK |
| 2026-06-27 | `curl -I http://localhost:3109/hybird/footprints` | 200 OK |

## 飞书知识库同步

| 日期 | 页面 | 链接 | 结果 |
| --- | --- | --- | --- |
| 2026-06-27 | 页面清单 | <https://v05ctaei9gn.feishu.cn/wiki/WgaqwTRRUitnRNkCtNPcOcDnnre> | 已追加“我的收藏与我的足迹真实接口迁移”，验证 revision 38 |
| 2026-06-27 | API/BFF 对接说明 | <https://v05ctaei9gn.feishu.cn/wiki/GPhdwjQ87iQAQskeS6lc9bMOnte> | 已追加“我的收藏与我的足迹 BFF”，验证 revision 10 |

## 未验证项

- 尚未在 App WebView 内用真实 `mallToken` 验证 Java 返回数据和删除动作。
