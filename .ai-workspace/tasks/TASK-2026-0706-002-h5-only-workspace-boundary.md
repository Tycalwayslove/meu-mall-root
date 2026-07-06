# TASK-2026-0706-002 H5 单项目工作区边界收敛

## 状态

verified

## 目标

将 MeuMall 根工作区从历史多项目协作模式收敛为只维护 `hybird-meumall` H5 C 端的工作区。后续 AI 需求、实现、验证和文档同步默认只考虑 H5；旧 `server-meumall`、`admin-meumall`、`app-meumall` 和 `meumall-ci` 已从当前工作区移除，不再作为本仓库当前项目范围。

## 背景

当前 H5 版本管理、manifest active、后台发布和旧配置服务能力已经迁移到 Java。项目中已经没有 `meu-mall/server:test` 和 `meu-mall/admin:test` 这两个 Docker 发布对象，也不再维护旧 Python server、admin 配置台或 iOS 原生壳。

根级 AI 工作流、发布脚本和 Nginx 模板仍残留历史多项目口径，会导致后续 AI 继续把 server/admin/iOS 当作当前协作端，甚至误跑旧全栈测试服部署链路。

## 涉及项目

- `hybird-meumall`：唯一当前维护项目。
- 根级 `.ai-workspace`：需要更新工作流、项目地图、发布治理和任务事实源。
- 根级 `scripts` / `deploy`：需要移除旧 server/admin 测试服务入口。

## 范围

- 更新根级 AI 工作流，明确当前仓库只维护 H5 C 端。
- 将旧 `server-meumall`、`admin-meumall`、`app-meumall` 和 `meumall-ci` 物理移出当前工作区，不再作为后续需求考虑范围。
- 将 Java H5 版本管理和 Java 业务接口明确为外部接口事实源。
- 清理根命令和部署残留，避免继续生成 `meu-mall/server:test`、`meu-mall/admin:test`。
- 更新 H5 项目内状态文档和验证记录。
- 同步飞书知识库相关页面。

## 不包含

- 不修改 Java 后端、Java 管理台或 iOS App 仓库。
- 不重写历史任务和 release notice，只更新当前事实源和入口规则。

## 责任边界

- H5：负责页面、BFF、H5 侧接口消费、H5 构建和 H5 发布脚本。
- Java：外部负责 H5 版本管理、active manifest、release 注册/切 active、业务 API、管理后台能力。
- iOS/App：外部运行环境，不再作为本仓库实现或验收对象。
- 旧 Python server/admin：已退役，不再作为 H5 发版、manifest 或管理后台事实源。

## 契约影响

- 契约类型：工作区项目边界、发布治理、H5 与 Java 外部接口边界。
- 向后兼容：对 H5 用户路径兼容；对旧 `server/admin` 本地开发命令不兼容。
- 迁移：根命令和旧 Docker/Compose 部署入口迁移到 H5-only。
- 灰度：无运行时灰度；属于仓库工作流变更。

## 对接说明

- 不新增跨团队 integration brief；本任务是工作区内部边界治理。
- 飞书知识库需同步项目总览、H5 发版流程和相关规则页。

## 对方责任

- Java 后端/管理台继续提供 H5 版本管理与业务接口。
- 运营、测试、发布后续只使用 H5 固定入口和 H5 版本发布链路，不再要求本仓库启动旧 admin/server。

## Mock 和联调方式

- Mock：无。
- 联调方式：H5 通过环境配置访问 Java 测试/正式接口。
- 本地开发：只启动 `hybird-meumall`。

## 验收标准

- [x] 根级 AI 工作流恢复入口明确只维护 `hybird-meumall`。
- [x] 根命令不再包含 `dev:server`、`dev:admin`、`check:server`、`check:admin`、`check:app`。
- [x] 根命令只保留 H5-only Jenkins job 同步入口，不恢复旧 `meumall-ci`。
- [x] 旧 `meu-mall/server:test` 和 `meu-mall/admin:test` Docker/Compose 入口被移除。
- [x] `server-meumall`、`admin-meumall`、`app-meumall` 和 `meumall-ci` 目录已从当前工作区物理移除。
- [x] Nginx 模板不再代理 `/api/` 到旧 Python server，也不再代理 `/admin/` 到旧 admin。
- [x] H5 发版链路仍可 dry run。
- [x] H5 项目 AI 文档同步当前边界。
- [x] 飞书知识库完成同步并回写 revision。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall
bash -n scripts/deploy/h5-version-deploy.sh
bash -n scripts/deploy/h5-jenkins-release.sh
bash -n scripts/jenkins/sync-h5-job.sh
bash -n scripts/root/check-all.sh
node --check scripts/register-resolver/server.js
node scripts/register-resolver/test.js
DRY_RUN=true bash scripts/jenkins/sync-h5-job.sh
DRY_RUN=true GIT_REF=HEAD ALLOW_INITIAL_H5_RELEASE=true H5_RELEASE_ENV=test bash scripts/deploy/h5-version-deploy.sh
git diff --check
```

## 发布影响

- 旧全栈测试服部署入口退役。
- H5 正式发布继续走 `scripts/deploy/h5-version-deploy.sh` 和 Java H5 版本管理。
- 如需恢复旧 admin/server，需要另开历史项目恢复任务，不作为当前 H5 需求的一部分。

## 风险和阻塞

- 历史文档、历史任务和旧 release notice 中仍会保留 `server/admin/app` 字样，不能作为当前事实源。
- 旧项目目录作为本机独立 Git 工作副本可能仍存在，但根工作流不再读取或要求修改。
- H5 仍会消费 Java API；这不是本仓库后端项目，只作为外部接口契约处理。

## 变更记录

- 2026-07-06：创建任务，开始收敛根级 AI 工作流和部署入口。
- 2026-07-06：完成根级 AGENTS、AI 工作流、项目地图、发布治理、H5 需求流程、模板、H5 项目状态、发布规范、变更记录和决策记录更新。
- 2026-07-06：删除旧 server/admin Docker、Compose、Jenkins 测试服脚本和旧测试服部署文档；根命令收敛为 H5-only。
- 2026-07-06：按最新要求物理删除旧 `server-meumall`、`admin-meumall`、`app-meumall` 和 `meumall-ci` 目录；删除根本地 Jenkins 启动脚本和 `ci:*` 命令。
- 2026-07-06：飞书同步完成：项目总览 revision 5；页面盘点 revision 75；H5 发版流程 revision 9；H5 需求协作流程 revision 5。
- 2026-07-06：补充 H5-only Jenkins Pipeline 同步入口 `scripts/jenkins/sync-h5-job.sh` 和根命令 `pnpm run jenkins:sync-h5`，用于在旧 `meumall-ci` 移除后创建或更新唯一 H5 发版 job。

## 验证结果

- `bash -n scripts/root/dev-all.sh scripts/root/check-all.sh scripts/deploy/h5-version-deploy.sh scripts/deploy/h5-jenkins-release.sh scripts/jenkins/sync-h5-job.sh`：通过。
- `DRY_RUN=true bash scripts/jenkins/sync-h5-job.sh`：通过，已生成 H5 `workflow-job` 配置 XML。
- `node --check scripts/register-resolver/server.js`：通过。
- `node scripts/register-resolver/test.js`：通过。
- `bash scripts/root/dev-lib.test.sh`：通过。
- `DRY_RUN=true GIT_REF=HEAD ALLOW_INITIAL_H5_RELEASE=true H5_RELEASE_ENV=test bash scripts/deploy/h5-version-deploy.sh`：通过；输出只包含 H5 镜像、H5 版本容器、Java manifest/register 和 register resolver。
- `pnpm run check`：通过。
- `git diff --check`：通过。

## 飞书同步记录

| 页面 | 链接 | revision |
| --- | --- | --- |
| 项目总览 | <https://v05ctaei9gn.feishu.cn/wiki/IGtzwfR1yi3F9Zkim4Ocno1gnAd> | 5 |
| 页面盘点 | <https://v05ctaei9gn.feishu.cn/wiki/WgaqwTRRUitnRNkCtNPcOcDnnre> | 75 |
| H5 发版流程 | <https://v05ctaei9gn.feishu.cn/wiki/HyBpwTbNUigKsOkO2Qgc2rjBnie> | 9 |
| H5 需求协作流程 | <https://v05ctaei9gn.feishu.cn/wiki/RaXBw8iZZiDjGCkUH0WcYWaPnpf> | 5 |
