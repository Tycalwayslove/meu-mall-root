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
- `h5-promotion-ranking-real-api-contract.md`：定义推广排行榜销量榜、销售额榜真实接口，H5 BFF 调 Java `/p/distribution/rank/list`，我的排名来自 `myRank`；激励榜暂为空态。
- `promotion-bff-mock-contract.md`：定义推广模块首页、活动、榜单、权益页在真实后端完成前的 H5 BFF mock 数据结构。

## 模板

使用：

```text
.ai-workspace/templates/API_CONTRACT.md
```
