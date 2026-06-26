# TASK-2026-0624-016 H5 商品详情地址 Bridge 接入

## 状态

blocked

## 目标

将商品详情、订单确认和地址管理的地址来源从“只依赖 H5 BFF/Java 接口”升级为“优先通过 App Native Bridge 获取和管理地址，H5 BFF 作为兜底与服务端校验”，补齐旧 uni-app 地址逻辑迁移到 App Hybrid 的变通方案。

## 背景

旧 uni-app 地址逻辑依赖小程序/uni 环境：

- 地址列表：`package-user/pages/delivery-address/delivery-address.vue`
- 新增/编辑地址：`package-prod/pages/edit-address/edit-address.vue`
- 订单确认地址展示：`package-prod/pages/submit-order/submit-order.vue`

当前 H5 已有 `/address`、`/address/edit` 和 Java 地址 BFF，但 App Hybrid 场景要求地址能力由 App 通过 Bridge 提供，H5 不应只假设浏览器能直接完成地址管理。

## 范围

包含：

- 扩展 H5 Bridge typed RPC：`address.getDefault`、`address.getList`、`address.getInfo`、`address.save`、`address.setDefault`、`address.delete`、`address.chooseLocation`。
- 新增 H5 `createHybridAddressApi()`，优先调用 App Bridge，Bridge 不可用/不支持时回退现有 H5 BFF。
- `/address` 地址列表、设默认、删除接入 Hybrid Address API。
- `/address/edit` 地址详情回填和新增/编辑保存接入 Hybrid Address API。
- `/address/edit` 省市区从空输入改为 Java `/p/area/listByPid` 真实接口级联选择；接口未返回时不展示本地选项。定位按钮预留 `address.chooseLocation` Bridge，并输出 `[MeuMall][address-location]` 本地调试日志。
- `/address/edit?addrId=<addrId>` 编辑回显时按地址详情里的 `provinceId/cityId/areaId` 级联加载真实省市区 options，避免 select 只有文本值但没有真实选项。
- 商品详情页加载默认地址，展示在“配送”行；有默认地址时用真实 `addrId` 重新请求商品详情 BFF。
- 订单确认页无 `addressId` 时，先通过 Bridge 获取默认地址，再带 `addrId` 请求订单确认 BFF。
- App debug Bridge receiver 不再内置调试地址样例；正式地址来源以 Bridge/BFF/Java 返回为准。

不包含：

- App 正式地址数据源实现。
- 完整全国行政区树、地图选点和 App 真实定位实现。
- 支付 Bridge。

## 迁移计划

1. 旧地址页行为梳理：列表、默认、删除、编辑、新增、保存校验、订单确认选择地址。
2. H5 抽象统一地址 API：业务页面不直接依赖 `window.webkit` 或 Java BFF。
3. App Bridge 优先：App 可用时由 `rpc/address.*` 提供地址数据和 mutation 结果。
4. H5 BFF 兜底：本地浏览器、老 App 或 Bridge unsupported 时继续使用 `/api/bff/address/*`。
5. 交易安全兜底：订单确认和提交 BFF 仍会用 Java `/p/address/addrInfo/{addrId}` 校验真实地址，避免只信任前端/Bridge 返回值。

## 验收标准

- [x] H5 Bridge adapter 发出的地址 RPC 使用统一 `{ module:"rpc", action:"address.*", callbackId, payload? }` 信封。
- [x] 地址页和编辑页优先使用 Bridge 地址能力，Bridge 不可用时回退 BFF。
- [x] 商品详情配送行显示默认收货地址，并可进入地址管理。
- [x] 商品详情真实 BFF 支持 `addrId` query。
- [x] 订单确认页无地址参数时先通过 Bridge 获取默认地址。
- [x] App debug Bridge receiver 不返回本地轻量地址样例，避免本地数据参与发货链路。
- [x] 新增地址页通过 `/api/bff/address/regions` -> Java `/p/area/listByPid` 获取省市区；接口无数据时不展示本地兜底选项。
- [x] 编辑地址页回显省市区时按真实区域 ID 级联加载 options，不合成本地选项。
- [x] 定位按钮预留 `address.chooseLocation`，App 未接入时有页面提示和 console 调试日志。
- [x] 本地事实源和对接文档已更新。
- [ ] 飞书知识库同步：当前被 `lark-cli` user 授权缺失和 Bot 页面权限不足阻塞，需恢复权限后补同步。

## 验证记录

验证记录：`hybird-meumall/.ai/test-reports/2026-06-24-address-bridge.md`

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/lib/bridge/protocol-bridge.test.ts src/features/mine-secondary/address-hybrid-api.test.ts src/features/mine-secondary/address-pages.test.tsx src/features/product/product-detail.test.tsx src/features/product/product-real-flow.test.tsx src/features/product/order-confirm.test.tsx
pnpm exec vitest run src/features/mine-secondary/address-region-hydration.test.ts src/features/mine-secondary/address-real-service.test.ts src/features/mine-secondary/address-pages.test.tsx src/features/mine-secondary/address-hybrid-api.test.ts
pnpm typecheck
pnpm lint
pnpm test
pnpm run build
pnpm run ai:check-docs-sync --strict
```

## 风险和后续

- 本轮只改 H5，不以 iOS 构建/测试作为验收项。
- App 正式地址数据源仍需后续接入真实 Bridge 实现；H5 不保留本地地址样例。
- 地址页和省市区均不保留本地轻量业务数据；Bridge/BFF/Java 未返回时展示空态、错误提示或空选项。
- `address.chooseLocation` 仅预留 Bridge 协议和 H5 日志，App 后续提供真实定位/地图选点。
- 飞书知识库同步阻塞：
  - `lark-cli docs +update --as user` 返回 `token_missing`，需要重新执行 `lark-cli auth login` 授权用户身份。
  - `lark-cli docs +update --as bot` 返回文档 `4030004` 无编辑权限，需要给 Bot 身份授予目标知识库页面编辑权限。
  - 恢复权限后，从 `.ai-workspace/product/page-inventory.md` 同步页面清单页，从 `.ai-workspace/integration-briefs/BRIEF-2026-0605-h5-native-route-map.md` 同步 Bridge / 路由对接说明页。
