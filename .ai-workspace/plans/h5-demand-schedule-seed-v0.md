# H5 需求排期种子清单 V0

飞书 Base：<https://v05ctaei9gn.feishu.cn/base/YFYGbcWJnaENSKsEIQVcUcrynAc>
Base token：`YFYGbcWJnaENSKsEIQVcUcrynAc`
默认飞书 profile：`company-feishu`
最后同步时间：2026-06-08 15:53:11 CST
同步结果：版本 3 条、页面 25 条、后端接口 21 条、原生对接 17 条、测试验收 16 条、团队人员占位 6 条、项目协作总览 79 条、仪表盘组件 17 个。

## 说明

本文用于初始化飞书多维表格 `MeuMall H5 需求排期`。它不是最终排期结论，而是基于当前页面盘点、路由对接说明和已实现页面状态生成的首批协作底稿。

后端、原生 App 和测试同事可以在飞书 Base 中继续补充负责人、接口字段、计划时间、测试用例和阻塞项。

本次同步已完成以下结构增强：

- 需求表主显示字段改为中文可读名称，例如 `首页｜/`、`首页配置｜H5 BFF`。
- 稳定编号保留在独立 ID 字段中，便于后续契约、自动化和文档引用。
- 新增 `团队人员与角色` 表，预置前端、后端、测试、iOS、Android、产品待分配占位。
- 所有需求表新增 `责任组` 和 `协作成员`，支持按部门和人员视角查看任务。
- 新增 `项目协作总览` 表，统一展示页面、接口、原生、测试任务。
- 新增 `MeuMall H5 进度仪表盘`，包含页面、接口、原生、测试、协作任务和团队角色分布。
- 新增 `页面开发甘特图`，并修正 `版本甘特图` 的开始/结束字段配置。
- 调整关键视图第一屏字段顺序，优先展示任务、状态、责任组、成员、计划完成、阻塞、需要谁提供和下一步动作。

## 版本迭代排期种子

| 版本 | 迭代名称 | 迭代状态 | 计划开始 | 计划完成 | 目标 | 风险 |
| --- | --- | --- | --- | --- | --- | --- |
| v1.1.0 | 推广链路一期 | 开发中 | 2026-06-08 | 2026-06-19 | 推广首页、权益中心、活动中心、榜单中心、榜单详情进入可测试。 | 真实后端接口、App 新开 WebView 和返回规则仍需联调。 |
| v1.2.0 | 首页与商品链路一期 | 未开始 | 2026-06-22 | 2026-07-03 | 首页配置、搜索、分类、商品详情、秒杀进入联调。 | 商品价格库存、秒杀资格、推荐商品接口依赖后端确认。 |
| v1.3.0 | 交易与我的链路一期 | 未开始 | 2026-07-06 | 2026-07-17 | 订单确认、支付、订单记录、收藏、我的页二级入口进入可测试。 | 支付 Bridge、订单接口、App 测试包和 QA 回归风险较高。 |

## H5 页面需求种子

| 页面需求 ID | 页面名称 | 路由 | 页面层级 | 所属模块 | 端归属 | 容器策略 | 开发状态 | 优先级 | 关联版本 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PAGE-HOME-001 | 首页 | `/` | 一级 | 首页 | Hybrid | `tab-root-webview` | 可测试 | P0 | v1.2.0 | 首页 Tab 根页面，内容 H5，Tab 容器原生。 |
| PAGE-PROMOTION-001 | 推广首页 | `/promotion` | 一级 | 推广 | H5 | `tab-root-webview` | 可测试 | P0 | v1.1.0 | 推广 Tab 根页面。 |
| PAGE-MINE-001 | 我的 | `/mine` | 一级 | 我的 | Hybrid | `tab-root-webview` | 可测试 | P0 | v1.3.0 | 我的 Tab 根页面，除设置外二级页面暂定 H5。 |
| PAGE-SEARCH-001 | 搜索 | `/search` | 二级 | 首页 | H5 | `new-h5-webview` | 静态页面 | P0 | v1.2.0 | 首页搜索入口进入。 |
| PAGE-MESSAGES-001 | 消息中心 | `/messages` | 二级 | 通用 | H5 | `new-h5-webview` | 静态页面 | P1 | v1.3.0 | 首页或我的页进入。 |
| PAGE-CATEGORY-001 | 分类/商品列表 | `/category` | 二级 | 商品 | H5 | `new-h5-webview` | 静态页面 | P0 | v1.2.0 | 首页分类入口进入。 |
| PAGE-PRODUCT-001 | 商品详情 | `/product/[id]` | 二级 | 商品 | H5 | `new-h5-webview` | 静态页面 | P0 | v1.2.0 | 首页进入时新开 WebView；列表内进入时当前 WebView push。 |
| PAGE-CONSULT-001 | 咨询入口 | `/consult` | 二级 | 商品 | H5 | `current-webview-push` | 静态页面 | P2 | v1.2.0 | 当前只做入口，不实现 IM。 |
| PAGE-SECKILL-001 | 秒杀 | `/seckill` | 二级 | 商品 | H5 | `new-h5-webview` | 静态页面 | P1 | v1.2.0 | 首页秒杀入口进入。 |
| PAGE-ORDER-CONFIRM-001 | 订单确认 | `/order-confirm` | 二级 | 订单 | H5 | `current-webview-push` | 静态页面 | P0 | v1.3.0 | 商品详情立即购买进入。 |
| PAGE-ORDERS-001 | 订单/购买记录 | `/orders` | 二级 | 订单 | H5 | `new-h5-webview` | 静态页面 | P1 | v1.3.0 | 我的页或支付完成进入。 |
| PAGE-FAVORITE-PRODUCTS-001 | 商品收藏 | `/favorites/products` | 二级 | 我的 | H5 | `new-h5-webview` | 静态页面 | P1 | v1.3.0 | 我的页进入。 |
| PAGE-FAVORITE-SHOPS-001 | 店铺收藏 | `/favorites/shops` | 二级 | 我的 | H5 | `new-h5-webview` | 静态页面 | P2 | v1.3.0 | 从我的或商品收藏切换。 |
| PAGE-PROMOTION-PRODUCTS-001 | 推广商品 | `/promotion/products` | 二级 | 推广 | H5 | `new-h5-webview` | 静态页面 | P0 | v1.1.0 | 推广首页进入。 |
| PAGE-PROMOTION-COMMISSION-001 | 佣金收益 | `/promotion/commission` | 二级 | 推广 | H5 | `new-h5-webview` | 静态页面 | P0 | v1.1.0 | 推广首页点击累计佣金进入。 |
| PAGE-PROMOTION-CARD-001 | 推广名片 | `/promotion/card` | 二级 | 推广 | Hybrid | `new-h5-webview` | 静态页面 | P1 | v1.1.0 | 分享和保存图片依赖 App。 |
| PAGE-PROMOTION-LEVEL-001 | 达人等级 | `/promotion/level` | 二级 | 推广 | H5 | `new-h5-webview` | 需求澄清 | P1 | v1.1.0 | 当前偏占位，达人和会员是一套体系。 |
| PAGE-PROMOTION-BENEFITS-001 | 权益中心 | `/promotion/benefits` | 二级 | 推广 | H5 | `new-h5-webview` | 可测试 | P0 | v1.1.0 | 我的页点击权益中心进入。 |
| PAGE-PROMOTION-ACTIVITIES-001 | 活动中心 | `/promotion/activities` | 二级 | 推广 | H5 | `new-h5-webview` | 可测试 | P0 | v1.1.0 | 推广首页进入。 |
| PAGE-PROMOTION-ACTIVITY-DETAIL-001 | 活动详情 | `/promotion/activities/[slug]` | 三级 | 推广 | H5 | `current-webview-push` | 可测试 | P1 | v1.1.0 | 活动中心进入。 |
| PAGE-PROMOTION-REWARD-RECORDS-001 | 奖励记录 | `/promotion/activities/reward-records` | 三级 | 推广 | H5 | `current-webview-push` | 可测试 | P1 | v1.1.0 | 活动中心进入。 |
| PAGE-PROMOTION-RANK-CENTER-001 | 榜单中心 | `/promotion/rank-center` | 二级 | 推广 | H5 | `new-h5-webview` | 可测试 | P0 | v1.1.0 | 推广首页进入。 |
| PAGE-PROMOTION-RANK-SALES-001 | 销量榜 | `/promotion/ranking/sales` | 三级 | 推广 | H5 | `current-webview-push` | 可测试 | P0 | v1.1.0 | 榜单中心进入。 |
| PAGE-PROMOTION-RANK-AMOUNT-001 | 销售额榜 | `/promotion/ranking/amount` | 三级 | 推广 | H5 | `current-webview-push` | 可测试 | P0 | v1.1.0 | 榜单中心进入。 |
| PAGE-SETTINGS-001 | 设置 | `native:settings` | 原生 | 我的 | App | `native-page` | 需求澄清 | P1 | v1.3.0 | 我的页进入，原则上由原生实现。 |

## 后端接口需求种子

| 接口需求 ID | 关联页面 | 接口名称 | 服务归属 | 接口类型 | Method | Path | 鉴权 Token | Mock 状态 | 接口状态 | 优先级 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| API-HOME-001 | PAGE-HOME-001 | 首页配置 | H5 BFF | 配置 | GET | `/api/bff/home/config` | mallToken | H5 Mock | 待确认 | P0 | banner、分类入口、活动配置、推荐模块。 |
| API-HOME-002 | PAGE-HOME-001 | 首页推荐商品 | Java | 查询 | GET | 待定 | mallToken | 未提供 | 待补充 | P0 | 推荐列表最终应走正式商品接口。 |
| API-SEARCH-001 | PAGE-SEARCH-001 | 搜索建议和搜索结果 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P0 | 包含关键词、分页、排序。 |
| API-CATEGORY-001 | PAGE-CATEGORY-001 | 分类和商品列表 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P0 | 分类、筛选、商品卡片。 |
| API-PRODUCT-001 | PAGE-PRODUCT-001 | 商品详情 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P0 | 价格、库存、规格、可购买状态需实时。 |
| API-PRODUCT-002 | PAGE-PRODUCT-001 | 收藏状态和收藏操作 | Java | 提交 | POST | 待定 | mallToken | H5 Mock | 待补充 | P1 | 商品收藏私有数据。 |
| API-SECKILL-001 | PAGE-SECKILL-001 | 秒杀活动和秒杀商品 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P1 | 倒计时需服务端时间校准。 |
| API-ORDER-001 | PAGE-ORDER-CONFIRM-001 | 订单预览 | Java | 交易 | POST | 待定 | mallToken | 未提供 | 待补充 | P0 | 价格、库存、优惠、地址等下单前确认。 |
| API-ORDER-002 | PAGE-ORDER-CONFIRM-001 | 创建订单 | Java | 交易 | POST | 待定 | mallToken | 未提供 | 待补充 | P0 | 创建后交给支付 Bridge。 |
| API-ORDERS-001 | PAGE-ORDERS-001 | 订单/购买记录 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P1 | 订单状态枚举待确认。 |
| API-FAVORITE-001 | PAGE-FAVORITE-PRODUCTS-001 | 商品收藏列表 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P1 | 私有 no-store。 |
| API-FAVORITE-002 | PAGE-FAVORITE-SHOPS-001 | 店铺收藏列表 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P2 | 是否存在店铺主页待确认。 |
| API-PROMOTION-001 | PAGE-PROMOTION-001 | 推广首页数据 | H5 BFF | 查询 | GET | `/api/bff/promotion/home` | 双 Token | H5 Mock | 待确认 | P0 | 达人信息、收益卡、工具入口、推荐。 |
| API-PROMOTION-002 | PAGE-PROMOTION-PRODUCTS-001 | 推广商品列表 | Java | 查询 | GET | 待定 | mallToken | H5 Mock | 待补充 | P0 | 商品佣金、推广状态。 |
| API-PROMOTION-003 | PAGE-PROMOTION-COMMISSION-001 | 佣金收益明细 | Python | 查询 | GET | 待定 | pythonToken | H5 Mock | 待补充 | P0 | N+1、待结算、可提现、扣回规则待确认。 |
| API-PROMOTION-004 | PAGE-PROMOTION-BENEFITS-001 | 达人权益和等级进度 | H5 BFF | 查询 | GET | `/api/bff/promotion/benefits` | 双 Token | H5 Mock | 待确认 | P0 | 当前已由 H5 mock 支撑。 |
| API-PROMOTION-005 | PAGE-PROMOTION-ACTIVITIES-001 | 活动中心 | H5 BFF | 查询 | GET | `/api/bff/promotion/activities` | 双 Token | H5 Mock | 待确认 | P0 | 活动列表、奖励记录入口。 |
| API-PROMOTION-006 | PAGE-PROMOTION-RANK-CENTER-001 | 榜单中心 | H5 BFF | 查询 | GET | `/api/bff/promotion/rank-center` | 双 Token | H5 Mock | 待确认 | P0 | 榜单入口、榜期信息。 |
| API-PROMOTION-007 | PAGE-PROMOTION-RANK-SALES-001 | 销量榜 | H5 BFF | 查询 | GET | `/api/bff/promotion/rankings/sales` | 双 Token | H5 Mock | 待确认 | P0 | 排名、用户、销量。 |
| API-PROMOTION-008 | PAGE-PROMOTION-RANK-AMOUNT-001 | 销售额榜 | H5 BFF | 查询 | GET | `/api/bff/promotion/rankings/amount` | 双 Token | H5 Mock | 待确认 | P0 | 排名、用户、销售额。 |
| API-MINE-001 | PAGE-MINE-001 | 我的页用户信息和入口 | H5 BFF | 查询 | GET | `/api/bff/user/profile` | 双 Token | H5 Mock | 待确认 | P0 | 用户信息、权益入口、订单/收藏入口。 |

## 原生 App 对接需求种子

| 原生需求 ID | 关联页面 | 关联链路 | 平台 | 对接类型 | Bridge 能力 | 容器策略 | iOS 状态 | Android 状态 | 优先级 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| APP-RUNTIME-001 | PAGE-HOME-001 | L-002 | 双端 | Cookie 注入 | 无 | `tab-root-webview` | 待确认 | 待确认 | P0 | App 打开 H5 时注入 `pythonToken`、`mallToken`、`statusHeight`。 |
| APP-ROUTE-001 | PAGE-HOME-001 | L-003 | 双端 | 切 Tab | App 内部 | `tab-root-webview` | 已确认 | 已确认 | P0 | 首页 Tab 根 WebView 常驻。 |
| APP-ROUTE-002 | PAGE-PROMOTION-001 | L-004 | 双端 | 切 Tab | App 内部 | `tab-root-webview` | 已确认 | 已确认 | P0 | 推广 Tab 根 WebView 常驻。 |
| APP-ROUTE-003 | PAGE-MINE-001 | L-005 | 双端 | 切 Tab | App 内部 | `tab-root-webview` | 已确认 | 已确认 | P0 | 我的 Tab 根 WebView 常驻。 |
| APP-ROUTE-004 | PAGE-SEARCH-001 | L-006 | 双端 | 打开 H5 WebView | `router.navigate` | `new-h5-webview` | 待确认 | 待确认 | P0 | 首页搜索入口新开 WebView。 |
| APP-ROUTE-005 | PAGE-PRODUCT-001 | L-010 | 双端 | 打开 H5 WebView | `router.navigate` | `new-h5-webview` | 待确认 | 待确认 | P0 | 首页商品进入详情时新开 WebView。 |
| APP-ROUTE-006 | PAGE-PROMOTION-COMMISSION-001 | L-018 | 双端 | 打开 H5 WebView | `router.navigate` | `new-h5-webview` | 待确认 | 待确认 | P0 | 推广首页点击累计佣金进入。 |
| APP-ROUTE-007 | PAGE-PROMOTION-ACTIVITIES-001 | L-020 | 双端 | 打开 H5 WebView | `router.navigate` | `new-h5-webview` | 待确认 | 待确认 | P0 | 推广首页点击奖励活动进入。 |
| APP-ROUTE-008 | PAGE-PROMOTION-RANK-CENTER-001 | L-021 | 双端 | 打开 H5 WebView | `router.navigate` | `new-h5-webview` | 待确认 | 待确认 | P0 | 推广首页点击排行榜进入。 |
| APP-ROUTE-009 | PAGE-PROMOTION-CARD-001 | L-029 | 双端 | 分享 | `share` | `native-modal` | 待确认 | 待确认 | P1 | 推广名片分享。 |
| APP-ROUTE-010 | PAGE-PROMOTION-CARD-001 | L-030 | 双端 | 保存图片 | `save_image` | `native-modal` | 待确认 | 待确认 | P1 | 推广名片保存到相册。 |
| APP-ROUTE-011 | PAGE-PROMOTION-BENEFITS-001 | L-031 | 双端 | 打开 H5 WebView | `router.navigate` | `new-h5-webview` | 待确认 | 待确认 | P0 | 我的页点击权益中心进入。 |
| APP-ROUTE-012 | PAGE-SETTINGS-001 | L-037 | 双端 | 原生页面 | `router.navigate` | `native-page` | 待确认 | 待确认 | P1 | 我的页点击设置进入原生设置页。 |
| APP-BACK-001 | PAGE-SEARCH-001 | L-038 | 双端 | 关闭 WebView | `router.navigate` | `new-h5-webview` | 待确认 | 待确认 | P0 | 二级页无 H5 history 时关闭当前 WebView。 |
| APP-BACK-002 | PAGE-PROMOTION-ACTIVITY-DETAIL-001 | L-039 | 双端 | 关闭 WebView | H5 Router | `current-webview-push` | 暂不需要 | 暂不需要 | P0 | 三级页优先 H5 history 返回。 |
| APP-AUTH-001 | PAGE-HOME-001 | L-043 | 双端 | 登录认证 | `token_expired` | `native-page` | 待确认 | 待确认 | P0 | 接口 401 或 token 过期时让 App 重新认证。 |
| APP-PAY-001 | PAGE-ORDER-CONFIRM-001 | L-017 | 双端 | 支付 | 待定 | `native-modal` | 待补充 | 待补充 | P0 | 支付 Bridge 需要单独契约。 |

## 测试验收需求种子

| 测试需求 ID | 关联页面 | 测试类型 | 测试场景 | 前置条件 | 验收标准 | 测试环境 | 测试状态 | 优先级 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TEST-HOME-001 | PAGE-HOME-001 | Smoke | 首页可打开 | 登录态有效，active manifest 正常 | 首页返回 200，核心模块可见，无白屏。 | 测试环境 | 待执行 | P0 |
| TEST-HOME-002 | PAGE-HOME-001 | 功能 | 首页入口跳转 | App 测试包支持新开 WebView | 搜索、分类、商品、推广入口按容器策略跳转。 | 测试环境 | 待执行 | P0 |
| TEST-HOME-003 | PAGE-HOME-001 | 接口契约 | 首页配置兜底 | 首页配置接口异常或缺字段 | 页面展示 fallback，不白屏。 | 本地 | 待编写 | P0 |
| TEST-PROMOTION-001 | PAGE-PROMOTION-001 | UI 还原 | 推广首页不同等级主题 | 使用 V1-V5 mock 用户 | 背景、徽章、收益卡、入口和商品区展示正确。 | 测试环境 | 待执行 | P0 |
| TEST-PROMOTION-002 | PAGE-PROMOTION-001 | Bridge | 推广首页打开二级页 | App 测试包支持 `router.navigate` | 佣金、活动、榜单、名片新开 H5 WebView，根页面状态保留。 | 测试环境 | 待执行 | P0 |
| TEST-BENEFITS-001 | PAGE-PROMOTION-BENEFITS-001 | 功能 | 权益中心等级切换 | 登录态有效，权益 mock 可用 | 左右滑动切换等级，主题、徽章、圆点、权益列表同步更新。 | 测试环境 | 待执行 | P0 |
| TEST-BENEFITS-002 | PAGE-PROMOTION-BENEFITS-001 | Bridge | 权益中心返回我的页 | 从我的页新开权益中心 | 点击返回或原生手势关闭当前 WebView，回到我的页原状态。 | 测试环境 | 待执行 | P0 |
| TEST-ACTIVITIES-001 | PAGE-PROMOTION-ACTIVITIES-001 | 功能 | 活动中心进入详情和奖励记录 | 活动 mock 可用 | 活动详情和奖励记录在当前 WebView 内 push，返回正常。 | 测试环境 | 待执行 | P1 |
| TEST-RANKING-001 | PAGE-PROMOTION-RANK-CENTER-001 | 功能 | 榜单中心进入销量榜/销售额榜 | 榜单 mock 可用 | 榜单中心点击后在当前 WebView 内进入对应榜单。 | 测试环境 | 待执行 | P0 |
| TEST-RANKING-002 | PAGE-PROMOTION-RANK-SALES-001 | UI 还原 | 销量榜 podium 和列表 | 榜单 mock 可用 | 前三名卡片、皇冠、头像、榜期、列表展示正确。 | 测试环境 | 待执行 | P0 |
| TEST-RANKING-003 | PAGE-PROMOTION-RANK-AMOUNT-001 | UI 还原 | 销售额榜 podium 和列表 | 榜单 mock 可用 | 金额榜单位、前三名卡片、列表展示正确。 | 测试环境 | 待执行 | P0 |
| TEST-PRODUCT-001 | PAGE-PRODUCT-001 | 接口契约 | 商品详情实时字段 | 商品详情接口可用 | 价格、库存、可购买状态与接口一致，异常可恢复。 | 测试环境 | 待编写 | P0 |
| TEST-ORDER-001 | PAGE-ORDER-CONFIRM-001 | 功能 | 立即购买到订单确认 | 商品详情可进入订单确认 | 订单确认展示商品、价格、优惠和提交按钮。 | 测试环境 | 待编写 | P0 |
| TEST-PAY-001 | PAGE-ORDER-CONFIRM-001 | Bridge | 支付 Bridge | App 测试包支持支付 mock | 点击支付拉起原生支付，成功/失败/取消均有回调处理。 | 测试环境 | 待编写 | P0 |
| TEST-AUTH-001 | PAGE-HOME-001 | 异常兜底 | token 过期重新认证 | 后端返回 401 | H5 清理状态并通知 App 重新认证，不停留白屏。 | 测试环境 | 待执行 | P0 |
| TEST-ASSET-001 | PAGE-PROMOTION-BENEFITS-001 | 回归 | 本地图片走版本 basePath | 访问 `/h5-v/<version>/promotion/benefits` | 徽章、背景、icon 不出现裸 `/assets/` 失效。 | 线上候选 | 待执行 | P0 |
