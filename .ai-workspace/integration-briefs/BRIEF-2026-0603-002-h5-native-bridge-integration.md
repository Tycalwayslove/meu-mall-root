# 对接说明：H5 与原生 App Bridge 联调

## 基本信息

- 编号：BRIEF-2026-0603-002
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0603-005-h5-native-bridge-integration.md`
- 状态：draft
- H5 负责人：待确认
- 原生 App 负责人：待确认
- 目标联调时间：待确认
- 目标上线环境：测试环境

## 需求背景

MeuMall H5 页面运行在原生 App WebView 中。后续首页、商品详情、推广、我的等页面都需要登录态、设备信息、原生导航、登出通知、分享、支付或系统能力支持。

当前双方需要先把 Bridge 基础通道打通，避免后续每个页面各自约一套调用方式。

## H5 侧目标

- 建立统一 Bridge facade，业务代码只调用 `bridge.navigate`、`bridge.emit`、`bridge.rpc`、`bridge.on`。
- 支持 iOS、Android 和 Web mock 三种运行环境。
- 调用前进行能力检测。
- 对 Bridge 不存在、App 版本过低、超时、原生失败提供 fallback。
- token 不进入普通 H5 缓存，不写入 URL、日志或 localStorage。

## 页面范围

| 页面 | 路由 | 端归属 | Bridge 依赖 |
| --- | --- | --- | --- |
| 首页 | `/` | H5 内容 + App Tab | token、设备信息、导航、消息/分享入口后续扩展 |
| 商品详情 | `/product/[id]` | H5 | token、商品分享、立即购买后续支付 |
| 推广 | `/promotion` | H5 | token、分享、保存海报后续扩展 |
| 我的 | `/mine` | H5 | token、登出通知、用户状态刷新 |
| 智能体 Tab | App 原生 | App | 不由 H5 Bridge 实现业务页面 |

## 数据流

```text
H5 页面
  -> Bridge facade
  -> 统一信封 { module, action, payload, callbackId }
  -> App bridgeHandler
  -> App 原生服务
  -> window.__bridgeHandler.resolve/reject/emit
  -> H5 渲染/跳转/兜底
```

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 是 | 实现 `bridgeHandler`、RPC 回传和事件下发。 | `.ai-workspace/contracts/native-bridge/meumall-bridge-protocol.md` |
| 原生页面跳转 | 是 | `router/navigate` 支持 home、back、product_detail、webview。 | 同上 |
| 登录态 | 是 | `rpc/getTokens` 提供 H5 请求所需 token。 | 同上 |
| 最低 App 版本 | 是 | App 方确认 P0 能力起始版本。 | 同上 |
| fallback | 是 | 不支持能力时返回 `unsupported`，不要静默失败。 | 同上 |

## H5 侧责任

- [ ] 将现有 `src/lib/bridge` 从简化 `call(method, payload)` 升级为信封协议 adapter。
- [ ] 提供 `bridge.navigate`、`bridge.emit`、`bridge.rpc`、`bridge.on`。
- [ ] 实现 callback registry、timeout、错误归一化。
- [ ] 实现 Web mock 和联调测试页。
- [ ] API client 接入 `getTokens`，并区分 `accessToken` 与 `mallToken` 的出站 header。
- [ ] Bridge 不可用时，页面不白屏，入口降级或隐藏。

## 原生 App 侧责任

- [ ] 在 WebView 中注册 `bridgeHandler`。
- [ ] 解码统一信封 `{ module, action, payload, callbackId }`。
- [ ] 实现 P0 RPC：`getTokens`、`getDeviceInfo`。
- [ ] 实现 P0 router：`home`、`back`、`product_detail`、`webview`。
- [ ] 实现 P0 event：接收 `token_expired`，下发 `logout`。
- [ ] 失败时按错误码返回 `unknown`、`timeout`、`cancelled`、`permission_denied`、`unsupported`、`invalid_payload`。
- [ ] 对 `webview` URL 做白名单校验。
- [ ] 明确最低 App 版本、测试包版本和能力列表。

## 首批 P0 能力

| 能力 | 调用方式 | 用途 | 完成口径 |
| --- | --- | --- | --- |
| 获取 token | `bridge.rpc("getTokens")` | H5 API 请求鉴权。 | H5 能拿到 `accessToken`、`mallToken`、`expiredAt`。 |
| 获取设备信息 | `bridge.rpc("getDeviceInfo")` | 能力检测和运行诊断。 | 返回平台、版本、build、bridgeVersion。 |
| 原生导航 | `bridge.navigate(payload)` | 页面栈、Tab 和 WebView 打开。 | home/back/product_detail/webview 可用。 |
| token 失效 | `bridge.emit("token_expired")` | H5 通知原生统一登录处理。 | 原生收到后可处理登录失效。 |
| 登出通知 | `bridge.on("logout")` | 原生通知 H5 清理状态。 | H5 收到后清理私有状态。 |

## 暂不纳入 P0

- 支付。
- 保存图片/海报。
- 相机、相册。
- 定位。
- 剪贴板。
- 打开外部 App。
- 推送、IM、智能体业务。

这些能力后续必须各自建立子契约。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/lib/bridge` 的 Web mock。
- App 测试包版本：待 App 方提供。
- 测试环境 H5：`https://hybird.aigcpop.com/h5-v/v1.0.2/`，后续按 active manifest 切换。
- 联调入口：建议新增 H5 Bridge 调试页，例如 `/debug/bridge`，只在测试环境开放。

联调步骤：

1. 打开测试 App，加载测试环境 H5。
2. 进入 Bridge 调试页。
3. 点击 `getDeviceInfo`，验证 App 版本、平台和能力列表。
4. 点击 `getTokens`，验证 token 返回和 H5 内存态保存。
5. 点击导航按钮，验证 home/back/product_detail/webview。
6. H5 触发 `token_expired`，验证 App 侧处理。
7. App 触发 `logout`，验证 H5 清理状态。
8. 分别验证 unsupported、invalid_payload、timeout。

## H5 兜底策略

- 无 Bridge：使用 Web mock，仅限本地或测试页；正式业务入口隐藏需要原生能力的按钮。
- token 不可用：页面进入未登录状态，请求不继续发出。
- 导航不可用：H5 先尝试内部路由或浏览器 history，不能完成时隐藏入口。
- 分享不可用：隐藏分享或复制链接。
- logout 事件不可用：H5 依赖接口 401 触发 `token_expired` 兜底。

## 验收标准

- [ ] H5 和 App 双方确认统一信封、handler 名和回传命名空间。
- [ ] H5 P0 Bridge mock 测试通过。
- [ ] App P0 Bridge 测试包可用。
- [ ] `getTokens` 不把 token 写入 localStorage、URL 或日志。
- [ ] `getDeviceInfo` 可用于能力检测。
- [ ] unsupported、timeout、invalid_payload 均有明确错误处理。
- [ ] H5 页面在 Bridge 不存在时不白屏。
- [ ] 联调结果写回工作项和测试报告。

## 对外沟通摘要

```text
本次 H5 与原生 App 需要先统一 Native Bridge 协议。

请 App 侧确认并实现：
1. 注册 WebView message handler：bridgeHandler。
2. 支持 H5 发送统一信封：{ module, action, payload, callbackId }。
3. 支持 RPC 回传：window.__bridgeHandler.resolve/reject。
4. 支持事件下发：window.__bridgeHandler.emit。
5. 首批实现 getTokens、getDeviceInfo、navigate、token_expired、logout。
6. 返回统一错误码，不支持能力时返回 unsupported。

契约文档：
.ai-workspace/contracts/native-bridge/meumall-bridge-protocol.md

联调方式：
测试 App 加载测试环境 H5，进入 H5 Bridge 调试页，逐项验证 P0 能力。

验收口径：
P0 能力成功、失败、超时、无 Bridge 四种路径均可验证，H5 不白屏，token 不落普通缓存。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-03 | H5 | draft | 基于 `MallProject` 示例形成 MeuMall Bridge 草案，待 App 方确认。 |
