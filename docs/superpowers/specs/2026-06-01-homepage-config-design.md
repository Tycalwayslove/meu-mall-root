# 首页配置生产化设计规格

## 状态

已确认设计方向。本文定义第一版可开发范围，后续实现以根级工作项和跨项目契约为准。

## 背景

MeuMall H5 首页目前主要是静态高保真页面。真实生产环境中，首页的 banner、分类入口、活动模块和部分展示策略需要由后台配置，并通过接口下发给 H5。首页没有购物车路径，且 H5 运行在原生 App WebView 中，首屏速度、骨架屏、缓存、降级和发布边界都必须清楚。

本次不做完整 CMS 搭建器，也不处理推荐商品算法。目标是先建立一个可维护的首页配置闭环：后台能配置，后端能保存和发布，H5 能读取并稳定渲染。

## 目标

第一版完成以下能力：

- 后端提供独立首页配置存储、草稿保存、发布和 H5 active 查询接口。
- 管理端新增“内容配置 / 首页配置”页面，和版本迭代、manifest 管理分离。
- H5 首页从接口读取配置，先展示骨架屏，再渲染 banner、分类入口和活动模块。
- 首页配置契约沉淀到根目录，作为后端、管理端和 H5 的共同标准。
- 首页首屏加载失败时不白屏，能够使用短缓存或兜底内容。

## 不包含

- 不做拖拽式可视化装修。
- 不做商品推荐算法和推荐接口实现。
- 不做原生 App tab、导航栏或 WebView 生命周期改造。
- 不做图片上传、素材库和 CDN 管理后台。
- 不在本任务中清理所有历史 `/cart` 配置，但新增配置不得引入购物车入口。

## 方案选择

采用“生产基线版”方案。

后端把首页配置作为独立业务配置，不复用 manifest/release 表。管理端提供结构化编辑，而不是让运营直接编辑大段 JSON。H5 按模块渲染接口配置，并保留骨架屏、缓存、超时和错误兜底。

这个方案比“只在现有 manifest 里塞首页字段”更清楚，也比“一次做完整 CMS”更可控。它能先满足正式业务开发和跨项目维护，后续可以平滑升级为更强的装修系统。

## 系统边界

`server-meumall` 负责首页配置的持久化、状态流转、发布约束和 H5 查询接口。

`admin-meumall` 负责配置录入、预览、校验、保存草稿和发布操作。

`hybird-meumall` 负责消费 active 配置、展示骨架屏、渲染首页模块、执行短缓存和性能上报。

根目录 `.ai-workspace` 负责保存跨项目契约、工作项、验收标准和后续上下文恢复材料。

## 后端设计

新增表 `home_page_configs`：

```sql
CREATE TABLE home_page_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  environment TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('draft', 'active', 'archived')),
  config_version TEXT NOT NULL,
  config_json TEXT NOT NULL,
  source TEXT,
  created_by TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  published_at TEXT
);
```

约束：

- 同一 `environment` 只能有一个 `active` 配置。
- 草稿可以编辑和删除。
- 发布一个配置时，当前环境旧的 `active` 自动归档。
- H5 active 查询只返回可渲染配置，不暴露后台管理字段。

核心接口：

- `GET /api/home/configs`
- `POST /api/home/configs`
- `GET /api/home/configs/{id}`
- `PUT /api/home/configs/{id}`
- `DELETE /api/home/configs/{id}`
- `POST /api/home/configs/{id}/publish`
- `GET /api/h5/home/config/active`

## 管理端设计

管理端新增内容配置区域：

```text
发布控制
- 正式发版
- Manifest 配置

内容配置
- 首页配置
```

首页配置页包含：

- 环境筛选：`dev`、`staging`、`prod`。
- 配置列表：名称、状态、版本、更新时间、发布时间。
- 基础信息：配置名称、备注、缓存 TTL、性能参数。
- Banner 模块编辑：标题、图片 URL、跳转事件、跳转参数、排序、启停。
- 分类入口编辑：文案、图标 URL、跳转事件、跳转参数、每行列数、排序、启停。
- 活动模块编辑：是否展示、标题、副标题、图片 URL、跳转事件、跳转参数、时间窗口、排序、启停。
- 操作：保存草稿、发布、删除草稿。

第一版可以使用当前 React/Vite 项目的本地视图状态或 hash 视图，不强制引入路由库。若拆分成本较低，应把 release、manifest、home-config 三块拆成独立 feature 目录，避免继续扩大 `App.tsx`。

## H5 设计

H5 首页入口保持在 `src/app/page.tsx`，页面主体迁移到 `src/features/home/HomeScreen.tsx`。

加载流程：

1. 首次进入立即展示首页骨架屏。
2. 并行读取本地短缓存和远端 active 配置。
3. 远端成功时渲染最新配置，并刷新本地缓存。
4. 远端失败但缓存可用时渲染缓存，并记录降级事件。
5. 远端失败且无缓存时渲染兜底首页，不出现白屏。

模块渲染：

- `banner_carousel` 渲染 banner 轮播或单图。
- `category_grid` 按配置列数渲染分类入口。
- `activity_section` 根据启停和时间窗口渲染活动模块。
- `recommendation` 只预留展示区和接口位置，不在本任务实现推荐算法。

性能策略：

- 首屏骨架尺寸尽量贴近真实模块，降低 CLS。
- 首个 banner 或配置指定的 LCP 图片进行预加载。
- 接口默认 3 至 5 秒超时。
- 首页配置使用短 TTL 缓存，只缓存公共配置，不缓存用户 token、库存、价格和权益。
- 预留白屏、加载耗时、配置版本、降级原因等 telemetry 字段。

## 配置模型

H5 active 接口返回页面级配置：

```json
{
  "schemaVersion": "1.0",
  "pageId": "home",
  "configVersion": "2026.06.01-001",
  "generatedAt": "2026-06-01T00:00:00Z",
  "cache": {
    "ttlSeconds": 300,
    "staleWhileRevalidateSeconds": 1800
  },
  "performance": {
    "requestTimeoutMs": 4000,
    "skeletonMinMs": 200,
    "preloadImageCount": 1,
    "lcpCandidateModuleId": "home-banner"
  },
  "modules": []
}
```

模块字段细节以 `.ai-workspace/contracts/homepage-config-contract.md` 为准。

## 错误处理

后端应在配置结构非法时返回 422，并说明字段路径。管理端应在保存前做基础校验，减少无效配置进入后端。H5 应把接口失败、解析失败、空配置和模块级异常分开处理，避免单个模块配置错误导致整页白屏。

## 测试策略

后端测试覆盖：

- 首页配置 CRUD。
- 同环境 active 唯一。
- 发布时旧 active 自动归档。
- H5 active 查询返回 config body。
- 非法配置返回 422。

管理端测试覆盖：

- 首页配置 API 封装。
- 草稿保存和发布操作。
- 动态增删 banner、分类和活动项。
- 基础字段校验。

H5 测试覆盖：

- 有配置时渲染模块。
- loading 时展示骨架屏。
- 接口失败时使用缓存。
- 无缓存失败时展示兜底。
- 分类列数和活动启停生效。

## 验收标准

- 后端、管理端、H5 都有对应测试或可执行验证命令。
- 管理端首页配置不和 manifest/release 页面混在一个业务区域。
- H5 首页不再依赖硬编码 banner、分类和活动数据作为主路径。
- 首页 active 配置接口和根级契约一致。
- 失败场景不白屏，至少有缓存或兜底展示。
- 不新增购物车入口。

## 开放问题

第一版默认跳转事件只定义结构，不实现所有原生行为。事件实际执行仍由 H5 路由和既有 Bridge 能力承接。

图片上传和素材管理留到后续工作项。第一版管理端只录入 URL，后续可接 CDN 或原生 zip 包资源策略。
