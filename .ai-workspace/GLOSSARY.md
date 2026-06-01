# 术语表

## H5

运行在原生 App WebView 中的 Web 应用。当前对应 `hybird-meumall`。

## Hybrid App

原生壳加 H5 页面组成的 App。当前 iOS/macOS 壳对应 `app-meumall`。

## Manifest

描述 H5 版本、资源地址、路由、灰度和回滚信息的运行时配置。

## Active Manifest

当前环境正在生效的 manifest。由 `server-meumall` 的 `/api/h5/manifest/active` 返回。

## Release

一次可被发布、灰度或回滚的 H5 版本记录。

## Candidate

已注册但未成为 active 的 release。

## Gray

灰度发布。通过 manifest 中的 `grayVersion` 和 `grayRules` 控制部分用户命中新版本。

## Rollback

回滚。将异常版本切回目标版本，并在需要时加入 blacklist。

## Native Bridge

H5 与原生 App 通信的接口层。

## 契约

两个或多个项目之间共享的接口、数据结构或行为约定。

## 工作项

AI 和人类推进正式开发的最小单位，包含目标、范围、验收、验证和发布影响。
