# TASK-2026-0601-001-首页配置生产化

## 状态

verified

## 目标

建立 MeuMall 首页配置生产化闭环，让后台可以配置首页 banner、分类入口和活动模块，后端可以保存和发布配置，H5 首页可以通过接口获取 active 配置并稳定渲染。

## 背景

当前 H5 首页已经完成视觉复刻，但首页数据仍以静态结构为主。真实业务中，首页 banner、分类入口、活动模块、缓存策略和性能策略都需要由管理系统配置，并通过后端接口下发。为了后续正式业务开发和长期维护，本任务将首页配置从静态页面推进到跨项目契约驱动。

## 涉及项目

- `server-meumall`
- `admin-meumall`
- `hybird-meumall`
- 根目录 `.ai-workspace`

## 范围

包含：

- 新增首页配置跨项目契约。
- 后端新增首页配置表、CRUD、发布和 H5 active 查询接口。
- 管理端新增独立的首页配置页面。
- H5 首页接入 active 配置接口，支持骨架屏、缓存、失败兜底和模块化渲染。
- 补充对应测试和验证记录。

不包含：

- 商品推荐算法和推荐接口实现。
- 图片上传、素材库、CDN 管理后台。
- 拖拽式 CMS 装修器。
- 原生 App tab 或 WebView 生命周期改造。
- 全量清理历史 manifest 中的 `/cart` 路由。

## 责任边界

`server-meumall`：

- 负责首页配置持久化、状态流转、发布约束和 H5 active 接口。
- 负责校验配置 schema、事件目标和同环境 active 唯一。
- 不负责管理端表单体验，也不负责 H5 模块视觉。

`admin-meumall`：

- 负责首页配置列表、编辑、校验、保存草稿、发布和删除草稿。
- 负责把 banner、分类和活动配置结构化录入。
- 不负责 H5 渲染细节和后端状态约束。

`hybird-meumall`：

- 负责首页骨架屏、接口读取、短缓存、模块渲染、失败兜底和性能事件预留。
- 不负责后台配置管理和后端发布规则。

根目录 `.ai-workspace`：

- 负责保存本任务、契约和验收口径。
- 不承载具体业务代码。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/homepage-config-contract.md`
- 是否向后兼容：新增契约，向后兼容现有 manifest/release。
- 是否需要迁移：后端新增表结构；现有 H5 静态首页作为兜底，不做数据迁移。

## 实现计划

1. 后端新增 `home_page_configs` 表和 Pydantic 模型。
2. 后端新增管理接口和 H5 active 查询接口。
3. 管理端拆出首页配置 API 类型和页面区域。
4. 管理端实现 banner、分类入口、活动模块的结构化编辑。
5. H5 新增首页 feature 目录，接入配置接口和骨架屏。
6. H5 实现短缓存、远端失败兜底、模块级容错和图片预加载。
7. 三端补充测试、类型检查、构建验证和任务记录。

## 验收标准

- [ ] 后端可以创建、查询、更新、删除草稿首页配置。
- [ ] 后端发布新配置时，同环境旧 active 自动归档。
- [ ] H5 active 接口返回结构符合 `.ai-workspace/contracts/homepage-config-contract.md`。
- [ ] 管理端首页配置页面和版本迭代、manifest 管理分开。
- [ ] 管理端可以编辑 banner、分类入口和活动模块，并保存草稿。
- [ ] H5 首页首次加载显示骨架屏。
- [ ] H5 首页成功获取配置后按模块渲染 banner、分类入口和活动模块。
- [ ] H5 配置接口失败时不白屏，能使用缓存或兜底内容。
- [ ] 新增首页配置不引入购物车入口。
- [ ] 三个子项目的测试、类型检查或构建验证有记录。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/server-meumall
.venv/bin/python -m pytest tests/test_api.py -k "home_config" -v
.venv/bin/python -m pytest

cd /Users/mac/person_code/meu-mall/admin-meumall
pnpm test -- src/lib/configApi.test.ts
pnpm test
pnpm exec tsc -b
pnpm build

cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm test -- src/features/home/home.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm build
```

## 验证结果

- `server-meumall`：首页配置专项测试 4 passed，全量 pytest 14 passed。
- `admin-meumall`：`configApi` 测试 9 passed，全量测试 9 passed，`pnpm exec tsc -b` 通过，`pnpm build` 通过。
- `hybird-meumall`：Vitest 12 files / 72 tests 通过，`typecheck`、`lint`、`build` 通过。
- smoke：发布 `2026.06.01-smoke` 首页配置后，`http://localhost:3000/` 展示接口下发的 `Smoke 首页配置`、`配置分类` 和 `配置活动`。
- 管理端 smoke：`http://localhost:5173/` 点击“内容配置”可进入首页配置页，并展示列表、模块摘要和配置 JSON。

## 发布影响

- 是否需要发布：需要，涉及后端、管理端和 H5。
- 发布项目：`server-meumall`、`admin-meumall`、`hybird-meumall`。
- 是否需要灰度：H5 首页配置建议先在 `dev` 或 `staging` 环境验证，再发布 `prod` active。
- 回滚目标：后端归档前一个 active 首页配置；H5 保留静态兜底。
- smoke check：打开 H5 首页，确认骨架屏、配置渲染、失败兜底和管理端发布流程。

## 风险和阻塞

- 首页配置字段如果过早做成自由 JSON，后续运营容易产生不可控配置；本任务采用结构化编辑和后端校验降低风险。
- 图片上传和 CDN 管理暂不包含，第一版依赖 URL 录入。
- 推荐商品接口不在本任务中实现，首页推荐区域只能保留现有兜底或预留位。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-01 | ready | 用户确认首页配置生产化方案，创建 ready 工作项。 |
| 2026-06-01 | in_progress | 按实现计划启动后端、管理端和 H5 三线并行开发。 |
| 2026-06-01 | verified | 后端、管理端、H5 自动化验证和本地 smoke 均通过。 |
