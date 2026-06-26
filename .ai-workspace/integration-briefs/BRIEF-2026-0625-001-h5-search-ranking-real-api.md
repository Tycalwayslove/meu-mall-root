# 对接说明：H5 搜索热榜真实接口

## 基本信息

- Brief 编号：BRIEF-2026-0625-001
- 状态：ready
- 关联任务：`.ai-workspace/tasks/TASK-2026-0625-001-h5-search-ranking-real-api.md`
- 关联契约：`.ai-workspace/contracts/api/h5-search-ranking-contract.md`
- 消费端：`hybird-meumall`
- 后端：Java `/mini_h5`

## 背景

搜索页热门词已接真实接口，但搜索页下方热榜标签和热榜商品仍来自本地 mock。根据 Apifox 商品榜单接口目录，H5 通过 BFF 接入“顶部标签”和“商品列表”两个 Java 接口。

## 调用链路

```text
/search 或 /search/ranking[?rankType=<rankType>&categoryId=<categoryId>]
  -> H5 client /api/bff/search/ranking
  -> Java /search/rankTabs?categoryBoardCount=4 或 /search/rankTabs
  -> Java /search/rank/{rankType}[?categoryId=<categoryId>]
  -> H5 view.tabs / view.products
```

## H5 行为

- 首屏展示热榜骨架，不展示本地 mock 商品。
- 接口成功后展示真实标签和商品列表。
- 标签切换时，根据标签的 `rankType/categoryId` 重新请求商品列表。
- `/search` 点击“查看完整榜单”时，H5 会把当前标签写入目标 URL：`rankType=1` 或 `rankType=2&categoryId=<categoryId>`。
- `/search/ranking` 首屏读取 URL 上的 `rankType/categoryId` 作为默认标签；进入页面后切换标签只更新页面 state 和 BFF 请求，不操作路由，避免 App 返回/滑动返回链路被标签切换污染。
- 搜索页热榜商品为空时复用通用空态，但空态外层不使用白底卡片，保持绿色热榜背景。
- Java 空数组展示空态；接口失败展示错误态。
- 商品卡点击进入 `/product/<prodId>`。

## 后端接口

| 接口 | 用途 |
| --- | --- |
| `GET /search/rankTabs` | 获取顶部标签。 |
| `GET /search/rank/{rankType}` | 获取对应榜单商品；品类榜传 `categoryId`。 |

## 验收

- `/search` 首屏不出现本地 mock 热榜商品。
- `/search/ranking` 能展示真实标签，切换标签能刷新商品。
- 从 `/search` 某个品类标签进入完整榜单后，`/search/ranking` 默认选中对应品类标签。
- `/search/ranking` 标签切换不会改 URL，不新增浏览器 history。
- `pic` 相对路径按 `JAVA_OSS_ASSET_BASE_URL` 拼接。
- Java 空数据不回退 mock。
