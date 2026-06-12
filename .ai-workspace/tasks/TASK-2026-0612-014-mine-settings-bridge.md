# TASK-2026-0612-014 原生页 Bridge Route 直出

## 状态

verified

## 目标

H5 打开原生页时，通过 Native Bridge 直接使用原生页面名作为 `router/navigate payload.route`。个人中心“设置”入口点击后发送：

```json
{ "module": "router", "action": "navigate", "payload": { "route": "settings" } }
```

## 背景

此前原生页复用通用协议 `router/navigate route=native_page`，并将页面名称放在 `params.name`。当前原生侧要求改为直接使用页面名 route，例如 `route=settings`、`route=address`。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- `openNativePage(name, params)` 发送 `route: name`。
- 有额外参数时保留在 `params`，不再把页面名写入 `params.name`。
- 补充导航层回归测试。
- 更新 Native Bridge 规范和验证记录。

不包含：

- 修改原生 App。
- 新增 H5 设置页。
- 修改原生 App。

## 责任边界

`hybird-meumall`：

- 负责原生页入口发出正确 Bridge payload。

原生 App：

- 负责消费 `router/navigate route=<native-page>` 并打开对应原生页。

## 契约影响

- 是否影响跨项目契约：是
- 契约文档路径：`hybird-meumall/docs/02_NATIVE_BRIDGE_SPEC.md`
- 是否向后兼容：Bridge payload 变更，不再发送 `native_page` 包装。
- 是否需要迁移：原生侧按具体 route 消费。
- 是否需要灰度：随 H5 常规灰度。

## 验收标准

- [x] 我的页设置入口最终发出 `router/navigate route=settings`。
- [x] 其它原生页入口最终发出 `router/navigate route=<native-page>`。
- [x] payload 不再包含 `route=native_page` 或 `params.name=<native-page>`。
- [x] 导航层回归测试通过。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/lib/navigation/hybrid-navigation.test.ts src/lib/bridge/protocol-bridge.test.ts src/features/mine-secondary/mine-secondary-pages.test.tsx
pnpm typecheck
pnpm lint
```

## 发布影响

- 是否需要发布：需要随 H5 常规发版。
- 发布项目：`hybird-meumall`
- 是否需要灰度：建议按 H5 常规灰度。
- 回滚目标：回滚到原生页发送 `native_page` 包装的上一版 H5 SSR 产物。
- smoke check：App 内打开我的页，点击设置，确认原生收到 `router/navigate route=settings` 并打开设置页。

## 风险和阻塞

- 未在真实 App 内完成端上联调；需要 iOS / Android 确认原生页直接 route 已接入。
