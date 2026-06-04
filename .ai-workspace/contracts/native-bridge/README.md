# H5 与 Native Bridge 契约

本目录记录 `hybird-meumall` 调用原生 App 能力的契约。

## 适用范围

- 登录、分享、支付、跳转、定位、图片预览等原生能力。
- H5 到 Native 的方法名、参数、返回值、错误码和超时。
- 最低 App 版本、能力检测和 H5 fallback。

## 当前契约

| 契约 | 状态 | 说明 |
| --- | --- | --- |
| `meumall-bridge-protocol.md` | draft | MeuMall H5 与原生 App Bridge 总协议，包含统一信封、router/event/rpc、错误码、能力检测和 P0/P1/P2 能力分组。 |

## 模板

使用：

```text
.ai-workspace/templates/NATIVE_BRIDGE_CONTRACT.md
```
