# 发布治理

## 目标

发布流程必须可验证、可灰度、可回滚。AI 不能只完成代码，还必须说明上线影响。

## 发布对象

- H5 SSR release。
- manifest active config。
- server API 行为。
- admin 发布操作台。
- iOS WebView 壳。
- CI pipeline。

## 发布影响声明

每个工作项必须写明：

- 是否需要发布。
- 发布哪个项目。
- 是否影响 manifest。
- 是否影响 API 契约。
- 是否需要灰度。
- 回滚目标是什么。
- smoke check 怎么做。

## H5 发布规则

H5 release 必须能通过 manifest 切换。发布记录应包含：

- version。
- environment。
- serviceBaseUrl。
- basePath。
- rollbackVersion。
- routes。
- buildMeta。

## 灰度规则

灰度必须明确：

- 灰度版本。
- 稳定版本。
- 灰度比例。
- 命中规则。
- 观察指标。
- 停止或扩大灰度条件。

## 回滚规则

回滚必须明确：

- 异常版本。
- 目标版本。
- 是否加入 blacklist。
- 回滚后如何验证。
- 是否需要通知 H5、admin、app 或 CI。

## 发布完成定义

有发布影响的任务只有满足以下条件才能标记为 `released`：

- release 或 active config 已记录。
- smoke check 已通过或限制已记录。
- 回滚路径可用。
- 任务文件记录发布结果。
