# 对接说明：H5 注册公开固定入口

## 基本信息

- 编号：BRIEF-2026-0706-001
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0706-001-h5-register-public-entry.md`
- 状态：ready
- H5 负责人：待补充
- 后端负责人：server-meumall
- 原生 App 负责人：不涉及
- 管理后台负责人：不涉及
- 目标联调时间：2026-07-06 起
- 目标上线环境：测试域名 `https://hybird.aigcpop.com`

## 需求背景

运营后续会把注册页面生成二维码给用户使用。二维码不能绑定 `/h5-v/<version>/register` 这种随 H5 发布版本变化的路径，否则版本容器下线或升级后二维码可能失效。

## H5 侧目标

H5 继续在版本容器内承载 `/register` 页面。对外只暴露固定入口 `https://hybird.aigcpop.com/register`，由 server-meumall 解析当前 active manifest 并跳转到当前生效版本的注册页。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| 注册页公开入口 | `/register` | server-meumall resolver | 302 到 active H5 版本注册页 |
| 注册页实际页面 | `/h5-v/<version>/register` | H5 | 由 hybird-meumall 版本容器承载 |

## 数据流

```text
用户扫码 -> GET /register -> server-meumall 查询 active manifest -> 302 /h5-v/<version>/register -> H5 注册页
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 是 | `GET /register`，返回 302 | `.ai-workspace/contracts/api/h5-register-public-entry-contract.md` |
| 调整接口 | 否 | 不改变 `/api/h5/manifest/active` | 同上 |
| 鉴权 | 否 | 公开二维码入口无需鉴权 | 同上 |
| 缓存策略 | 是 | resolver 不缓存 active manifest，跟随当前 active 指针 | 同上 |
| 错误码 | 是 | active 缺失或 route 缺失返回 404 | 同上 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 注册二维码入口不是 App 内注册入口 |  |
| 原生页面跳转 | 否 | 不涉及 |  |
| 登录态 | 否 | 注册页自身处理注册流程 |  |
| 最低 App 版本 | 否 | 外部 H5 入口 |  |
| fallback | 否 | active route 缺失时 resolver 404 |  |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 否 | 当前直接读取 active manifest |  |
| 素材管理 | 否 | 不涉及 |  |
| 上下线开关 | 否 | 通过 active manifest 发布/回滚控制 |  |
| 排序规则 | 否 | 不涉及 |  |
| 灰度规则 | 否 | 注册二维码入口固定指向 active，不走用户灰度 |  |

## H5 侧责任

- [x] 版本化 H5 中存在 `/register` 页面。
- [x] 发版 manifest routes 包含 `/register`。
- [x] 注册页面真实接口、AES 加密、认证后续流程由既有注册任务负责。
- [x] 页面可在 `/h5-v/<version>/register` 下正常访问。

## 对方责任

### 后端 / server-meumall

- [x] 提供 `GET /register` 固定入口。
- [x] 查询 active manifest 并生成 302 目标。
- [x] active manifest 未声明 `/register` 时返回 404。

### 运维

- [ ] nginx 将公网 `/register` 转发到 `server-meumall`。
- [ ] 保留 `/h5-v/<version>/` 到版本 H5 容器的代理。

### 运营

- [ ] 二维码固定使用 `https://hybird.aigcpop.com/register`。
- [ ] 不把 `/h5-v/<version>/register` 直接投放给用户。

## Mock 和联调方式

- Mock 数据位置：无。
- Mock 使用阶段：不适用。
- 测试接口环境：`https://hybird.aigcpop.com/register`
- App 测试包版本：不涉及。
- 管理后台测试入口：active manifest 发布平台。
- 联调步骤：先发布并激活包含 `/register` route 的 H5 版本，再访问固定入口确认 302。
- 联调阶段是否已移除页面 mock 兜底：注册页业务接口另由注册任务控制。

## 真实接口渲染规则

public entry 不渲染页面，只做 302。H5 注册页进入后继续遵循注册任务的接口和错误展示规则。

## H5 兜底策略

- active manifest 缺失：`GET /register` 返回 404。
- active manifest 未声明 `/register`：返回 404，避免跳转到不存在页面。
- 当前 active 版本异常：通过 release promote/rollback 切换 active manifest。

## 验收标准

- [x] 固定入口 302 到 active H5 版本注册页。
- [x] query 参数保留；测试和正式环境通过域名与部署实例区分，入口不接收 `environment` query。
- [x] active route 缺失返回 404。
- [x] server/H5/root 文档已同步。
- [ ] 飞书知识库已同步。

## 对外沟通摘要

```text
本次 H5 注册二维码入口调整为固定 URL：
https://hybird.aigcpop.com/register

该入口由 server-meumall 查询 active manifest 后 302 到当前 H5 版本：
https://hybird.aigcpop.com/h5-v/<version>/register

运维需要将公网 /register 转发到 server-meumall；运营二维码不要再使用 /h5-v/<version>/register。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-07-06 | 需求方 | 已确认 | 按固定入口方案实施 |
