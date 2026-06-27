# 对接说明：推广首页概览真实接口联调

## 基本信息

- 编号：BRIEF-2026-0627-001
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0627-001-h5-promotion-home-overview-real-api.md`
- 状态：implemented，待 App token 联调验证
- H5 负责人：待补充
- 后端负责人：待确认
- 原生 App 负责人：待确认
- 管理后台负责人：无
- 目标联调时间：2026-06-27 起
- 目标上线环境：测试环境

## 需求背景

`/promotion` 推广首页此前为 H5 高保真 mock。后端已在 Apifox 项目 `4403987` main 分支发布“达人主页接口 / 推广页概览”，H5 需要切到真实接口进行联调。

## H5 侧目标

推广 Tab 根页面 `/promotion` 首屏展示真实用户信息、达人等级、我的带货和六宫格统计。进入真实接口联调后，页面不再使用本地 mock 业务数据兜底。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 推广首页 | `/promotion` | H5 | Tab 根 WebView，数据来自 Java `/p/distribution/home/overview` |

## 数据流

```text
App WebView 写入 mallToken Cookie
  -> H5 SSR /promotion
  -> H5 BFF /api/bff/promotion/home
  -> Java GET /p/distribution/home/overview
  -> H5 mapper
  -> 推广首页渲染
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 已有 | `GET /p/distribution/home/overview` | `.ai-workspace/contracts/api/h5-promotion-home-overview-real-api-contract.md` |
| 鉴权 | 是 | H5 BFF 用 `mallToken` 转 `Authorization` 请求 Java | `h5-bff-http-auth-contract.md` |
| 缓存策略 | 是 | 用户私有收益/统计数据，H5 no-store | 同上 |
| 错误码 | 是 | 按 Java envelope `code/msg/success/data` 处理 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本次不新增 Bridge | 无 |
| 原生页面跳转 | 是 | `/promotion` 仍由原生 Tab WebView 打开 | 既有路由契约 |
| 登录态 | 是 | App 需写入有效 `mallToken` Cookie | `h5-bff-http-auth-contract.md` |
| fallback | 是 | H5 展示错误态；App 处理 WebView 通用错误 | 无新增 |

## 管理后台依赖

当前无必须交付项。

## H5 侧责任

- [x] BFF 调 Java 概览接口。
- [x] mapper 输出现有推广首页 view model。
- [x] 首屏真实数据成功态。
- [x] token 缺失、鉴权失败、接口失败错误态。
- [x] 联调阶段不使用 mock 业务数据兜底。

## 对方责任

### 后端

- [ ] 提供测试环境有效数据。
- [ ] 确认统计字段口径和空值策略。

### 原生 App

- [ ] 打开 `/promotion` 前写入 `mallToken` Cookie。
- [ ] 协助确认 H5 SSR/BFF 可读取 Cookie。

## Mock 和联调方式

- Mock 数据位置：旧 `hybird-meumall/src/features/promotion/mock/home.ts` 保留给既有 mock 阶段测试，不作为 `/promotion` 联调兜底。
- 测试接口环境：Java test `/p/distribution/home/overview`。
- 联调步骤：打开 `/promotion`，确认真实接口返回和页面展示，失败时用 response `requestId` 查 `[h5-bff-backend-call]`。
- 联调阶段是否已移除页面 mock 兜底：是。

## 真实接口渲染规则

- 首屏由 SSR 等待真实接口；Next route loading 展示骨架。
- 接口成功后只渲染 Java 概览数据经 mapper 处理后的结果。
- 接口失败、超时、鉴权失败或 token 缺失时展示错误态，不回退 mock。
- 字段缺失时使用安全空值，避免白屏；不从 mock 补业务数值。

## H5 兜底策略

token 缺失或鉴权失败：展示错误态，待 App 登录态恢复。接口异常：展示错误态。头像缺失：使用 H5 默认头像占位。等级缺失：主题降级为 V1，但收益、统计等业务数据不从 mock 补齐。

## 验收标准

- [x] H5 页面成功状态可用。
- [x] H5 页面 loading、error 状态可用。
- [x] 联调阶段未渲染或拼接 mock 业务数据。
- [x] API 契约与 Apifox 当前接口一致。
- [ ] App WebView 有效 token 联调通过。
- [x] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 推广首页 /promotion 已切到 Java 概览接口：
GET /p/distribution/home/overview

后端请确认测试数据、字段口径和错误码；App 请确认打开 /promotion 时 mallToken Cookie 可被 H5 SSR/BFF 读取。

联调口径：成功展示真实用户/等级/带货/六宫格；失败展示错误态，不回退 mock。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-27 | H5 | 已实现，待联调 | Apifox 项目 `4403987` main 分支，接口状态 released。 |
