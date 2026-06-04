# H5 与原生路由契约

## 契约名称

H5 Native Route Contract

## 状态

draft

## 提供方

- `hybird-meumall`：提供 H5 页面路由、页面含义、路由可用性。
- `server-meumall`：通过 active manifest 提供 route map。

## 消费方

- `app-meumall`：原生 Tab、WebView URL 拼接、本地 fallback manifest。

## 关联对接说明

`.ai-workspace/integration-briefs/BRIEF-2026-0603-001-h5-routes-to-native.md`

## 适用环境

- 测试环境：`https://hybird.aigcpop.com`
- 生产环境：待正式域名和发布策略确认

## URL 拼接规则

原生侧应继续使用 manifest 的拼接规则：

```text
assets.serviceBaseUrl + assets.basePath + route.path
```

注意：

- `assets.serviceBaseUrl` 由 active manifest 提供。
- `assets.basePath` 由 active manifest 提供，空字符串表示不追加路径前缀。
- route path 必须以 `/` 开头。
- 动态路由 `/product/{id}` 在实际 URL 中替换为具体商品 ID，例如 `/product/p-1001`。

## Manifest 获取与版本识别

App 应通过 active manifest 获取当前 H5 版本、资源入口和 route map：

```text
GET /api/h5/manifest/active?environment=prod
```

测试环境可通过 H5 域名访问：

```text
https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod
```

本接口直接返回 manifest body，不添加 `code/data` wrapper。

App 识别当前 H5 版本时，以 manifest 字段为准：

| 字段 | 含义 | App 用途 |
| --- | --- | --- |
| `stableVersion` | 当前稳定 H5 版本 | 作为当前 H5 版本主标识。 |
| `grayVersion` | 当前灰度候选 H5 版本 | 表示存在灰度候选；具体命中策略后续单独确认。 |
| `configVersion` | 当前 manifest 配置版本 | 用于排查配置切换或 route map 变化。 |
| `environment` | 当前环境 | 区分 test/prod/local。 |
| `assets.serviceBaseUrl` | H5 SSR 服务基础地址 | 拼接 WebView URL。 |
| `assets.basePath` | H5 部署 basePath | 拼接 WebView URL。 |
| `routes` | H5 route map | App 打开页面时读取 route 配置。 |

H5 页面右上角固定展示版本标识，来源为 `H5_RELEASE_LABEL` 或 `H5_VERSION`。App 的机器判断仍以 active manifest 字段为准，页面版本标识主要用于人工联调和截图确认。

## 一级 Tab 契约

| Tab key 建议 | 标题 | 原生行为 | H5 route | 备注 |
| --- | --- | --- | --- | --- |
| `home` | 首页 | 原生 Tab + WebView | `/` | 默认入口。 |
| `agent` | 智能体 | 原生页面 | 无 | H5 不承载智能体页面。 |
| `promotion` | 推广 | 原生 Tab + WebView | `/promotion` | 达人推广入口。 |
| `mine` | 我的 | 原生 Tab + WebView | `/mine` | 我的入口。 |

## H5 页面路由清单

| route | 页面 | 类型 | 是否可作为原生入口 | 登录 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `/` | 首页 | 一级 Tab 内容 | 是 | 是 | App 默认 H5 内容入口。 |
| `/promotion` | 推广首页 | 一级 Tab 内容 | 是 | 是 | 推广 Tab H5 内容入口。 |
| `/mine` | 我的 | 一级 Tab 内容 | 是 | 是 | 我的 Tab H5 内容入口。 |
| `/category` | 分类/商品列表 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 首页分类入口。 |
| `/messages` | 消息中心 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 当前按 H5 消息入口处理。 |
| `/seckill` | 限时秒杀 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 首页活动入口。 |
| `/product/{id}` | 商品详情 | 动态二级页面 | 可由 H5 内部或 App 打开 | 是 | `{id}` 为商品 ID。 |
| `/consult` | 咨询入口 | 二级页面 | 可由 H5 内部打开 | 是 | 当前只做入口占位。 |
| `/order-confirm` | 订单确认 | 交易二级页面 | 可由 H5 内部打开 | 是 | 支付能力后续可能需要 App。 |
| `/orders` | 订单/购买记录 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 私有数据页面。 |
| `/favorites/products` | 商品收藏 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 私有数据页面。 |
| `/favorites/shops` | 店铺收藏 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 私有数据页面。 |
| `/member` | 会员/达人中心 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 达人与会员一套体系。 |
| `/promotion/products` | 推广商品 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 推广商品列表。 |
| `/promotion/commission` | 佣金收益 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 收益数据 no-store。 |
| `/promotion/card` | 推广名片 | Hybrid 二级页面 | 可由 H5 内部或 App 打开 | 是 | 分享/保存相册可能需要 App 能力。 |
| `/promotion/level` | 达人等级 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 达人等级入口。 |
| `/promotion/benefits` | 权益中心 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 权益展示骨架。 |
| `/promotion/ranking` | 排行榜 | 二级页面 | 可由 H5 内部或 App 打开 | 是 | 排行榜骨架。 |

## Manifest route map 建议

当前至少应包含：

```json
{
  "/": {
    "delivery": "remote",
    "path": "/",
    "minAppVersion": "0.0.0",
    "requiredBridgeMethods": []
  },
  "/promotion": {
    "delivery": "remote",
    "path": "/promotion",
    "minAppVersion": "0.0.0",
    "requiredBridgeMethods": []
  },
  "/mine": {
    "delivery": "remote",
    "path": "/mine",
    "minAppVersion": "0.0.0",
    "requiredBridgeMethods": []
  },
  "/category": {
    "delivery": "remote",
    "path": "/category",
    "minAppVersion": "0.0.0",
    "requiredBridgeMethods": []
  },
  "/product/{id}": {
    "delivery": "remote",
    "path": "/product/{id}",
    "minAppVersion": "0.0.0",
    "requiredBridgeMethods": []
  }
}
```

说明：

- 如果 manifest 暂不支持模板路由，可以只在原生端记录动态路由规则，实际打开时传具体 path，例如 `/product/p-1001`。
- 二级页面是否全部进入 manifest route map，由 App 与 server 共同确认。

## 原生侧需要调整的文件

基于当前仓库状态，原生端至少需要检查：

```text
app-meumall/meumall/HybridRoute.swift
app-meumall/meumall/HybridManifest.swift
app-meumall/meumallTests/meumallTests.swift
app-meumall/docs/02_HYBRID_MANIFEST.md
```

## H5 侧约束

- H5 当前所有页面按登录态页面处理。
- 接口 token 注入属于后续登录/token 契约，不在本路由契约中展开。
- 新增或删除 H5 页面路由时，应同步更新本契约、manifest 和原生 fallback。

## 测试方式

### H5 独立验证

```bash
curl -I https://hybird.aigcpop.com/
curl -I https://hybird.aigcpop.com/promotion
curl -I https://hybird.aigcpop.com/mine
```

### 原生联调验证

- App 启动后默认进入首页 H5。
- 点击推广 Tab，WebView 加载 `/promotion`。
- 点击我的 Tab，WebView 加载 `/mine`。
- 点击智能体 Tab，进入原生智能体页面，不参与 H5 URL 拼接。
- fallback manifest 使用本契约 route map。

## 变更流程

1. H5 新增或删除页面路由。
2. 更新本契约。
3. 更新 active manifest 或 server 默认 manifest。
4. 更新 App route enum、fallback manifest 和测试。
5. H5 与 App 联调验证。

## 回滚方式

- 如果新路由不可用，原生端可以回退到 `/` 或 `/mine`。
- 如果动态商品详情不可用，回退到 `/category` 或提示页面不可用。
