# 喵呜 H5 页面骨架设计

## 状态

accepted

## 背景

当前 Figma 仍按实验稿处理，正式视觉和业务细节会继续调整。第一版 H5 页面目标不是还原图片和 icon，而是让页面结构、入口关系、端归属和后续替换边界先跑通。

## 核心决策

- 原生 App 负责一级 Tab 容器和 Tab 切换。
- H5 不渲染底部 Tab。
- H5 只负责被原生加载的内容页和 H5 内部二级跳转页。
- H5 不从 Figma 下载图片或 icon。
- 图片、banner、头像、商品图、二维码和 icon 统一使用可替换的色块占位组件。
- 智能体由 App 原生负责，H5 只提供说明型占位页，不实现智能体业务。
- 喵呜没有购物车，H5 不再保留购物车页面或购物车语义。

## 第一批页面范围

一级入口页做成可理解的闭环：

- 首页内容页：搜索、消息入口、banner 占位、分类入口、限时秒杀、推广入口、推荐商品。
- 推广内容页：达人信息、收益概览、推广工具、活动入口、推广商品、佣金、名片、等级入口。
- 我的内容页：用户信息、会员/达人入口、收藏、订单或购买记录、收益、设置入口。
- 智能体占位页：说明该模块由 App 原生承载。

其它 H5 页面做低保真骨架：

- 商品列表、商品详情、订单确认。
- 秒杀列表。
- 消息入口、咨询入口。
- 商品收藏、店铺收藏。
- 推广商品、佣金收益、我的名片、达人等级、权益中心、排行榜。
- 会员/达人中心、订单或购买记录。

## 路由设计

```text
/                         首页内容
/promotion                推广内容
/mine                     我的内容
/agent-placeholder        智能体原生占位说明
/category                 商品列表/分类结果
/product/[id]             商品详情
/order-confirm            订单确认
/seckill                  秒杀列表
/messages                 消息入口
/consult                  咨询入口占位
/favorites/products       商品收藏
/favorites/shops          店铺收藏
/promotion/products       推广商品
/promotion/commission     佣金收益
/promotion/card           我的名片
/promotion/level          达人等级
/promotion/benefits       权益中心
/promotion/ranking        排行榜
/member                   会员/达人中心
/orders                   订单或购买记录
```

## 组件设计

- `H5PageShell`：移动 WebView 内容页外壳，处理背景、安全区、最大宽度和顶部标题区，不包含底部 Tab。
- `PlaceholderMedia`：统一表达 banner、商品图、头像、二维码等图片类占位。
- `PlaceholderIcon`：统一表达 icon 类占位。
- `SectionHeader`：区块标题和右侧跳转。
- `ActionGrid`：功能入口宫格。
- `ProductCard`：商品卡片骨架。
- `MetricCard`：收益、佣金、等级等数字卡片。
- `LowFiPage`：低保真二级页骨架。

## 验收标准

- H5 页面中不出现底部 Tab。
- H5 页面中不出现购物车入口或购物车语义。
- 首页、推广、我的、智能体占位页均可通过路由访问。
- 其它低保真骨架页均可通过对应入口访问。
- 图片和 icon 都通过占位组件表达，不能引入 Figma 下载素材。
- 页面在移动 WebView 宽度下内容不重叠、按钮文字不溢出。
- `pnpm typecheck`、`pnpm lint`、`pnpm test`、`pnpm build` 通过。
