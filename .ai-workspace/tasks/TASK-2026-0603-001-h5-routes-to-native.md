# TASK-2026-0603-001-h5-routes-to-native

## 状态

implemented

## 目标

梳理并同步 H5 当前页面路由给原生 App，明确一级 Tab、二级页面、active manifest 读取规则、URL 拼接规则和版本识别方式，作为原生调整 Tab、WebView 加载、fallback manifest 和联调验证的依据。

## 背景

当前项目已经确认一级 Tab 应围绕首页、智能体、推广、我的展开。H5 已实现多条页面路由，App 需要通过 active manifest 读取当前 H5 版本、资源入口和 route map，再拼接最终 WebView URL。

本任务已从对接说明扩展为文档、H5 route、server 默认 manifest 和 App fallback route 的一致性同步。

## 涉及项目

- `hybird-meumall`
- `app-meumall`
- `server-meumall`

## 范围

包含：

- 盘点 H5 当前真实页面路由。
- 明确原生一级 Tab 应使用的 H5 route。
- 输出给原生 App 的对接说明。
- 建立 H5 与原生的路由契约。
- 移除 H5 旧兼容页面文件。
- 同步 server 默认 manifest routes。
- 同步 App Tab route、本地 fallback manifest 和测试。
- 在 H5 页面右上角展示版本标识。

不包含：

- 不新增 Native Bridge 方法。
- 不新增后端业务接口。
- 不处理登录/token 注入契约。
- 不直接操作线上 active manifest。

## 责任边界

`hybird-meumall`：

- 提供当前 H5 页面路由清单。
- 页面右上角展示 H5 版本标识。
- 后续新增或删除页面时同步更新路由契约。

`app-meumall`：

- 按路由契约调整一级 Tab 和 WebView route。
- 将智能体作为原生 Tab，不参与 H5 URL 拼接。
- 调整 fallback manifest 和相关测试。

`server-meumall`：

- 按契约更新默认 manifest routes。
- 后续由 admin/server 流程更新线上 active manifest。

## 契约影响

- 是否影响跨项目契约：是
- 契约文档路径：`.ai-workspace/contracts/h5-native-route-contract.md`
- 是否向后兼容：不保留旧 H5 兼容路由作为正式入口。
- 是否需要迁移：需要原生 App 和 manifest 按当前 route contract 调整。
- 是否需要灰度：暂不需要，后续如进入 App 发版或 manifest 切换，再按发布策略确认。

## 对接说明

- 是否需要对接说明：是
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0603-001-h5-routes-to-native.md`
- 需要确认的角色：原生 App / 后端 Manifest 服务
- 当前确认状态：待确认

## 对方责任

后端：

- 更新 active/default manifest routes。
- 确认 manifest 是否支持动态模板路由，例如 `/product/{id}`。

原生 App：

- 确认一级 Tab 调整：首页、智能体、推广、我的。
- 确认智能体 Tab 走原生实现，不参与 H5 URL 拼接。
- 更新 fallback manifest、route enum 和相关测试。

管理后台：

- 本任务无管理后台配置调整。

CI 或发布：

- 路由同步本身不要求重新发布原生 App。
- 线上测试 active manifest 已在 `TASK-2026-0603-002-h5-real-release-manifest` 中切换到 `2026.06.03-001`，后续 H5 SSR 容器版本标识仍需重新部署验证。

## Mock 和联调方式

- Mock 数据位置：本任务不新增 mock 数据。
- 测试接口环境：`https://hybird.aigcpop.com`
- App 测试包版本：待原生确认。
- 管理后台测试入口：无。
- 联调步骤：
  1. App 拉取测试环境 manifest。
  2. 点击首页、推广、我的 Tab，确认 WebView URL 分别为 `/`、`/promotion`、`/mine`。
  3. 点击智能体 Tab，确认进入原生页面。
  4. 从 H5 内部进入分类、消息、商品详情、订单、收藏、推广二级页面。
  5. 确认 App Tab、fallback manifest、测试和 H5 route 清单与本文一致。
- H5 fallback：新 route 不可用时回到 `/` 或 `/mine`。

## 实现计划

1. 完成 H5 路由盘点。
2. 生成 H5 与原生路由契约。
3. 生成原生对接说明。
4. 同步 H5、server 和 App 代码中的 route。
5. 运行 H5、server、App 的最小验证。
6. 待原生和后端确认线上 active manifest 后进入联调。

## 验收标准

- [x] 对接说明包含一级 Tab、二级页面、active manifest 读取规则和 URL 拼接规则。
- [x] 对接说明明确 App 通过 active manifest 获取当前 H5 入口，不写死域名和版本。
- [x] 对接说明解释 `stableVersion/grayVersion/configVersion` 的含义和读取规则。
- [x] 对接说明给出首页从 manifest 到 finalUrl 的完整加载流程。
- [x] H5 页面右上角展示版本标识。
- [x] 路由契约明确智能体由原生承载，不参与 H5 URL 拼接。
- [x] 原生侧需要调整的文件和验证步骤已列出。
- [x] 后端/Manifest 服务需要调整的内容已列出。
- [ ] 原生 App 和后端/Manifest 负责人完成确认。

## 验证命令

```bash
git diff --check
cd hybird-meumall && pnpm test -- src/lib/commerce/mock-data.test.ts
cd hybird-meumall && pnpm typecheck
cd server-meumall && pytest
cd server-meumall && python scripts/ai/check_workflow.py
cd app-meumall && bash scripts/ai/check-workflow.sh
cd app-meumall && plutil -lint meumall/Info.plist
cd app-meumall && xcodebuild test -project meumall.xcodeproj -scheme meumall -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:meumallTests
```

验证结果：

- `git diff --check`：通过。
- `hybird-meumall pnpm test -- src/lib/commerce/mock-data.test.ts`：通过，12 个测试文件、72 个测试通过。
- `hybird-meumall pnpm typecheck`：通过。首次失败是 `.next` 缓存仍引用已删除页面，清理 `.next` 后通过。
- `server-meumall .venv/bin/pytest`：通过，14 个测试通过，1 个 Starlette/httpx deprecation warning。
- `server-meumall .venv/bin/python scripts/ai/check_workflow.py`：通过。
- `app-meumall bash scripts/ai/check-workflow.sh`：通过。
- `app-meumall plutil -lint meumall/Info.plist`：通过。
- `app-meumall xcodebuild test ... -only-testing:meumallTests`：通过，2 个测试通过；Xcode 保存 `.xcresult` 时出现结果包写入 warning，但测试结果为 `TEST SUCCEEDED`。

## 发布影响

- 是否需要发布：代码变更后需要随各项目后续发布进入对应环境。
- 发布项目：`hybird-meumall`、`server-meumall`、`app-meumall`
- 是否需要灰度：无。
- 回滚目标：如后续联调失败，回退到上一版 App 包、上一版 H5 release 或上一版 active manifest。
- smoke check：后续联调时检查首页、推广、我的和 H5 版本标识。

## 风险和阻塞

- 原生端尚未完成对接说明确认。
- server manifest 是否支持动态 route template 仍待确认。
- 登录/token 注入契约尚未定义，实际打开私有页面可能需要另行联调。
- 线上测试 active manifest 已切换为本文 route map；H5 SSR 容器运行时标识仍待重新部署后确认。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-03 | draft | 创建 H5 路由同步给原生端的工作项、对接说明和路由契约。 |
| 2026-06-03 | draft | 按 App 接入视角重写对接说明，补充 manifest 获取、URL 拼接、版本识别和当前测试 active manifest 注意事项。 |
| 2026-06-03 | draft | 按最新要求移除旧兼容路由说明，补充字段读取规则、详细 URL 拼接流程和 H5 右上角版本标识，并同步 H5/server/App route 代码。 |
| 2026-06-03 | implemented | H5、server、App 和文档同步完成，最小验证通过；待 App 与 Manifest 服务确认后进入联调。 |
| 2026-06-03 | implemented | 线上测试 active manifest 已通过 `TASK-2026-0603-002-h5-real-release-manifest` 切换到 `2026.06.03-001`。 |
