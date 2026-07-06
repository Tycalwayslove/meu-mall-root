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

`routes` 必须以 `hybird-meumall/src/app/**/page.*` 为事实源，由 Jenkins 核心脚本或 `hybird-meumall/scripts/ai/register-release.ts` 自动发现后写入 release payload。不得把手写静态路由清单作为默认发版来源；只有临时兼容或灰度验证场景允许显式传入 `H5_ROUTES` 覆盖，并且必须在发版审核中说明原因和缺口。

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

## H5 发版审核基准门禁

H5 发版审核不是发布完成后的自由总结，而是发布流程的一部分。每次发送飞书审核消息前，必须先建立可追溯的对比基准：

- 当前线上 active 版本必须从当前发布体系读取。Jenkins/Java H5 发版以 Java H5 版本管理 active/list 接口为准，不得使用旧 Python/prod active manifest 代替。
- 必须拿到当前线上 active 版本对应的 `buildMeta.gitCommit`，并拿到本次待审核版本对应的 `buildMeta.gitCommit`。
- 改动范围必须是 `activeCommit..targetCommit`；审核消息中必须写明 `activeVersion`、`activeCommit`、`targetVersion`、`targetCommit` 和 diff 范围。
- 如果目标版本已被 promote 成 active，必须改用 `rollbackVersion` 或上一条 active/published release 的 commit 作为基准，并在审核消息中说明原因。
- 无法确认 active commit、target commit、Java release 记录或 smoke 结果时，不能发送“待审核发版通报”，只能先说明取数失败和需要补齐的权限、token 或 release 记录。

禁止把以下信息当作 H5 发版审核基准：

- 聊天上下文中的“上一次版本”。
- `hybird-meumall/package.json` 的 `version`。
- 本地最近一个 `h5/v*` tag。
- 旧 Python/prod `GET /api/h5/manifest/active?environment=prod` 返回的历史版本。
