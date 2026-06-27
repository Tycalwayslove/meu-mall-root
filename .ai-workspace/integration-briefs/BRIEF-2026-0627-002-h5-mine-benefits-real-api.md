# 对接说明：我的页与权益中心真实接口联调

## 基本信息

- 编号：BRIEF-2026-0627-002
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-002-h5-mine-benefits-real-api.md`
- 状态：implemented，待 App token 联调验证
- H5 负责人：待补充
- 后端负责人：待确认
- 原生 App 负责人：待确认
- 管理后台负责人：无
- 目标联调时间：2026-06-27 起
- 目标上线环境：测试环境

## 需求背景

我的页和权益中心此前为 H5 静态高保真 mock。后端已在 Apifox 项目 `4403987` main 分支发布个人中心页数据、查询我的达人等级和达人等级列表接口，H5 需要切到真实接口进行联调。

## H5 侧目标

`/mine` 展示真实钱包余额、今年已省、可用优惠券和当前达人等级；点击权益中心进入 `/promotion/benefits?level=<当前等级>`。权益中心展示我的当前等级，并可切换查看等级列表中的不同等级权益。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 我的 | `/mine` | H5 | Tab 根 WebView，数据来自 Java `/p/app/profile/summary` 和 `/p/daren/level/myLevel` |
| 权益中心 | `/promotion/benefits` | H5 | 新 H5 WebView，数据来自 Java `/p/daren/level/myLevel` 和 `/p/daren/level/list` |

## 数据流

```text
App WebView 写入 mallToken Cookie
  -> H5 SSR /mine
  -> H5 BFF /api/bff/mine/summary
  -> Java /p/app/profile/summary + /p/daren/level/myLevel
  -> 点击权益中心
  -> H5 SSR /promotion/benefits
  -> Java /p/daren/level/myLevel + /p/daren/level/list
  -> H5 权益中心切换展示
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 个人中心页数据 | 已有 | `GET /p/app/profile/summary` | `.ai-workspace/contracts/api/h5-mine-benefits-real-api-contract.md` |
| 查询我的达人等级 | 已有 | `GET /p/daren/level/myLevel` | 同上 |
| 达人等级列表 | 已有 | `GET /p/daren/level/list` | 同上 |
| 鉴权 | 是 | H5 BFF 用 `mallToken` 转 `Authorization` 请求 Java | `h5-bff-http-auth-contract.md` |
| 缓存策略 | 是 | 用户私有数据 no-store；等级规则后续可由后端确认短缓存 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本次不新增 Bridge | 无 |
| 原生页面跳转 | 是 | `/mine` 为 Tab 根 WebView，权益中心新开 H5 WebView | 既有路由契约 |
| 登录态 | 是 | App 需写入有效 `mallToken` Cookie | `h5-bff-http-auth-contract.md` |

## H5 侧责任

- [x] BFF 调 Java 个人中心概览。
- [x] BFF 调 Java 我的等级和等级列表。
- [x] `/mine` 成功态和错误态。
- [x] `/promotion/benefits` 多等级切换。
- [x] 联调阶段不使用 mock 业务数据兜底。

## 对方责任

### 后端

- [ ] 提供测试环境有效数据。
- [ ] 确认 Apifox description 里的旧 path 与 OpenAPI 当前 path 差异。
- [ ] 确认等级权益字段展示口径。

### 原生 App

- [ ] 打开 `/mine` 前写入 `mallToken` Cookie。
- [ ] 确认权益中心新开 H5 WebView 行为正常。

## Mock 和联调方式

- Mock 数据位置：旧 `mine/mock/data.ts` 与 `promotion/mock/benefits.ts` 保留给历史测试，不作为本次联调兜底。
- 测试接口环境：Java test。
- 联调步骤：打开 `/mine`，点击权益中心，左右切换等级并观察真实权益数据。
- 联调阶段是否已移除页面 mock 兜底：是。

## 真实接口渲染规则

- 接口成功后只渲染 Java 返回并经 mapper 处理的数据。
- 接口失败、超时、鉴权失败或 token 缺失时展示错误态，不回退 mock。
- 等级列表为空视为接口不可用，展示错误态。
- 字段缺失时使用安全空值，避免白屏；不从 mock 补业务数值。

## 验收标准

- [x] `/mine` 成功状态可用。
- [x] `/promotion/benefits` 成功状态可用，并支持切换等级。
- [x] 联调阶段未渲染或拼接 mock 业务数据。
- [x] API 契约与 Apifox 当前接口一致。
- [ ] App WebView 有效 token 联调通过。

## 对外沟通摘要

```text
本次 H5 我的页和权益中心已切真实接口：
GET /p/app/profile/summary
GET /p/daren/level/myLevel
GET /p/daren/level/list

后端请确认测试数据、字段口径和 path 命名；App 请确认 /mine 与 /promotion/benefits 打开时 mallToken Cookie 可被 H5 SSR/BFF 读取。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-27 | H5 | 已实现，待联调 | Apifox 项目 `4403987` main 分支，接口状态 released。 |
