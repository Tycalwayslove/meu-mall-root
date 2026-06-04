# App 接入说明：H5 路由、URL 拼接与版本识别

## 基本信息

- 编号：BRIEF-2026-0603-001
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0603-001-h5-routes-to-native.md`
- 关联契约：`.ai-workspace/contracts/h5-native-route-contract.md`
- 状态：draft
- 面向对象：原生 App
- 目标环境：test / prod

## App 需要先知道的结论

1. App 通过线上或测试域名请求 active manifest，不直接写死 H5 版本和页面完整 URL。
2. App 从 active manifest 中读取 `assets`、`routes` 和版本字段，再拼接 WebView 最终加载地址。
3. H5 一级内容入口只有：首页 `/`、推广 `/promotion`、我的 `/mine`。
4. 智能体是 App 原生 Tab，不进入 H5 URL 拼接。
5. H5 页面右上角会固定展示当前 H5 版本标识，便于人工确认 WebView 实际加载到的版本。

## H5 路由清单

### 一级 Tab 路由

| Tab | App 展示标题 | 端归属 | H5 routeKey | App 行为 |
| --- | --- | --- | --- | --- |
| 首页 | 首页 | Hybrid | `/` | App 原生 Tab，内容加载 H5 首页。 |
| 智能体 | 智能体 | App | 无 | App 原生实现，不加载 H5。 |
| 推广 | 推广 | Hybrid | `/promotion` | App 原生 Tab，内容加载 H5 推广首页。 |
| 我的 | 我的 | Hybrid | `/mine` | App 原生 Tab，内容加载 H5 我的页面。 |

### H5 二级页面路由

| H5 routeKey | 页面 | 端归属 | App 是否可直接打开 | 说明 |
| --- | --- | --- | --- | --- |
| `/category` | 分类/商品列表 | H5 | 可以 | 首页分类入口。 |
| `/messages` | 消息中心 | H5 | 可以 | 当前消息入口按 H5 处理。 |
| `/seckill` | 限时秒杀 | H5 | 可以 | 首页活动入口。 |
| `/product/{id}` | 商品详情 | H5 | 可以 | 动态路由，`{id}` 为商品 ID，例如 `/product/p-1001`。 |
| `/consult` | 咨询入口 | H5 | 不建议作为 App 一级入口 | 当前只做入口占位，不实现 IM。 |
| `/order-confirm` | 订单确认 | H5 | 不建议作为 App 一级入口 | H5 内部从商品详情进入。支付能力后续另行对接。 |
| `/orders` | 订单/购买记录 | H5 | 可以 | 我的页面入口。 |
| `/favorites/products` | 商品收藏 | H5 | 可以 | 我的页面入口。 |
| `/favorites/shops` | 店铺收藏 | H5 | 可以 | 我的页面入口。 |
| `/member` | 会员/达人中心 | H5 | 可以 | 达人与会员一套体系。 |
| `/promotion/products` | 推广商品 | H5 | 可以 | 推广首页入口。 |
| `/promotion/commission` | 佣金收益 | H5 | 可以 | 推广首页入口。 |
| `/promotion/card` | 推广名片 | Hybrid | 可以 | 页面由 H5 承载，分享/保存能力后续可能需要 App。 |
| `/promotion/level` | 达人等级 | H5 | 可以 | 推广或我的入口。 |
| `/promotion/benefits` | 权益中心 | H5 | 可以 | 达人等级入口。 |
| `/promotion/ranking` | 排行榜 | H5 | 可以 | 推广榜单入口。 |

未出现在本清单中的路径，不作为本次 App 对接入口。

## App 如何获取当前 H5 配置

### 1. 请求 active manifest

测试环境：

```text
GET https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod
```

生产环境使用同结构接口，域名以后续正式环境为准。

接口返回 manifest body，不包 `code/data`：

```json
{
  "schemaVersion": "1.0.0",
  "appId": "hybrid-h5",
  "configVersion": "config-2026.06.03-001",
  "environment": "prod",
  "stableVersion": "2026.06.03-001",
  "grayVersion": null,
  "rollbackVersion": "2026.06.02-001",
  "grayRules": {
    "percentage": 0
  },
  "assets": {
    "serviceBaseUrl": "https://hybird.aigcpop.com",
    "basePath": ""
  },
  "routes": {
    "/": { "path": "/" },
    "/promotion": { "path": "/promotion" },
    "/mine": { "path": "/mine" }
  }
}
```

### 2. 读取字段和读取规则

| 字段 | 含义 | App 读取规则 |
| --- | --- | --- |
| `stableVersion` | 当前稳定 H5 版本 | 必读。App 调试面板和日志中作为“当前稳定版本”记录。没有灰度时，它就是当前应展示的 H5 版本。 |
| `grayVersion` | 当前灰度候选版本 | 可选。为空时表示没有灰度候选；有值时只说明当前 manifest 存在灰度候选，不要直接拿它替换 URL。灰度命中策略后续单独确认。 |
| `configVersion` | 当前 manifest 配置版本 | 必读。用于排查“页面版本没变，但路由、资源地址或配置被切换”的情况。 |
| `environment` | manifest 环境 | 必读。用于区分测试、生产等环境，日志中必须带上。 |
| `assets.serviceBaseUrl` | H5 服务基础域名 | 必读。作为 WebView URL 的域名和协议来源。 |
| `assets.basePath` | H5 部署路径前缀 | 必读。为空字符串时不追加路径前缀；不为空时必须参与 URL 拼接。 |
| `routes` | H5 路由表 | 必读。App 只能从这里查找可加载的 H5 routeKey。 |
| `routes[routeKey].path` | routeKey 对应的最终页面路径 | 必读。App 拼接 URL 时使用这个 `path`，不要自己猜页面路径。 |
| `routes[routeKey].minAppVersion` | 最低 App 版本 | 可选。有值时，App 版本低于该值就不要加载该 H5 页面。 |
| `routes[routeKey].requiredBridgeMethods` | 页面依赖的原生能力 | 可选。有值时，App 需要确认这些能力可用；不可用时不应直接进入页面。 |

建议 App 每次加载 H5 页面时记录：

```text
environment
stableVersion
grayVersion
configVersion
routeKey
routes[routeKey].path
assets.serviceBaseUrl
assets.basePath
finalUrl
```

## URL 拼接详细规则

### 1. 输入

App 加载某个 H5 页面时，先确定 `routeKey`：

```text
首页 Tab -> routeKey = /
推广 Tab -> routeKey = /promotion
我的 Tab -> routeKey = /mine
商品详情 -> routeKey = /product/p-1001
```

动态路由需要先把业务 ID 替换成真实路径。比如商品详情不是直接使用 `/product/{id}`，而是使用 `/product/p-1001`。

### 2. 查询 routes

App 用 `routeKey` 查询 manifest：

```text
routeConfig = manifest.routes[routeKey]
```

处理规则：

1. 如果 `routeConfig` 存在，读取 `routeConfig.path`。
2. 如果 `routeConfig` 不存在，不要自己拼一个未知页面地址。
3. 如果业务上必须兜底，优先回到首页 `/`。
4. 智能体 Tab 不参与这个流程，因为它不是 H5 页面。

### 3. 规范化参数

拼接前先规范化：

```text
serviceBaseUrl = 去掉末尾 /
basePath = 空字符串或以 / 开头且不以 / 结尾
routePath = 必须以 / 开头
```

示例：

```text
assets.serviceBaseUrl = https://hybird.aigcpop.com/
assets.basePath = ""
routes["/promotion"].path = /promotion

规范化后：
serviceBaseUrl = https://hybird.aigcpop.com
basePath = ""
routePath = /promotion
```

### 4. 拼接 finalUrl

规则：

```text
如果 basePath 为空：
finalUrl = serviceBaseUrl + routePath

如果 basePath 不为空：
finalUrl = serviceBaseUrl + basePath + routePath
```

首页 routePath 是 `/` 时也保留尾部 `/`：

```text
serviceBaseUrl = https://hybird.aigcpop.com
basePath = ""
routePath = /
finalUrl = https://hybird.aigcpop.com/
```

推广页示例：

```text
serviceBaseUrl = https://hybird.aigcpop.com
basePath = ""
routePath = /promotion
finalUrl = https://hybird.aigcpop.com/promotion
```

带 basePath 的环境示例：

```text
serviceBaseUrl = https://h5.example.com
basePath = /hybird
routePath = /mine
finalUrl = https://h5.example.com/hybird/mine
```

## 首页加载流程示例

```text
1. 用户打开 App。
2. App 请求 active manifest。
3. App 读取：
   stableVersion
   configVersion
   assets.serviceBaseUrl
   assets.basePath
   routes
4. App 进入首页 Tab，确定 routeKey = /。
5. App 查询 manifest.routes["/"]。
6. App 读取 routes["/"].path，得到 routePath = /。
7. App 按 URL 拼接规则得到 finalUrl。
8. App 使用 WebView 加载 finalUrl。
9. App 日志记录 stableVersion、configVersion、routeKey、routePath 和 finalUrl。
10. H5 页面右上角显示 H5 版本标识，人工可以对照 App 日志确认版本。
```

## H5 页面版本标识

H5 页面右上角固定展示版本标识。

当前 H5 版本标识来源：

```text
优先 H5_RELEASE_LABEL
其次 H5_VERSION
都不存在时显示 H5 unknown
```

发布或切换 H5 版本时，发布链路应保证页面右上角展示的版本与 active manifest 的 `stableVersion` 保持一致。App 仍以 manifest 字段作为机器判断依据，右上角版本号主要用于人工联调和截图确认。

## 管理后台切换 H5 版本后 App 会看到什么

```text
CI 注册 H5 release
-> server-meumall 保存 candidate release
-> 管理后台 promote/gray/rollback
-> server-meumall 更新 active manifest
-> App 下次请求 active manifest 得到新的 stableVersion/configVersion/assets/routes
-> App 按新的 manifest 拼接 WebView URL
```

App 不需要直接调用管理后台接口，也不需要知道后台如何切换版本。App 只需要信任 active manifest。

建议 App 的 manifest 拉取策略：

- App 启动时拉取一次。
- 进入 Hybrid Tab 前可按需刷新一次。
- manifest 请求失败时使用 App 内置 fallback manifest。
- fallback manifest 也必须使用本文的 H5 routeKey。
- 如未来做灰度命中，需要单独确认 App 是否需要传 userId、deviceId 或渠道参数。

## App 侧需要调整的点

| 调整项 | 建议 |
| --- | --- |
| 一级 Tab | 调整为：首页、智能体、推广、我的。 |
| 首页 | routeKey 使用 `/`。 |
| 推广 | routeKey 使用 `/promotion`。 |
| 我的 | routeKey 使用 `/mine`。 |
| 智能体 | 原生实现，不参与 H5 URL 拼接。 |
| fallback manifest | 使用当前 route contract。 |
| 调试日志 | 输出 manifest 版本、base URL、basePath、routeKey、routePath、finalUrl。 |

当前仓库里原生侧至少需要检查：

```text
app-meumall/meumall/HybridRoute.swift
app-meumall/meumall/HybridManifest.swift
app-meumall/meumallTests/meumallTests.swift
app-meumall/docs/02_HYBRID_MANIFEST.md
```

## 联调检查清单

- [ ] App 能请求 active manifest，并打印 `stableVersion/configVersion`。
- [ ] 首页 Tab 最终 URL 是 H5 `/`。
- [ ] 推广 Tab 最终 URL 是 H5 `/promotion`。
- [ ] 我的 Tab 最终 URL 是 H5 `/mine`。
- [ ] 智能体 Tab 不进入 H5 URL 拼接。
- [ ] App fallback manifest 使用本文 routeKey。
- [ ] manifest 切换后，App 再次拉取能看到新的 `stableVersion` 或 `configVersion`。
- [ ] H5 页面右上角展示版本标识。
- [ ] H5 版本标识与 App 日志中的 `stableVersion` 可人工对照。

## 发给 App 同学的摘要

```text
这次 H5 路由接入请按 active manifest 读取，不要写死 H5 完整 URL。

1. Manifest 接口：
   GET https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod

2. H5 一级 routeKey：
   首页：/
   推广：/promotion
   我的：/mine
   智能体：App 原生负责，不参与 H5 URL 拼接

3. URL 拼接：
   先用 routeKey 从 manifest.routes 中取 routeConfig.path。
   再按 assets.serviceBaseUrl + assets.basePath + routeConfig.path 拼接 finalUrl。

4. 版本识别：
   stableVersion 是当前稳定 H5 版本；
   grayVersion 是灰度候选版本，不直接替换 URL；
   configVersion 是 manifest 配置版本。

5. H5 页面右上角会展示版本标识，方便联调截图和人工确认。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-03 | H5 | 待 App 确认 | 已按 App 接入视角重写路由、URL 拼接和版本识别说明。 |
