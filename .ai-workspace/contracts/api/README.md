# H5 与后端 API 契约

本目录记录 `hybird-meumall` 作为消费方需要后端提供的业务 API 契约。

## 适用范围

- H5 页面数据接口。
- H5 操作提交接口。
- 登录态、鉴权、分页、缓存和错误码约定。
- H5 与正式业务后端之间的请求和响应结构。

## 已有契约

- `h5-bff-http-auth-contract.md`：定义 App Cookie 登录态、H5 BFF、Python / Java Authorization 鉴权之间的转换规则。
- `promotion-bff-mock-contract.md`：定义推广模块首页、活动、榜单、权益页在真实后端完成前的 H5 BFF mock 数据结构。

## 模板

使用：

```text
.ai-workspace/templates/API_CONTRACT.md
```
