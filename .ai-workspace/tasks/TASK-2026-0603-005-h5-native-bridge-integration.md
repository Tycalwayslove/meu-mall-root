# TASK-2026-0603-005-H5 与原生 App Bridge 联调机制

## 状态

implemented

## 目标

基于 `aigcpop/MallProject` 的 Bridge 调用清单，为 MeuMall 建立一套可长期维护、可扩展、可联调的 H5 与原生 App Bridge 机制。

本阶段原目标是完成方案、契约和对接说明。2026-06-03 用户进一步确认先在 H5 首页增加能力测试按钮，并让 App 侧只接收消息和占位回调，不实现真实原生业务。

## 背景

MeuMall H5 后续需要频繁调用原生能力，例如获取 token、页面导航、分享、支付、保存图片、接收登出事件等。如果每个页面单独约调用方式，会导致 H5、iOS、Android 三端长期维护困难。

当前现状：

- `hybird-meumall` 已有 typed bridge adapter、Web mock 和首批简化方法。
- `app-meumall` 已有 SwiftUI / WKWebView / manifest runtime，但尚未正式实现 Bridge runtime。
- 外部参考仓库 `aigcpop/MallProject` 提供了 `bridgeHandler`、统一信封、router/event/rpc、callbackId 和错误码示例。

## 涉及项目

- `hybird-meumall`
- `app-meumall`

## 范围

包含：

- 建立 MeuMall Native Bridge 总协议草案。
- 建立面向原生 App 的 Bridge 对接说明。
- 梳理 H5 侧和 App 侧的分层实现方案。
- 分类首批 P0/P1/P2 Bridge 能力。
- 明确 token、导航、事件、RPC、错误码、能力检测和 fallback。
- 在 H5 首页增加 Bridge 调试面板。
- 在 App WebView 中注册 `bridgeHandler` debug receiver，只接收消息并对 RPC 返回 debug 占位结果。
- 将包含首页 Bridge 调试面板的 H5 版本发布为测试环境 candidate，供 App WebView 联调加载。

不包含：

- 不实现 Android Bridge。
- 不实现支付、相册、定位、剪贴板等高风险能力。
- 不实现真实原生登录、导航、分享、支付或 token 业务。
- 不自动切换 active manifest，不影响当前线上稳定 H5 入口。

## 责任边界

`hybird-meumall`：

- 提供 Bridge facade、typed adapter、callback registry、Web mock。
- 消费 App 提供的 token、设备信息、导航、事件能力。
- 实现 Bridge 不可用时的 fallback。
- 不保存长期 token，不实现原生登录、支付、安全能力。

`app-meumall`：

- 注册 WebView Bridge handler。
- 解码统一 Bridge 信封。
- 当前只实现 debug receiver：`getDeviceInfo` / `getTokens` 返回 debug resolve，其它 rpc 返回 `unsupported`。
- router/event 当前只接收打印，不执行真实业务。
- 后续由原生 App 方实现真实 token、设备信息、导航、事件下发等 P0 能力。
- 校验可信域名和 URL 白名单。
- 不实现 H5 页面业务逻辑。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：`.ai-workspace/contracts/native-bridge/meumall-bridge-protocol.md`
- 是否向后兼容：当前为草案；实现时应兼容 H5 Web mock 和旧 App 无 Bridge 场景。
- 是否需要迁移：后续 H5 需要从简化 `nativeBridge.call(method, payload)` 逐步迁移到 `bridge.navigate`、`bridge.emit`、`bridge.rpc`、`bridge.on`。
- 是否需要灰度：Bridge runtime 上线时需要按 App 测试包和 H5 manifest 灰度控制。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0603-002-h5-native-bridge-integration.md`
- 需要确认的角色：原生 App
- 当前确认状态：暂用 mock

## 对方责任

后端：

- 本阶段无直接后端依赖。
- 后续 API client 使用 token 时，需要再确认 Python 后端和 mall4j 的 header 规则。

原生 App：

- 确认统一信封、handler 名和命名空间。
- 确认 P0 能力是否可实现。
- 确认最低 App 版本、测试包版本和错误码。
- 在 debug receiver 基础上替换真实业务 handler。

管理后台：

- 本阶段无直接依赖。
- 后续高风险能力可通过配置隐藏入口。

CI 或发布：

- 已将 H5 `v1.0.3` 发布到测试环境并 promote 为 active。
- 当前 active manifest 已指向 `v1.0.3`，App 重新拉取 manifest 后会加载带首页 Bridge 调试面板的 H5。
- `v1.0.2` 当前作为 rollback 目标保留。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/lib/bridge`。
- 测试接口环境：测试环境 H5 通过 active manifest 加载。
- App 测试包版本：当前本地 `app-meumall` debug build。
- 管理后台测试入口：无。
- 联调步骤：见 `.ai-workspace/integration-briefs/BRIEF-2026-0603-002-h5-native-bridge-integration.md`。
- H5 fallback：无 Bridge 时使用 Web mock 或隐藏入口；token 失败时进入未登录状态；导航失败时使用 H5 内部路由或 history。

## 实现计划

1. 已完成总协议草案和对接说明。
2. 已完成 H5 首页 Bridge 调试面板和统一信封 runtime。
3. 已完成 App `bridgeHandler` debug receiver 和占位 RPC 回传。
4. 后续由原生 App 方在 debug receiver 基础上接真实 handler。
5. 后续双方在测试 App + 测试 H5 上联调 P0 真实能力。
6. P0 稳定后拆分支付、相册、分享增强等 P1/P2 子任务。

## 验收标准

- [x] Bridge 总协议草案已建立。
- [x] P0 能力清单已形成：getTokens、getDeviceInfo、navigate、token_expired、logout。
- [x] H5 首页调试面板和统一信封 runtime 验证通过。
- [x] App 侧 debug receiver 可返回 `getTokens` / `getDeviceInfo` 占位 RPC 结果。
- [x] H5 无 Bridge 时会展示错误日志，不导致页面白屏。
- [ ] Bridge 总协议被真实 App 方确认。
- [ ] App 侧真实 P0 handler 可用。
- [ ] token 不进入普通 H5 缓存、URL、日志或埋点。
- [ ] 真实联调记录和测试报告已更新。

## 验证命令

```bash
# 根级文档检查
test -f .ai-workspace/contracts/native-bridge/meumall-bridge-protocol.md
test -f .ai-workspace/integration-briefs/BRIEF-2026-0603-002-h5-native-bridge-integration.md

cd hybird-meumall
pnpm test src/lib/bridge/protocol-bridge.test.ts
pnpm test
pnpm typecheck
pnpm build
pnpm run ai:check-workflow

cd app-meumall
bash scripts/ai/check-workflow.sh
plutil -lint meumall/Info.plist
xcodebuild test -project meumall.xcodeproj -scheme meumall -destination 'platform=iOS Simulator,id=D70F04ED-0C7B-4926-89FB-99AC89402147' -only-testing:meumallTests/meumallTests/bridgeReceiverDecodesMessagesAndBuildsPlaceholderReplies -only-testing:meumallTests/meumallTests/bridgeReceiverRejectsUnsupportedRpcWithoutBusinessHandling
xcodebuild build -project meumall.xcodeproj -scheme meumall -destination 'platform=iOS Simulator,id=D70F04ED-0C7B-4926-89FB-99AC89402147'
```

## 发布影响

- 是否需要发布：已发布 H5 active。
- 发布项目：`hybird-meumall`。
- candidate 版本：`v1.0.3`。
- Git commit：`32b2834ac6554122808cda0b8a831c64f5869612`。
- Git tag：`h5/v1.0.3`。
- 访问入口：`https://hybird.aigcpop.com/h5-v/v1.0.3`。
- release id：`f7dbe687-6875-46d8-817b-c942cf9db190`。
- 当前状态：`active`，已 promote。
- active manifest：`stableVersion=v1.0.3`，`configVersion=config-v1.0.3`，`basePath=/h5-v/v1.0.3`。
- 回滚目标：`v1.0.2`。
- smoke check：远端容器 `/api/health`、公网 HTTPS `/h5-v/v1.0.3/api/health` 和页面入口均通过。

## 风险和阻塞

- App 方尚未确认最低版本和具体实现排期。
- Android 侧调用入口只按参考清单预留，当前项目没有 Android 代码。
- token header 细节仍需结合真实后端接口确认。
- 支付、相册、定位等高风险能力必须另建子契约，不应混入 P0。
- H5 `v1.0.3` 已切为 active；App 如存在 manifest 本地缓存，需要在 App 内刷新配置或等待缓存过期后再进入 H5。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-03 | draft | 基于 `MallProject` 示例创建 Bridge 总协议、对接说明和工作项。 |
| 2026-06-03 | implemented | H5 首页增加 Bridge 调试面板；App 增加 debug receiver，只接收消息和占位 RPC 回传。 |
| 2026-06-03 | implemented | H5 `v1.0.3` 发布为 candidate，远端 smoke 通过，active manifest 保持 `v1.0.2`。 |
| 2026-06-03 | implemented | 调用 release promote 接口将 `v1.0.3` 切为 active；验证 active manifest、health 和页面入口均通过。 |
