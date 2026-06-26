# TASK-2026-0612-015 H5 收货地址模块

## 状态

verified

## 目标

为 `hybird-meumall` 补齐订单确认链路缺失的收货地址模块，完成 H5 地址列表、地址新增/编辑页、订单确认页地址入口，并接入旧 Java 地址接口，使当前购买流程具备选择、补充和使用收货地址的链路。

## 背景

商品详情和订单确认已接入普通商品、快递、SKU 和普通订单创建，但订单确认页此前只有静态地址卡，缺少地址列表、地址新增/编辑页面，也没有把选中地址 ID 传入订单确认和下单 BFF。

旧 uni-app 参考页面：

- `/Users/mac/company_code/mall4uni-bbc/src/package-user/pages/delivery-address/delivery-address.vue`
- `/Users/mac/company_code/mall4uni-bbc/src/package-prod/pages/edit-address/edit-address.vue`

## 范围

包含：

- 新增 H5 路由 `/address`，用于收货地址列表和订单确认选择地址。
- 新增 H5 路由 `/address/edit`，用于新增/编辑收货地址表单。
- 复制旧项目地址空态图和定位图标到当前 H5 `public/assets/address/`，并注册到 `localAssetUrl()`。
- 我的页“地址管理”入口从占位改为 `/address`。
- 订单确认页地址卡改为可点击入口，跳转 `/address?select=1` 并保留商品、SKU、数量和地址参数。
- `/order-confirm`、`/api/bff/order-confirm`、`/api/bff/order-submit` 支持传递 `addressId/addrId`，交易 BFF 已使用 Java `/p/address/addrInfo/{addrId}` 解析默认/选中地址。
- 新增地址管理 BFF：`/api/bff/address/list`、`/api/bff/address/info`、`/api/bff/address/save`、`/api/bff/address/default`、`/api/bff/address/delete`。
- 地址列表、地址详情、新增、编辑、设默认和删除接入旧 Java 地址接口。
- 测试覆盖地址列表、空态、新增地址页和订单确认地址入口。

契约：

- `.ai-workspace/contracts/api/h5-address-module-contract.md`

不包含：

- 省市区联动真实行政区数据。
- 腾讯地图选点和定位 Bridge。

## 当前实现口径

- 地址页面先用 H5 本地 mock 数据兜底，进入页面后通过 BFF 同步真实 Java 地址数据；无 token 或接口失败时保留本地预览，避免页面白屏。
- 订单确认页会把 `selectedAddressId` 传给 H5 BFF；真实 BFF 会先调 Java `/p/address/addrInfo/{addrId}`，未传时用 `0` 获取默认地址，再用解析后的真实 `addrId` 请求商品详情、订单确认和订单提交。
- 无法解析收货地址时，订单确认页展示未选地址并禁用提交；订单提交 BFF 返回 409，不创建订单。
- 地址列表“使用”会保留 `productId`、`skuId`、`quantity` 并回到 `/order-confirm?addressId=<addrId>`。

## 验收标准

- [x] `/address` 可展示地址列表、默认地址、使用、编辑、删除和新增入口。
- [x] `/address?state=empty` 展示旧项目复制来的地址空态图。
- [x] `/address/edit` 展示收货人、手机号、所在地区、详细地址、定位、设为默认地址和保存按钮。
- [x] `/order-confirm` 地址卡可点击进入 `/address?select=1`。
- [x] 订单确认和订单提交 BFF 支持 `addrId` 传递，并通过 `/p/address/addrInfo/{addrId}` 解析地址。
- [x] 地址列表、详情、新增、编辑、设默认和删除通过 H5 BFF 接入 Java 地址接口。
- [x] 本地资产不输出裸 `/assets/...` 路径。

## 验证记录

验证记录：`hybird-meumall/.ai/test-reports/2026-06-12-address-module.md`

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/mine-secondary/address-pages.test.tsx
pnpm exec vitest run src/features/mine-secondary/address-real-service.test.ts src/features/mine-secondary/address-pages.test.tsx
pnpm exec vitest run src/features/mine-secondary/address-pages.test.tsx src/features/mine-secondary/mine-secondary-pages.test.tsx src/features/product/order-confirm.test.tsx src/features/product/product-real-flow.test.tsx
pnpm typecheck
pnpm lint
pnpm run build
```

结果：

- 地址模块测试：1 file / 4 tests 通过。
- 地址真实服务和页面测试：2 files / 6 tests 通过。
- 地址、个人中心二级页、订单确认、商品真实链路回归：4 files / 25 tests 通过。
- 全量测试：47 files / 239 tests 通过。
- TypeScript：通过。
- ESLint：0 errors，4 warnings；warning 均为 promotion 模块既有 `<img>` 规则提示。
- Next build：通过，路由表包含 `/address`、`/address/edit` 和 `/api/bff/address/*`。

## 飞书同步

- 已同步页面清单到公司知识库：<https://v05ctaei9gn.feishu.cn/wiki/WgaqwTRRUitnRNkCtNPcOcDnnre>
- 同步结果：success。
- 飞书 revision：12。
- 同步时间：2026-06-12 18:01。

## 后续

- 省市区联动接真实地址数据或后端行政区接口。
- 如需要地图选点，另行定义 H5 与原生定位/地图 Bridge 或 H5 腾讯地图回跳策略。
