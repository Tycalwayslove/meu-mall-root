# H5 版本接口迁移 Java 交接文档

## 说明

本文只给 Java 同学看，目标是把当前 H5 版本发布相关能力迁移到 Java + MySQL。

不迁移首页配置接口：

- 不需要实现 `/api/home/configs`
- 不需要实现 `/api/h5/home/config/active`
- 不需要建 `h5_home_page_config`
- 首页配置后续由 Java 端自行设计开发

当前测试环境：

```text
https://hybird.aigcpop.com
```

当前数据来源：

```text
GET https://hybird.aigcpop.com/api/releases?environment=prod
GET https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod
```

数据抓取时间：2026-06-15 14:28 CST

## 需要 Java 实现的接口

### 1. 获取当前生效 H5 版本

```http
GET /api/h5/manifest/active?environment=prod
```

用在哪里：

| 调用方 | 用途 |
| --- | --- |
| App | 启动或刷新时读取当前 H5 版本、basePath 和路由。 |
| H5 | SSR / 调试时读取当前 active manifest。 |
| 发布脚本 | 读取当前 active 版本，作为新版本的 rollbackVersion。 |

请求参数：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `environment` | string | 否 | `prod` | 环境。当前只有 `prod`。 |

响应要求：

- 直接返回 manifest JSON。
- 不要包一层 `{ code, data }`。
- 没有 active 版本时返回 404。
- Header 必须包含：

```http
Cache-Control: no-cache, max-age=0, must-revalidate
```

当前 active 响应关键字段：

```json
{
  "schemaVersion": "1.0.0",
  "appId": "hybrid-h5",
  "configVersion": "config-v1.0.14",
  "environment": "prod",
  "stableVersion": "v1.0.14",
  "rollbackVersion": "v1.0.13",
  "blacklistVersions": [],
  "grayRules": {
    "percentage": 0,
    "salt": "prod",
    "includeUserIds": [],
    "excludeUserIds": []
  },
  "assets": {
    "serviceBaseUrl": "https://hybird.aigcpop.com",
    "basePath": "/h5-v/v1.0.14",
    "staticAssetPath": "/_next/static",
    "healthCheckPath": "/api/health"
  },
  "routes": {
    "/": {
      "delivery": "remote",
      "path": "/",
      "minAppVersion": "0.0.0",
      "requiredBridgeMethods": []
    }
  },
  "remoteConfig": {
    "appConfigUrl": "/config/app-config.json"
  }
}
```

`routes` 是对象，不是数组。示例：

```json
{
  "/": {
    "delivery": "remote",
    "path": "/",
    "minAppVersion": "0.0.0",
    "requiredBridgeMethods": []
  }
}
```

### 2. 查询 H5 版本列表

```http
GET /api/releases?environment=prod
```

用在哪里：

| 调用方 | 用途 |
| --- | --- |
| 管理后台 | 展示 H5 版本列表、当前 active、候选版本。 |
| 迁移脚本 | 拉取当前测试环境已有版本数据。 |

请求参数：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `environment` | string | 否 | 无 | 当前使用 `prod`。 |

响应字段：

```ts
type ReleaseItem = {
  id: string;
  version: string;
  environment: string;
  status: "candidate" | "active" | "failed" | "rolled_back";
  manifest: Manifest;
  gray_percentage: number;
  source: string | null;
  build_meta: Record<string, unknown> | null;
  created_by: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
  published_at: string | null;
};
```

排序：当前按 `updated_at desc` 返回。

### 3. 注册一个 H5 候选版本

```http
POST /api/releases
```

用在哪里：

| 调用方 | 用途 |
| --- | --- |
| CI / 发布脚本 | H5 镜像和版本路径部署完成后，注册 candidate release。 |

请求字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `version` | string | 是 | H5 版本，如 `v1.0.15`。 |
| `environment` | string | 是 | 当前为 `prod`。 |
| `serviceBaseUrl` | string | 是 | H5 域名，如 `https://hybird.aigcpop.com`。 |
| `basePath` | string | 是 | 版本路径，如 `/h5-v/v1.0.15`。 |
| `healthCheckPath` | string | 否 | 默认 `/api/health`。 |
| `rollbackVersion` | string | 是 | 回滚目标版本。通常取当前 active stableVersion。 |
| `rolloutPercentage` | number | 否 | 灰度比例，0-100，默认 0。 |
| `routes` | string[] | 否 | H5 路由列表。服务端保存时转成 routes 对象。 |
| `source` | string | 否 | 来源，如 `hybird-ci`。 |
| `buildMeta` | object | 否 | 构建信息。 |
| `createdBy` | string | 否 | 创建人。 |
| `notes` | string | 否 | 备注。 |

请求示例：

```json
{
  "version": "v1.0.15",
  "environment": "prod",
  "serviceBaseUrl": "https://hybird.aigcpop.com",
  "basePath": "/h5-v/v1.0.15",
  "healthCheckPath": "/api/health",
  "rollbackVersion": "v1.0.14",
  "rolloutPercentage": 0,
  "routes": ["/", "/promotion", "/mine", "/category"],
  "source": "hybird-ci",
  "buildMeta": {
    "renderMode": "ssr",
    "runtime": "next-standalone",
    "gitCommit": "xxxx",
    "gitRef": "h5/v1.0.15",
    "gitTag": "h5/v1.0.15",
    "packageVersion": "1.0.15",
    "dockerImage": "meu-mall/h5:v1.0.15",
    "container": "meu-mall-h5-v1.0.15"
  },
  "createdBy": "ci"
}
```

保存规则：

- 新记录状态为 `candidate`。
- `manifest.stableVersion = version`。
- `manifest.rollbackVersion = rollbackVersion`。
- `manifest.assets.serviceBaseUrl = serviceBaseUrl`。
- `manifest.assets.basePath = basePath`。
- `manifest.grayRules.percentage = rolloutPercentage`。
- `routes` 数组要转成 manifest 的 routes 对象。

### 4. 提升版本为 active

```http
POST /api/releases/{id}/promote
```

用在哪里：

| 调用方 | 用途 |
| --- | --- |
| 管理后台 | 将某个 candidate 切为当前 active。 |
| 发布脚本 | 可选，注册后自动提升。 |

路径参数：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | release id。 |

行为：

- 把目标 release 状态改为 `active`。
- 把同 environment 下旧 active 改为 `candidate`。
- 更新目标 release 的 `published_at` 和 `updated_at`。
- 必须用事务保证同一 environment 只有一个 active。

### 5. 设置灰度

```http
POST /api/releases/{id}/gray
```

用在哪里：

| 调用方 | 用途 |
| --- | --- |
| 管理后台 | 用某个 candidate 作为灰度版本。 |

请求字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `percentage` | number | 是 | 灰度比例，0-100。 |

行为：

- `{id}` 是 candidate release id。
- 找到同 environment 当前 active。
- 更新 active manifest：
  - `grayVersion = candidate.version`
  - `grayRules.percentage = percentage`
- 当前接口返回被更新后的 active release。

### 6. 回滚

```http
POST /api/releases/{id}/rollback
```

用在哪里：

| 调用方 | 用途 |
| --- | --- |
| 管理后台 | 当前 active 异常时回滚。 |

请求字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `targetVersion` | string | 否 | 指定回滚目标。不传时使用异常版本 manifest.rollbackVersion。 |
| `reason` | string | 否 | 回滚原因。 |

行为：

- `{id}` 是异常 release id。
- 目标版本为 `targetVersion` 或异常 release 的 `rollbackVersion`。
- 找到目标 release。
- 异常 release 状态改为 `rolled_back`。
- 目标 release 状态改为 `active`。
- 目标 manifest 清掉 `grayVersion`。
- 目标 manifest 的 `grayRules.percentage` 改为 0。
- 把异常版本加入目标 manifest 的 `blacklistVersions`。

## Manifest 字段说明

```ts
type Manifest = {
  schemaVersion: string;
  appId: string;
  configVersion: string;
  environment: string;
  stableVersion: string;
  grayVersion?: string;
  rollbackVersion: string;
  blacklistVersions?: string[];
  grayRules: {
    percentage: number;
    salt: string;
    includeUserIds: string[];
    excludeUserIds: string[];
  };
  assets: {
    serviceBaseUrl: string;
    basePath: string;
    staticAssetPath: string;
    healthCheckPath: string;
    publicAssetBaseUrl?: string;
  };
  routes: Record<string, {
    delivery: "remote";
    path: string;
    minAppVersion: string;
    requiredBridgeMethods: string[];
  }>;
  remoteConfig: {
    appConfigUrl: string;
  };
};
```

## MySQL 表结构建议

只需要这一张表承接 H5 版本发布主链路。

```sql
CREATE TABLE h5_manifest_release (
  id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'release id，建议使用 UUID',
  name VARCHAR(255) NOT NULL COMMENT '展示名称，如 H5 release v1.0.14',
  environment VARCHAR(32) NOT NULL COMMENT '环境，如 prod',
  status VARCHAR(32) NOT NULL COMMENT 'candidate / active / failed / rolled_back',
  version VARCHAR(64) NOT NULL COMMENT 'H5 版本，如 v1.0.14',
  manifest_json JSON NOT NULL COMMENT '完整 manifest JSON',
  source VARCHAR(128) NULL COMMENT '来源，如 hybird-ci',
  build_meta_json JSON NULL COMMENT '构建元数据',
  created_by VARCHAR(128) NULL COMMENT '创建人',
  notes TEXT NULL COMMENT '备注',
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  active_environment VARCHAR(32)
    GENERATED ALWAYS AS (
      CASE WHEN status = 'active' THEN environment ELSE NULL END
    ) STORED,
  UNIQUE KEY uk_h5_manifest_active_environment (active_environment),
  KEY idx_h5_manifest_env_status_updated (environment, status, updated_at),
  KEY idx_h5_manifest_env_version (environment, version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='H5 版本 release / active manifest 表';
```

说明：

- `manifest_json` 存完整 manifest。
- `build_meta_json` 存完整构建信息。
- `active_environment` 用于保证同一个 environment 只有一个 active。MySQL 允许多个 NULL，所以 candidate 不受影响。
- 如果你们不想用生成列，也可以在代码事务里保证同环境 active 唯一。

## 当前测试环境表数据

当前共 19 条记录：

- active：1 条，`v1.0.14`
- candidate：18 条
- 当前 active 回滚目标：`v1.0.13`
- 完整数据请以 `GET /api/releases?environment=prod` 返回为准，导入时把每条的 `manifest` 存到 `manifest_json`，把 `build_meta` 存到 `build_meta_json`。

| id | version | status | stableVersion | rollbackVersion | serviceBaseUrl | basePath | routeCount | gitRef | packageVersion | published_at |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| `9873301d-f09d-4ab3-a2ab-efaacbd713e4` | `v1.0.13` | candidate | `v1.0.13` | `v1.0.12` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.13` | 22 | `h5/v1.0.13` | `1.0.13` | `2026-06-12T07:39:19.179487+00:00` |
| `a89d7267-86f0-403e-9622-9b1f908f27f6` | `v1.0.14` | active | `v1.0.14` | `v1.0.13` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.14` | 22 | `h5/v1.0.14` | `1.0.14` | `2026-06-12T08:28:23.748306+00:00` |
| `32bdec95-a5ec-4e96-9c16-5d8474e910f5` | `v1.0.12` | candidate | `v1.0.12` | `v1.0.11` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.12` | 22 | `h5/v1.0.12` | `1.0.12` | `2026-06-10T07:55:29.421054+00:00` |
| `21f40cdf-6e6e-4a96-a261-c0a9e9a6d3e5` | `v1.0.11` | candidate | `v1.0.11` | `v1.0.10` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.11` | 22 | `h5/v1.0.11` | `1.0.11` | `2026-06-09T03:33:49.086036+00:00` |
| `934c1db5-867d-4fcd-8fe1-cd7ca66d3531` | `v1.0.10` | candidate | `v1.0.10` | `v1.0.9` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.10` | 23 | `h5/v1.0.10` | `1.0.10` | `2026-06-08T09:30:12.619863+00:00` |
| `ab0b364b-3d55-4c21-92a4-fe9137ea0df1` | `v1.0.9` | candidate | `v1.0.9` | `v1.0.8` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.9` | 23 | `h5/v1.0.9` | `1.0.9` | `2026-06-05T06:04:48.727020+00:00` |
| `3a1f8db2-cc3d-4a24-aaf1-b964e9d332a6` | `v1.0.8` | candidate | `v1.0.8` | `v1.0.7` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.8` | 23 | `h5/v1.0.8` | `1.0.8` | `2026-06-05T04:21:51.909071+00:00` |
| `3ea7fea6-fa86-40e1-9930-9ea15a476d76` | `v1.0.7` | candidate | `v1.0.7` | `v1.0.6` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.7` | 23 | `h5/v1.0.7` | `1.0.7` | `2026-06-04T11:22:08.914126+00:00` |
| `f9cd020d-3386-45a8-9cf5-53d27b698346` | `v1.0.6` | candidate | `v1.0.6` | `v1.0.5` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.6` | 23 | `h5/v1.0.6` | `1.0.6` | `2026-06-04T06:01:03.620798+00:00` |
| `ce2d6dc0-51df-41c9-a0e6-b63e34384620` | `v1.0.5` | candidate | `v1.0.5` | `v1.0.4` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.5` | 19 | `h5/v1.0.5` | `1.0.5` | `2026-06-04T02:50:17.155509+00:00` |
| `60381a7a-ab95-4344-b2ce-086092ce14ca` | `v1.0.4` | candidate | `v1.0.4` | `v1.0.3` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.4` | 19 | `h5/v1.0.4` | `1.0.4` | `2026-06-03T09:35:43.052931+00:00` |
| `f7dbe687-6875-46d8-817b-c942cf9db190` | `v1.0.3` | candidate | `v1.0.3` | `v1.0.2` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.3` | 19 | `h5/v1.0.3` | `1.0.3` | `2026-06-03T07:56:20.640661+00:00` |
| `81c2b308-fa13-4f61-919f-309652861e13` | `v1.0.2` | candidate | `v1.0.2` | `v1.0.1` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.2` | 19 | `h5/v1.0.2` | `1.0.2` | `2026-06-03T06:34:56.485479+00:00` |
| `89edd567-fa19-42f9-bc01-9e8f15120e1c` | `v1.0.1` | candidate | `v1.0.1` | `v1.0.0` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.1` | 19 | `h5/v1.0.1` | `1.0.1` | `2026-06-03T06:32:56.328042+00:00` |
| `b1d5e148-c8fd-47ab-8a1d-b36d525917a8` | `v1.0.0` | candidate | `v1.0.0` | `2026.06.03-003` | `https://hybird.aigcpop.com` | `/h5-v/v1.0.0` | 19 | `h5/v1.0.0` | `1.0.0` | `2026-06-03T06:30:36.231326+00:00` |
| `2770a592-ef4e-40da-903e-b2ffc4538bbd` | `2026.06.03-003` | candidate | `2026.06.03-003` | `2026.06.03-003` | `https://hybird.aigcpop.com` | `/h5-v/2026.06.03-003` | 19 |  |  | `2026-06-03T06:04:41.532484+00:00` |
| `84f63d0e-b715-4f39-b7c2-44e48caedd72` | `2026.06.03-002` | candidate | `2026.06.03-002` | `2026.06.03-001` | `https://hybird.aigcpop.com` | `/h5-v/2026.06.03-002` | 19 |  |  | `2026-06-03T05:51:58.277886+00:00` |
| `39475c30-81bd-485e-9e7a-ec29c73facb4` | `2026.06.03-001` | candidate | `2026.06.03-001` | `2026.05.15-001` | `https://hybird.aigcpop.com` |  | 19 |  |  | `2026-06-03T04:13:34.763263+00:00` |
| `42ae56d7-60af-497e-978a-cfc8e7beebea` | `2026.05.15-001` | candidate | `2026.05.15-001` | `2026.05.15-001` | `http://127.0.0.1:3109` | `/hybird` | 4 |  |  | `2026-06-02T07:54:00.979868+00:00` |

## 当前 active 版本路由

`v1.0.14` 当前有 22 个 route：

```json
[
  "/",
  "/category",
  "/consult",
  "/favorites/products",
  "/favorites/shops",
  "/messages",
  "/mine",
  "/order-confirm",
  "/orders",
  "/product/p-1001",
  "/promotion",
  "/promotion/activities",
  "/promotion/benefits",
  "/promotion/card",
  "/promotion/commission",
  "/promotion/level",
  "/promotion/products",
  "/promotion/rank-center",
  "/promotion/ranking",
  "/promotion/ranking/amount",
  "/promotion/ranking/sales",
  "/seckill"
]
```

## Java 迁移注意事项

1. active manifest 接口必须返回 manifest 本体，不包 wrapper。
2. active manifest 必须 no-cache。
3. 同一个 environment 只能有一个 active。
4. 发布时间字段建议用 `DATETIME(6)`，保留微秒。
5. `manifest_json` 和 `build_meta_json` 建议用 MySQL JSON。
6. 当前所有新版本 basePath 都是 `/h5-v/<version>`。
7. 最早期 `2026.05.15-001` 是旧测试记录，里面有 `/cart`、`/profile`，不要拿它当当前 active 路由事实。
8. Java 不需要实现首页配置接口，首页配置另做。
