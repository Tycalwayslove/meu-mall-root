# API 契约：H5 我的页与权益中心真实接口

## 基本信息

- 契约编号：API-2026-0627-002
- 状态：implemented，待联调验证
- 提供方：Java 后端
- 消费方：`hybird-meumall`
- 适用环境：dev / test / prod
- Apifox 项目：`4403987`，branch `main`
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-002-h5-mine-benefits-real-api.md`
- 关联对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0627-002-h5-mine-benefits-real-api.md`

## 背景

`/mine` 和 `/promotion/benefits` 需要从 H5 mock 切换到真实个人中心和达人等级数据。

## 接口定义

### 个人中心页数据

- Method：`GET`
- Java Path：`/p/app/profile/summary`
- H5 BFF Path：`/api/bff/mine/summary`
- 鉴权：用户登录态；H5 BFF 使用 `mallToken` 作为 Java `Authorization`
- 缓存策略：no-store

### 查询我的达人等级

- Method：`GET`
- Java Path：`/p/daren/level/myLevel`
- H5 使用：`/api/bff/mine/summary`、`/api/bff/promotion/benefits`
- 备注：Apifox description 中仍写旧 path `/p/distribution/level/myLevel`，H5 以 OpenAPI 当前 path 为准。

### 达人等级列表

- Method：`GET`
- Java Path：`/p/daren/level/list`
- H5 BFF Path：`/api/bff/promotion/benefits`
- 备注：Apifox description 中仍写旧 path `/p/distribution/level/list`，H5 以 OpenAPI 当前 path 为准。

## 字段说明

### `AppProfileSummaryDto`

| 字段 | 类型 | 说明 | H5 映射 |
| --- | --- | --- | --- |
| `walletBalance` | number | 钱包余额，单位元 | 我的页“钱包余额” |
| `yearSavedAmount` | number | 今年已省，单位元 | 我的页“今年已省” |
| `couponCount` | integer | 可用优惠券数量 | 我的页“优惠券” |
| `banners` | array | 个人中心轮播图 | 我的页 banner，取 `seq` 最小的一张 |

### `DistributionMyLevelDto`

| 字段 | 类型 | 说明 | H5 映射 |
| --- | --- | --- | --- |
| `currentLevelValue` | integer | 当前档位 1-5 | `v1-v5` |
| `currentLevelName` | string | 当前等级名称 | 我的页等级、权益中心当前等级 |
| `commissionMultiplier` | number | 佣金倍率 | 权益中心佣金文案 |
| `displayBenefits` | array | 当前等级展示权益 | 权益中心当前等级权益 |
| `darenBenefitItems` | array[string] | 当前等级达人权益展示条目 | 权益中心会员特权 |
| `nextUpgradeGmv` | number | 下一档升级所需 GMV | 权益中心进度 |
| `nextUpgradeOrderCount` | integer | 下一档升级所需销量 | 权益中心进度 |
| `gapGmv` | number | 距下一档还差 GMV | 权益中心进度 |
| `gapOrderCount` | integer | 距下一档还差订单量 | 权益中心进度 |

### `DistributionLevelAppDto`

| 字段 | 类型 | 说明 | H5 映射 |
| --- | --- | --- | --- |
| `levelValue` | integer | 档位 1-5 | 权益中心可切换等级 |
| `levelName` | string | 等级名称 | 权益中心标题 |
| `upgradeGmv` | number | 升级所需 GMV | 锁定提示 |
| `upgradeOrderCount` | integer | 升级所需销量 | 锁定提示 |
| `commissionMultiplier` | number | 佣金倍率 | 佣金文案 |
| `benefitText` | string | 等级权益展示文案 | 达人定位 |
| `displayBenefits` | array | 展示权益列表 | 专属特权 |
| `darenBenefitItems` | array[string] | 达人权益展示条目 | 会员特权 |

## 错误码

| code | HTTP 状态 | 说明 | H5 处理方式 |
| --- | --- | --- | --- |
| `A00004` | 401 | 未授权 / token 无效 | 展示错误态，不回退 mock |
| `A00005` | 5xx | Java 服务异常 | 展示错误态，不回退 mock |
| `TOKEN_MISSING` | 401 | H5 未读取到 `mallToken` | 展示错误态，等待 App 登录态 |
| `PARSE_ERROR` | 502 | `data` 缺失、等级列表为空或不可解析 | 展示错误态 |

## H5 兜底策略

- 数值字段为空：展示 0。
- banner 为空：不展示 banner，不使用本地运营 mock banner。
- 当前等级为空：降级为 V1 视觉，但权益和统计不从 mock 补业务数据。
- 等级列表为空：展示错误态。
- token 缺失、鉴权失败、接口失败：展示错误态，不展示 mock 我的页或 mock 权益。

## 测试方式

- H5 验证：`/mine`、`/promotion/benefits`、`/api/bff/mine/summary`、`/api/bff/promotion/benefits`。
- 契约测试：`pnpm exec vitest run src/features/mine/mine-real-api.test.tsx src/features/promotion/promotion-service.test.ts`。
- 联调环境：Java test `https://test.aigcpop.com/mini_h5`。

## 回滚方式

H5 发布异常时回滚 active manifest 到上一版 H5；代码层不在真实接口失败时自动回退 mock，避免联调误判。
