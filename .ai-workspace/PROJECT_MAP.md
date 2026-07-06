# H5 工作区地图

## 总览

```text
hybird-meumall -> Java business APIs
hybird-meumall build -> Java H5 Release APIs -> active manifest
nginx/register-resolver -> Java active manifest -> /h5-v/<active>/register
```

## 当前维护项目

### hybird-meumall

H5 商城前台。负责 WebView 内的用户体验、页面路由、H5 runtime、API client、主题、telemetry 和 Native Bridge 消费边界。

不负责：

- manifest 服务端存储。
- iOS WebView 容器实现。
- Java 业务接口实现。
- Java H5 版本管理和 release 管理台。
- 旧 Python server/admin 运行服务。

## 外部系统

### Java 后端与 Java H5 版本管理

Java 是当前正式后端和版本管理事实源，负责：

- 业务 API。
- H5 release 记录。
- active manifest。
- promote、rollback、list 等版本管理能力。
- 管理后台能力。

H5 只通过环境配置和契约消费 Java 能力。

### iOS / App

iOS / App 是外部运行环境。当前仓库不实现 iOS WebView、原生 Tab、Bridge 或 App 页面。H5 需求如涉及 App 能力，只记录 H5 侧调用假设和 fallback，不把 iOS 改造纳入验收。

## 已移除目录

- `server-meumall`：旧 Python FastAPI 配置和 release 服务，已从当前工作区移除。
- `admin-meumall`：旧本地管理后台，已从当前工作区移除。
- `app-meumall`：旧 SwiftUI 壳，已从当前工作区移除。
- `meumall-ci`：旧本地 Jenkins 工作区，已从当前工作区移除。
- `deploy/docker/server.Dockerfile`、`deploy/docker/admin.Dockerfile`、旧全栈 compose 链路：已从当前工作区移除。

## 变更规则

- H5 调用 Java 后端：先更新 H5 侧 API 契约或联调说明，再实现 H5。
- H5 发布流程变化：先更新 H5 release 文档，再改根级 H5 发布脚本。
- manifest schema 变化：评估 H5 runtime、H5 发布脚本和 Java H5 版本管理接口，不再评估旧 Python server/admin/iOS 项目。
- 任何新需求不得恢复 `server-meumall`、`admin-meumall`、`app-meumall` 或 `meumall-ci` 目录。
