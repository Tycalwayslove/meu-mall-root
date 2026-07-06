# 术语表

## H5

运行在浏览器或外部 App WebView 中的 Web 应用。当前仓库只维护 `hybird-meumall`。

## Hybrid App

外部 App 容器加 H5 页面组成的运行形态。当前仓库不再维护 iOS/macOS 壳。

## Manifest

描述 H5 版本、资源地址、路由、灰度和回滚信息的运行时配置。

## Active Manifest

当前环境正在生效的 manifest。当前由外部 Java H5 版本管理接口 `GET /platform/h5Release/active` 返回。

## Release

一次可被发布、灰度或回滚的 H5 版本记录。

## Candidate

已注册但未成为 active 的 release。

## Gray

灰度发布。通过 manifest 中的 `grayVersion` 和 `grayRules` 控制部分用户命中新版本。

## Rollback

回滚。将异常版本切回目标版本，并在需要时加入 blacklist。

## Native Bridge

H5 与外部 App/WebView 运行环境通信的接口层。本仓库只维护 H5 侧调用和 fallback。

## 契约

两个或多个项目之间共享的接口、数据结构或行为约定。

## 工作项

AI 和人类推进正式开发的最小单位，包含目标、范围、验收、验证和发布影响。

## Public API

可公开缓存或短缓存的接口，例如首页配置、分类树、帮助文档和商品基础信息。

## Private API

用户私有接口，例如我的页面、推广收益、佣金、订单或购买记录、优惠券和会员/达人信息。默认不得被共享缓存。

## Transactional API

交易类接口，例如下单、支付、库存锁定、价格确认和优惠券核销。必须实时确认，不能使用缓存结果继续流程。

## 弱快照

弱网或无网时用于展示的上次成功数据。弱快照只能辅助查看，不能作为交易、支付、库存、余额或权限判断的最终依据。

## Native Cache

外部运行环境管理的本地缓存。可用于 H5 静态资源包或非敏感业务快照，不能保存服务端密钥或不经确认的交易结果。
