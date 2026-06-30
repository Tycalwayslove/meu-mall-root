# H5 与后端 API 契约

本目录记录 `hybird-meumall` 作为消费方需要后端提供的业务 API 契约。

## 适用范围

- H5 页面数据接口。
- H5 操作提交接口。
- 登录态、鉴权、分页、缓存和错误码约定。
- H5 与正式业务后端之间的请求和响应结构。

## 已有契约

- `h5-bff-http-auth-contract.md`：定义 App Cookie 登录态、H5 BFF、Python / Java Authorization 鉴权之间的转换规则。
- `h5-mine-benefits-real-api-contract.md`：定义我的页 `/mine` 与权益中心 `/promotion/benefits` 真实接口，H5 BFF 调 Java 个人中心和达人等级接口。
- `h5-promotion-home-overview-real-api-contract.md`：定义推广首页 `/promotion` 概览真实接口，H5 BFF 调 Java `/p/distribution/home/overview`。
- `h5-promotion-incentive-activities-real-api-contract.md`：定义推广活动中心和活动详情真实接口，H5 BFF 调 Java APP 侧达人激励活动列表、详情、奖励详情和领取接口。
- `h5-promotion-ranking-real-api-contract.md`：定义推广排行榜销量榜、销售额榜真实接口，H5 BFF 调 Java `/p/distribution/rank/list`，我的排名来自 `myRank`；激励榜暂为空态。
- `h5-seller-activities-real-api-contract.md`：定义卖手活动营销入口、活动商品配置、批量状态、商品设置和新增活动商品来源接口。
- `h5-wallet-bankcard-real-api-contract.md`：定义钱包 `/wallet` 与银行卡管理 `/wallet/bank-cards` 真实接口，H5 BFF 调 Java 分销钱包、推广订单和通联银行卡接口。
- `promotion-bff-mock-contract.md`：定义推广模块首页、活动、榜单、权益页在真实后端完成前的 H5 BFF mock 数据结构。

## 模板

使用：

```text
.ai-workspace/templates/API_CONTRACT.md
```
