# TASK-2026-0603-002-h5-real-release-manifest

## 状态

released

## 目标

将线上测试环境的 H5 active manifest 从初始化 seed/mock 数据切换为可联调的真实 release 版本，并明确当前发布模型和后续版本产物拆分缺口。

## 背景

线上 `https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod` 曾返回初始化默认 manifest：

- `stableVersion`: `2026.05.15-001`
- `assets.serviceBaseUrl`: `http://127.0.0.1:3109`
- `assets.basePath`: `/hybird`
- routes 包含旧入口 `/cart`、`/profile`

这会导致 App 侧认为当前 H5 版本控制仍是 mock 数据，也无法按正式域名拼接可用 WebView URL。

## 涉及项目

- `server-meumall`
- `hybird-meumall`
- 根级部署脚本

## 范围

包含：

- 注册并提升线上测试环境 active manifest。
- 将 active manifest 切换到真实测试版本 `2026.06.03-001`。
- 修正部署脚本，使 H5 容器构建和运行时可注入 `H5_VERSION`、`H5_RELEASE_LABEL`。
- 同步 release 文档和脚本测试中的当前路由示例。

不包含：

- 不重新部署线上 H5 SSR 容器。
- 不实现多个 H5 版本实例并存。
- 不增加 release API 鉴权。
- 不修改原生 App 发版包。

## 责任边界

`server-meumall`：

- 存储并返回 active manifest。
- 提供 release 注册、提升、灰度和回滚 API。

`hybird-meumall`：

- 使用部署时注入的版本环境变量显示 H5 页面版本标识。
- 通过 release 脚本生成 manifest/release 注册 payload。

根级部署脚本：

- 部署测试服务器时显式传入 H5 版本和展示标识。

## 契约影响

- 是否影响跨项目契约：是
- 契约类型：server、H5、App 共享的 manifest 契约；CI 与 server release 注册契约
- 是否向后兼容：是，manifest schema 未改变。
- 是否需要迁移：否。
- 是否需要灰度：本次测试环境直接提升为 active，灰度比例为 0。

## 对接说明

- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0603-001-h5-routes-to-native.md`
- App 侧应以 active manifest 字段判断当前版本，不以页面右上角展示文案做机器判断。

## Mock 和联调方式

- 线上 active manifest：

```text
https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod
```

- 当前测试版本：`2026.06.03-001`
- release id：`39475c30-81bd-485e-9e7a-ec29c73facb4`
- 回滚目标：`2026.05.15-001`
- 当前 SSR 域名：`https://hybird.aigcpop.com`
- 当前 basePath：空字符串，等价于根域挂载。

## 验收标准

- [x] active manifest 返回真实线上域名，不再返回 `127.0.0.1`。
- [x] active manifest 的 `stableVersion` 为 `2026.06.03-001`。
- [x] active manifest 不包含 `/cart`、`/profile`、`/agent-placeholder`。
- [x] 首页、推广、我的和商品详情测试 URL 返回 200。
- [x] 部署脚本支持 H5 版本环境变量注入。
- [ ] H5 SSR 容器已重新部署并显示 `2026.06.03-001` 页面版本标识。
- [ ] release API 增加 CI token、内网限制或管理后台审批鉴权。

## 验证命令

```bash
git diff --check
cd hybird-meumall && pnpm test -- scripts/ai/release-manifest.test.ts
cd hybird-meumall && pnpm run ai:check-workflow
cd server-meumall && .venv/bin/pytest
cd server-meumall && .venv/bin/python scripts/ai/check_workflow.py
curl -fsS 'https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod' | python3 -m json.tool
curl -fsSI 'https://hybird.aigcpop.com/'
curl -fsSI 'https://hybird.aigcpop.com/promotion'
curl -fsSI 'https://hybird.aigcpop.com/mine'
curl -fsSI 'https://hybird.aigcpop.com/product/p-1001'
```

验证结果：

- active manifest 返回 `stableVersion: 2026.06.03-001`。
- active manifest 返回 `assets.serviceBaseUrl: https://hybird.aigcpop.com`。
- active manifest 返回 `assets.basePath: ""`，表示根域挂载。
- active manifest 返回 19 条 route。
- active manifest 返回当前 H5 路由集合，无旧购物车和旧个人页入口。
- `/`、`/promotion`、`/mine`、`/product/p-1001` 均返回 HTTP 200。
- `git diff --check`：通过。
- `hybird-meumall pnpm test -- scripts/ai/release-manifest.test.ts`：通过，12 个测试文件、72 个测试通过。
- `hybird-meumall pnpm run ai:check-workflow`：通过。
- `server-meumall .venv/bin/pytest`：通过，14 个测试通过，1 个 Starlette/httpx deprecation warning。
- `server-meumall .venv/bin/python scripts/ai/check_workflow.py`：通过。

## 发布影响

- 是否需要发布：是，已切换线上测试 active manifest。
- 发布项目：`server-meumall` active manifest 数据。
- 是否需要灰度：否，`grayRules.percentage` 为 0。
- 回滚目标：`2026.05.15-001`。
- smoke check：已通过基础 HTTP 状态检查。

## 风险和阻塞

- 当前 H5 页面右上角仍可能显示旧容器运行时标识，例如 `H5 blue`；需要重新部署 H5 SSR 容器并传入 `H5_VERSION=2026.06.03-001`、`H5_RELEASE_LABEL=2026.06.03-001`。
- 当前部署模型仍是单 H5 SSR 实例替换，不是多个版本产物并存。manifest 目前控制的是 active 指针，不保证旧版本服务同时在线。
- release API 测试环境目前可公网调用，正式环境必须增加鉴权或网络限制。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-03 | released | 注册 release `2026.06.03-001` 并提升为线上测试 active manifest，完成基础 smoke。 |
