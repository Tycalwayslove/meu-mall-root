# 对接说明：H5 版本接口迁移 Java

## 基本信息

- 编号：BRIEF-2026-0615-001
- 关联工作项：`.ai-workspace/tasks/TASK-2026-0615-001-h5-version-api-java-migration.md`
- 状态：draft
- H5 负责人：待确认
- 后端负责人：Java 后端，待确认
- 原生 App 负责人：待确认
- 管理后台负责人：待确认
- CI/发布负责人：待确认
- 目标联调时间：待确认
- 目标上线环境：待确认

## 需求背景

当前 H5 版本发布、active manifest、灰度、回滚接口由测试环境 `https://hybird.aigcpop.com` 提供。现在需要迁移给 Java 后端统一管理。迁移前需要 Java 同事明确当前接口行为、表结构、测试环境最新数据和调用方。

完整盘点文档：

```text
docs/h5-version-api-java-migration-inventory.md
```

## H5 侧目标

- 保持 App/H5 读取 active manifest 的方式稳定。
- 保持 CI 发布脚本可以注册 candidate release。
- 保持 admin 可以查看、发布、灰度和回滚 H5 版本。
- 旧首页配置接口明确作废，不要求 Java 兼容；Java 首页配置能力后续自行设计开发。
- Java 切换过程中，H5 线上版本可回滚。

## 页面范围

| 页面 | 路由 | 端归属 | 说明 |
| --- | --- | --- | --- |
| H5 active manifest | `/api/h5/manifest/active?environment=prod` | server / Java | App 和 H5 版本入口，不是业务页面。 |
| 后台版本管理 | `admin-meumall` 内 release/config 页面 | Admin | 调用 config/release 接口。 |

## 数据流

```text
CI 构建 H5 版本 -> POST /api/releases -> Java 保存 release
管理后台/发布脚本 -> promote/gray/rollback -> Java 更新 active manifest
App/H5 启动 -> GET /api/h5/manifest/active -> 根据 manifest 打开 H5 版本 URL
```

## 后端依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 新增接口 | 是 | Java 需要提供兼容的 manifest/config/release API。旧首页配置接口不迁移。 | 待补正式 release/manifest API 契约。 |
| 调整接口 | 是 | 当前 Python path 可保持，也可由网关兼容。 | `docs/h5-version-api-java-migration-inventory.md` |
| 鉴权 | 是 | 当前无鉴权；正式迁移建议补 CI token、admin 权限或内网限制。 | 待 Java 确认。 |
| 缓存策略 | 是 | active manifest 必须 no-cache。 | 盘点文档已标注。 |
| 错误码 | 是 | 需兼容 404/409/422/400 当前语义，或同步调用方。 | 待补正式契约。 |

## 原生 App 依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| Native Bridge | 否 | 本次不涉及 Bridge 方法。 | 无 |
| 原生页面跳转 | 否 | 不改变 H5 route 打开规则。 | 无 |
| 登录态 | 否 | active manifest 当前无登录态。 | 无 |
| 最低 App 版本 | 待确认 | 如果 manifest URL 或 schema 变化，需要 App 确认可兼容版本。 | 待确认 |
| fallback | 是 | Java 服务异常时，App fallback manifest 或旧 Python 服务回退方案需确认。 | 待确认 |

## 管理后台依赖

| 事项 | 是否需要 | 说明 | 契约 |
| --- | --- | --- | --- |
| 配置项 | 是 | `admin-meumall` 当前调用 config/release/home config API；其中 home config 旧接口已作废。 | 盘点文档已列出。 |
| 素材管理 | 否 | 本次主链路不涉及素材。 | 无 |
| 上下线开关 | 是 | active/promote/gray/rollback 都是发布操作。 | 待补正式契约。 |
| 排序规则 | 是 | release/config 列表当前按 `updated_at desc`。 | 盘点文档已列出。 |
| 灰度规则 | 是 | `grayRules.percentage` 和 `grayVersion` 需要保持。 | 待补正式契约。 |

## H5 侧责任

- [x] 梳理当前接口和调用方配置点。
- [x] 导出当前表结构和测试环境最新行数据。
- [ ] Java 接口确认后，更新 H5 env profile 或 manifest runtime 相关配置。
- [ ] 联调 active manifest、版本 URL 和回滚路径。

## 对方责任

### 后端

- [ ] 确认 Java 服务是否保持现有 API path。
- [ ] 确认 `manifest_configs` 迁移方案；`home_page_configs` 不迁移。
- [ ] 确认鉴权、权限和内网/网关策略。
- [ ] 提供测试环境 base URL。
- [ ] 提供 SQLite 数据导入方式和导入校验结果。
- [ ] 首页配置能力由 Java 端另行设计开发，不兼容旧 Python `/api/home/configs`。

### 原生 App

- [ ] 确认 `HybridManifestURL` 切换方式。
- [ ] 确认 Java active manifest 不可用时的 fallback。

### 管理后台

- [ ] 确认 Java 响应字段是否保持当前 configApi 兼容。
- [ ] 如不兼容，更新 `admin-meumall/src/lib/configApi.ts`。
- [ ] 下线旧首页配置入口，或等待 Java 新首页配置方案后重做。

### CI 或发布

- [ ] 确认 `scripts/deploy/h5-version-deploy.sh` 的 `SERVER_URL`、release 注册 payload 和 promote 行为。
- [ ] 补充 Java release 注册后的 smoke check。

## Mock 和联调方式

- Mock / 当前数据来源：测试环境 `https://hybird.aigcpop.com/api/releases?environment=prod`
- 测试接口环境：Java 待提供；当前 Python/FastAPI 测试环境为 `https://hybird.aigcpop.com`
- App 测试包版本：待确认
- 管理后台测试入口：`admin-meumall` 本地或测试环境
- 联调步骤：
  1. Java 按测试环境 `/api/releases?environment=prod` 导入当前 `manifest_configs` 数据。
  2. 验证 `GET /api/h5/manifest/active?environment=prod` 返回 active manifest body。
  3. 验证 admin release list 与 Python 旧服务数据一致。
  4. 注册新 candidate release。
  5. 执行 promote、gray、rollback。
  6. App 拉取 manifest 并打开对应 H5 版本 URL。

## H5 兜底策略

- Java active manifest 404 或网络异常：App 继续使用 fallback manifest；发布侧保留 Python 服务或旧 manifest JSON 作为回滚方案。
- Java release 注册失败：CI 不切 active，H5 版本容器可保留但不对 App 生效。
- Java gray/rollback 失败：不得手动修改 H5 版本容器代替 manifest 指针；需要恢复旧 active manifest。

## 验收标准

- [ ] Java `GET /api/h5/manifest/active?environment=prod` 直接返回 manifest body，无 wrapper。
- [ ] active manifest header 包含 `Cache-Control: no-cache, max-age=0, must-revalidate`。
- [ ] Java release 列表、注册、promote、gray、rollback 行为与盘点文档一致，或差异已同步调用方。
- [ ] 当前测试环境 `manifest_configs` 数据已导入并校验 active 版本 `v1.0.14`。
- [ ] admin、CI、App、H5 均完成测试环境联调。
- [ ] 发布影响和回滚方式已说明。

## 对外沟通摘要

```text
本次 H5 版本接口准备迁移给 Java 统一管理。当前 Python 服务接口和 SQLite 数据已整理在：
docs/h5-version-api-java-migration-inventory.md

请 Java 后端重点确认：
1. 是否保持 /api/h5/manifest/active、/api/releases、/api/configs 这些 path 和响应结构。
2. /api/home/configs 旧首页配置接口已明确作废，不纳入迁移；Java 首页配置能力自行设计。
3. manifest_configs 当前测试环境 19 条数据是否原样导入；最早期 2026.05.15-001 历史记录仍含 legacy /cart route，当前 active v1.0.14 已不包含。
4. 正式环境鉴权、网关、CI token、admin 权限如何处理。
5. Java 异常时如何回滚到旧 active manifest 或旧 Python 服务。

联调验收优先级：
1. App/H5 能读取 active manifest。
2. CI 能注册 candidate release。
3. admin 能 promote/gray/rollback。
4. 回滚后 App 能重新打开目标 H5 版本。
```

## 确认记录

| 日期 | 角色 | 结论 | 说明 |
| --- | --- | --- | --- |
| 2026-06-15 | AI | 待确认 | 已完成当前接口和数据盘点，等待 Java/后端确认迁移方案。 |
