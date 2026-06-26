# TASK-2026-0615-001-h5-version-api-java-migration

## 状态

draft

## 目标

梳理当前 H5 版本、manifest、release、灰度、回滚相关接口和表数据，为迁移到 Java 后端统一管理提供对接输入。

## 背景

当前 `server-meumall` 使用 FastAPI + SQLite 管理 H5 manifest config、release 记录、active manifest、灰度和回滚。用户希望将 H5 版本相关接口迁移给 Java 统一管理，需要先列清当前接口、请求响应、表结构和现有数据。

## 涉及项目

- `server-meumall`
- `admin-meumall`
- `hybird-meumall`
- `app-meumall`
- `meumall-ci`

## 范围

包含：

- 当前 H5 active manifest、config、release、gray、rollback 接口盘点。
- 当前 `manifest_configs` 表结构和测试环境最新行数据盘点。
- 明确旧首页配置接口和 `home_page_configs` 表作废，不纳入 Java 迁移导入范围。
- Java 迁移兼容要求、调用方配置点和待确认问题。

不包含：

- Java 代码实现。
- Python FastAPI 服务删除。
- 线上数据库迁移脚本。
- 飞书知识库同步。

## 责任边界

`server-meumall`：

- 提供当前实现、接口行为和 SQLite 数据事实源。

Java 后端：

- 确认目标服务、表设计、鉴权策略、接口兼容方式和迁移窗口。

`admin-meumall`：

- 如 Java path 或响应结构变化，更新 H5 版本管理相关 `src/lib/configApi.ts` 和后台展示。
- 旧首页配置接口已作废，后续按 Java 新首页配置方案重做或下线。

`hybird-meumall`：

- 如 active manifest 地址或 schema 变化，更新环境 profile 和 manifest runtime 消费逻辑。

`app-meumall`：

- 如 active manifest 地址变化，更新 `HybridManifestURL` 和 fallback 策略。

`meumall-ci`：

- 如 release 注册接口变化，更新 H5 version deploy 脚本和 smoke 流程。

## 契约影响

- 是否影响跨项目契约：是。
- 契约文档路径：当前先以 `docs/h5-version-api-java-migration-inventory.md` 作为盘点输入；后续应补正式 `release-api-contract` / `manifest-contract`。
- 是否向后兼容：待 Java 确认。
- 是否需要迁移：是，至少涉及 `manifest_configs`。
- 是否需要灰度：需要，active manifest 是 App/H5 启动入口。

## 对接说明

- 是否需要对接说明：是。
- 对接说明路径：`.ai-workspace/integration-briefs/BRIEF-2026-0615-001-h5-version-api-java-migration.md`
- 需要确认的角色：后端 / 管理后台 / 原生 App / CI 或发布
- 当前确认状态：待确认

## 对方责任

后端：

- 确认 Java 服务是否保持现有 API path 和响应结构。
- 确认表设计、数据导入方式、鉴权方式和回滚方案。
- 首页配置接口不要求兼容旧 Python 实现，由 Java 端自行设计开发。

原生 App：

- 确认 active manifest 地址切换方式和失败 fallback。

管理后台：

- 确认旧首页配置入口下线或等待 Java 新方案重做。

CI 或发布：

- 确认 release 注册、promote、gray、rollback 接口是否保持当前 payload。

## Mock 和联调方式

- Mock / 当前数据来源：测试环境 `https://hybird.aigcpop.com/api/releases?environment=prod`
- 本地 schema 参考：`server-meumall/data/meumall-config.sqlite`
- 测试接口环境：`https://hybird.aigcpop.com`
- App 测试包版本：待原生确认。
- 管理后台测试入口：`admin-meumall` 本地默认 `VITE_CONFIG_API_BASE_URL=http://127.0.0.1:4100`
- 联调步骤：Java 提供兼容接口后，依次验证 active manifest、admin release 列表、CI 注册 candidate、promote、gray、rollback。
- H5 fallback：Java active manifest 异常时需保留可切回 Python 服务或旧 manifest 的回滚方案。

## 实现计划

1. 输出当前接口和表数据盘点文档。
2. Java 后端确认兼容策略和数据迁移方式。
3. 创建或更新正式 manifest/release API 契约。
4. Java 实现兼容接口并导入数据。
5. admin、H5、App、CI 切换配置并联调验证。

## 验收标准

- [x] 当前接口逐项列出，并标注消费者和当前行为。
- [x] 当前版本主链路表结构和测试环境最新行数据列出；旧首页配置表标记为历史参考。
- [x] Java 迁移兼容要求和待确认问题列出。
- [ ] Java 后端确认 path、schema、鉴权和迁移方案。
- [ ] Java 联调环境通过 active manifest、release 注册、promote、gray、rollback 验证。

## 验证命令

```bash
sqlite3 server-meumall/data/meumall-config.sqlite '.schema manifest_configs'
sqlite3 server-meumall/data/meumall-config.sqlite '.schema home_page_configs'
curl -kfsS --max-time 20 'https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod'
curl -kfsS --max-time 20 'https://hybird.aigcpop.com/api/releases?environment=prod'
```

## 发布影响

- 是否需要发布：后续迁移阶段需要。
- 发布项目：Java 后端、admin 配置、H5 env profile、App manifest URL、CI 发布脚本按确认结果决定。
- 是否需要灰度：需要。
- 回滚目标：Python `server-meumall` 当前 active manifest 服务，或迁移前导出的 manifest JSON。
- smoke check：`GET /api/h5/manifest/active?environment=prod`、App 启动加载 H5、CI release 注册、admin release 操作。

## 风险和阻塞

- 当前 release/config 接口没有鉴权，迁移时若补鉴权会影响 admin 和 CI。
- 当前 `GET /api/releases` 实现会返回 `manifest_configs` 中匹配环境的所有行；测试环境当前没有 draft 行，但 Java 若新增 release/config 类型边界需要同步前端。
- 测试环境最早期历史记录 `2026.05.15-001` 含 legacy `/cart` route，和产品事实“无购物车”不一致；当前 active `v1.0.14` 已不包含 `/cart`。
- 旧首页配置接口已作废，admin 侧如仍有入口需要后续单独处理。
- 正式 manifest/release 根级契约尚未补齐。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-15 | draft | 创建 H5 版本接口 Java 迁移盘点任务。 |
| 2026-06-15 | draft | 明确旧首页配置接口作废，由 Java 端自行开发，不纳入迁移。 |
| 2026-06-15 | draft | 将表数据来源从本地 SQLite 修正为测试环境 `/api/releases?environment=prod` 最新数据。 |
