# API 契约：H5 收货地址模块

## 基本信息

- 契约编号：API-2026-0612-015
- 状态：ready
- 提供方：App Native Bridge，Java 后端，H5 BFF
- 消费方：`hybird-meumall`
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0612-015-h5-address-module.md`

## 范围

H5 收货地址模块优先通过 App Native Bridge 获取和管理地址；Bridge 不可用或老版本 App 不支持时，通过 H5 BFF 消费旧 Java 地址接口。覆盖地址列表、详情、新增、编辑、设默认、删除，以及定位选点 Bridge 预留。

不包含：地图选点真实 App 实现。

## App Bridge 接口

所有地址 Bridge 均使用统一 RPC 信封：

```json
{
  "module": "rpc",
  "action": "address.getList",
  "callbackId": "cb_xxx"
}
```

| action | payload | resolve data | 说明 |
| --- | --- | --- | --- |
| `address.getDefault` | 无 | `{ "address": Address \| null }` | 获取当前默认收货地址。 |
| `address.getList` | 无 | `{ "addresses": Address[] }` | 获取地址列表。 |
| `address.getInfo` | `{ "addrId": "3001" }` | `{ "address": Address \| null }` | 获取地址详情。 |
| `address.save` | `Address` | `{ "addrId": "3001", "message": "地址已保存" }` | 新增或编辑地址。 |
| `address.setDefault` | `{ "addrId": "3001" }` | `{ "message": "默认地址已更新" }` | 设置默认地址。 |
| `address.delete` | `{ "addrId": "3001" }` | `{ "message": "地址已删除" }` | 删除地址。 |
| `address.chooseLocation` | 无 | `{ "location": AddressLocation \| null }` | 定位选点预留；当前 H5 只发起 Bridge 并输出调试日志，正式定位由 App 后续提供。 |

H5 使用口径：

- 商品详情进入后先调用 `address.getDefault`，有地址时把 `addrId` 传给 `/api/bff/product-detail` 刷新配送相关状态。
- 订单确认页 URL 未带 `addressId` 时先调用 `address.getDefault`，再把解析到的 `addrId` 传给 `/api/bff/order-confirm`。
- 地址管理页所有列表/详情/保存/删除/设默认操作优先走 `address.*`；Bridge 不可用或返回 unsupported 时回退 H5 BFF。
- 新增/编辑地址页的省市区只通过 H5 BFF `/api/bff/address/regions` 消费 Java `/p/area/listByPid`；接口未返回数据时不展示本地选项、不用本地轻量数据兜底。
- 定位按钮调用 `address.chooseLocation`，H5 console 输出 `[MeuMall][address-location]` 调试日志；App 未接入时页面提示“定位能力等待 App Bridge 接入”，不伪造定位结果。
- 交易 BFF 仍会用 Java `/p/address/addrInfo/{addrId}` 做服务端校验，不信任前端地址快照。

## H5 BFF 兜底接口

| Method | Path | 说明 |
| --- | --- | --- |
| GET | `/api/bff/address/list` | 获取当前用户地址列表。 |
| GET | `/api/bff/address/info?addrId=<addrId>` | 获取单个地址详情。 |
| POST | `/api/bff/address/save` | 新增地址。 |
| PUT | `/api/bff/address/save` | 编辑地址。 |
| PUT | `/api/bff/address/default` | 设置默认地址，body 带 `addrId`。 |
| DELETE | `/api/bff/address/delete` | 删除地址，body 带 `addrId`。 |
| GET | `/api/bff/address/regions?parentId=<areaId>` | 获取省/市/区级联数据；无 `parentId` 时获取省份。 |

H5 BFF 鉴权：服务端从 Cookie 读取 `mallToken`，转为 Java `Authorization: <mallToken>`；Java / mall 后端出站请求统一带 `source: 1`。BFF 是 Bridge 不可用时的兜底和交易校验层，不是 App Hybrid 的首选地址来源。

## Java 后端依赖

| Method | Path | H5 使用口径 |
| --- | --- | --- |
| GET | `/p/address/list?isDefaultFirst=false` | 地址列表。 |
| GET | `/p/address/addrInfo/{addrId}` | 地址详情；`addrId=0` 在交易链路中解析默认地址。 |
| POST | `/p/address/addAddr` | 新增地址。 |
| PUT | `/p/address/updateAddr` | 编辑地址。 |
| PUT | `/p/address/defaultAddr/{addrId}` | 设置默认地址。 |
| DELETE | `/p/address/deleteAddr/{addrId}` | 删除非默认地址。 |
| GET | `/p/area/listByPid?level=1` | 获取省份。 |
| GET | `/p/area/listByPid?pid={areaId}` | 获取指定省/市下级区域。 |

## 地址字段

```ts
type JavaAddress = {
  addr?: string;
  addrId?: number | string;
  area?: string;
  areaId?: number | string;
  city?: string;
  cityId?: number | string;
  commonAddr?: 0 | 1 | "0" | "1" | boolean;
  lat?: number | string;
  lng?: number | string;
  mobile?: string;
  province?: string;
  provinceId?: number | string;
  receiver?: string;
};
```

定位预留返回：

```ts
type AddressLocation = {
  addr?: string;
  area?: string;
  areaId?: number | string;
  city?: string;
  cityId?: number | string;
  lat?: number | string;
  lng?: number | string;
  name?: string;
  province?: string;
  provinceId?: number | string;
};
```

新增/编辑保存 body 由 H5 BFF 归一化为旧 uni-app 字段：`receiver`、`mobile`、`addr`、`province`、`provinceId`、`city`、`cityId`、`area`、`areaId`、`commonAddr`、`lat`、`lng`、`userType=0`。

## 兜底

- 无 token：H5 BFF 返回 401，地址页展示空态或错误提示，不展示本地地址预览数据。
- Bridge 不可用或 unsupported：H5 自动回退 BFF。
- `address.chooseLocation` 不回退 BFF；App 未接入时只展示提示并保留手动省市区选择。
- 保存字段缺失：H5 BFF 返回 502/解析错误，页面展示错误文案。
- 地址列表失败：页面展示空态或错误提示，不使用本地 mock 地址兜底。
- 省市区接口失败或返回空：对应下拉不展示本地选项，保存时必须有 Java 区域接口返回的 `provinceId`、`cityId`、`areaId`。
- 删除和设默认失败：停留在地址列表并展示错误。

## 验证

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/mine-secondary/address-real-service.test.ts src/features/mine-secondary/address-pages.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
```
