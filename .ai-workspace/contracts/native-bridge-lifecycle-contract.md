# Native Bridge 生命周期契约

## 契约名称

Native Bridge Lifecycle Contract

## 提供方

- `app-meumall`：原生容器事件、WebView 生命周期、网络状态、登录态、内存压力、页面栈。
- `hybird-meumall`：H5 ready、路由变化、状态保存、错误上报、原生能力请求。

## 消费方

- `app-meumall`
- `hybird-meumall`

## 目标

统一原生容器和 H5 在 WebView 生命周期、tab 切换、缓存恢复、登录态变化和错误上报中的通信边界。

## Native 到 H5 事件

建议事件：

| 事件 | 触发方 | 用途 |
| --- | --- | --- |
| `tabVisible` | Native | 当前 tab WebView 变为可见 |
| `tabHidden` | Native | 当前 tab WebView 变为不可见 |
| `networkChanged` | Native | 网络状态变化 |
| `loginStateChanged` | Native | 登录、退出或切换账号 |
| `appForeground` | Native | App 回到前台 |
| `appBackground` | Native | App 进入后台 |
| `memoryWarning` | Native | 原生收到内存压力 |
| `h5ResourceVersionChanged` | Native | 本地 H5 资源版本发生变化 |

## H5 到 Native 事件

建议事件：

| 事件 | 触发方 | 用途 |
| --- | --- | --- |
| `ready` | H5 | H5 runtime 可接收事件 |
| `routeChanged` | H5 | H5 路由变化 |
| `switchTab` | H5 | 请求原生切换一级 tab |
| `openPage` | H5 | 请求原生打开二级页面 |
| `closePage` | H5 | 请求关闭当前页面 |
| `updateCartBadge` | H5 | 更新购物车角标 |
| `needLogin` | H5 | 请求原生登录流程 |
| `showToast` | H5 | 请求原生提示 |
| `reportError` | H5 | 上报 H5 错误 |
| `saveStateBeforeDestroy` | H5 | WebView 回收前保存状态 |

## 能力检测

H5 调用原生能力前必须做能力检测。缺失能力时必须走降级逻辑，不能导致页面崩溃。

原生应声明：

- App version。
- platform。
- channel。
- bridge version。
- 可用 method 列表或 capability 列表。

## 安全边界

Native Bridge 必须遵守：

- 不向任意 H5 URL 暴露高权限能力。
- 校验域名、scheme 和参数。
- 不通过普通 JS 环境直接暴露长期 token。
- 支付、账号、安全相关能力必须单独确认权限边界。
- H5 错误上报不得包含敏感信息。

## Tab 状态保存

原生准备回收某个 WebView 前，应发送 `memoryWarning` 或 `saveStateBeforeDestroy`。H5 可以保存：

- 当前路由。
- 滚动位置。
- tab 内筛选条件。
- 非敏感表单草稿。
- 公共数据快照。

H5 不得保存：

- token。
- 支付凭证。
- 交易确认结果。
- 权限判定最终结果。

## 登录态变化

登录成功：

- 原生发送 `loginStateChanged`。
- H5 刷新用户相关模块。
- 购物车和我的页面重新请求真实数据。

退出登录：

- 原生发送 `loginStateChanged`。
- H5 清理私有快照和内存状态。
- 所有相关 WebView 进入未登录态。

切换账号：

- 按退出旧账号再登录新账号处理。

## 验收要求

涉及 Native Bridge 生命周期的工作项必须验证：

- 旧 App 缺少新能力时有 fallback。
- tab 切换不会强制 reload。
- WebView 回收前状态可保存。
- 登录态变化会通知相关 WebView。
- 退出登录会清理 H5 私有缓存。
