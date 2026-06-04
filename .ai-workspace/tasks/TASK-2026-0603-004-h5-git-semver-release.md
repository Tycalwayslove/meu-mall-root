# TASK-2026-0603-004-h5-git-semver-release

## 状态

released

## 目标

将 H5 多容器发布版本体系从手动日期版本升级为 `package.json` 语义化版本，并将每次发布和 Git commit/tag、Jenkins 构建、Docker 容器、server release manifest 绑定。

## 背景

原 H5 发布版本使用类似 `2026.06.03-002` 的日期递增格式，并由 Jenkins 手动输入 `H5_VERSION` 和 `ROLLBACK_VERSION`。这会带来几个问题：

- 版本号和代码提交没有强绑定，排查线上问题时需要人工反查。
- 回滚目标依赖人工输入，容易和当前线上 active 版本不一致。
- Jenkins 参数过多，发布人员需要理解太多内部细节。
- package 版本、Git 版本、manifest 版本、容器版本之间没有统一规则。

## 涉及项目

- 根目录部署脚本
- `hybird-meumall`
- `server-meumall`
- `meumall-ci`

## 范围

包含：

- `hybird-meumall/package.json` 增加 `version`。
- H5 部署脚本从 `package.json` 派生 `vX.Y.Z`。
- 正式发布要求存在 `h5/vX.Y.Z` Git tag。
- 正式发布要求 H5 工作区 HEAD 与发布 Git ref 一致，且工作区干净。
- 回滚目标从线上 active manifest 的 `stableVersion` 自动读取。
- release payload 的 `buildMeta` 增加 Git、package、Jenkins、Docker 信息。
- Jenkins H5 发布 job 删除 `H5_VERSION` 和 `ROLLBACK_VERSION` 参数，仅保留 `GIT_REF`。
- 更新 H5 发布规范和 server release API 示例。

不包含：

- 不自动创建 Git tag。
- 不自动提交代码。
- 不修改 server release 数据模型。

## 责任边界

`hybird-meumall`：

- 维护 package 版本。
- 确保发布 commit 已打 `h5/vX.Y.Z` tag。
- 提供 release 注册 payload 的构建元数据。

根目录部署脚本：

- 校验版本、Git ref、Git tag、工作区状态。
- 构建版本容器并注册 candidate release。
- 从 active manifest 自动确定 `rollbackVersion`。

`server-meumall`：

- 存储 release 和 active manifest。
- 提供 active manifest 查询接口。

`meumall-ci`：

- 初始化并同步 Jenkins H5 发布 job。
- 只暴露必要发布参数。

## 验收标准

- [x] H5 版本源来自 `hybird-meumall/package.json`。
- [x] 部署脚本不再按日期生成版本。
- [x] 部署脚本不再使用手填 `ROLLBACK_VERSION`。
- [x] 正式部署要求 `h5/vX.Y.Z` tag 和干净工作区。
- [x] release `buildMeta` 包含 Git/package/Jenkins/Docker 追溯信息。
- [x] Jenkins H5 发布 job 删除旧版本参数。
- [x] 发布规范和接口文档更新为语义化版本。

## 验证命令

```bash
git diff --check
bash -n scripts/deploy/h5-version-deploy.sh
DRY_RUN=true GIT_REF=HEAD bash scripts/deploy/h5-version-deploy.sh
cd hybird-meumall && pnpm test -- scripts/ai/release-manifest.test.ts
pnpm run check:workflow
pnpm run ci:jenkins
```

验证结果：

- `git diff --check`：通过。
- `bash -n scripts/deploy/h5-version-deploy.sh`：通过。
- `DRY_RUN=true GIT_REF=HEAD bash scripts/deploy/h5-version-deploy.sh`：通过，版本从 `package.json` 派生为 `v1.0.0`，路径为 `/h5-v/v1.0.0`，镜像为 `meu-mall/h5:v1.0.0`。当前工作区为 `dirty` 且缺少 `h5/v1.0.0` tag，dry-run 允许展示；正式部署会阻止发布。
- `cd hybird-meumall && pnpm test -- scripts/ai/release-manifest.test.ts`：通过，12 个测试文件、72 个测试通过。
- `pnpm run check:workflow`：通过，H5/server/admin/app 工作流检查均通过。
- `pnpm run ci:jenkins`：通过，Jenkins 已同步 `meu-mall-h5-version-deploy`，旧 `H5_VERSION` 和 `ROLLBACK_VERSION` 参数已移除。
- `cd hybird-meumall && pnpm test -- src/lib/commerce/mock-data.test.ts scripts/ai/release-manifest.test.ts`：通过，12 个测试文件、72 个测试通过。
- `cd hybird-meumall && pnpm test -- src/features/home/home.test.tsx`：v1.0.1 和 v1.0.2 变更前均通过，12 个测试文件、72 个测试通过。
- `cd hybird-meumall && pnpm typecheck`：v1.0.0、v1.0.1、v1.0.2 变更前均通过。
- `curl -kfsSL https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod`：最终 active manifest 为 `stableVersion=v1.0.2`、`rollbackVersion=v1.0.1`、`assets.basePath=/h5-v/v1.0.2`。
- `curl -kfsS https://hybird.aigcpop.com/h5-v/v1.0.0/api/health`、`/h5-v/v1.0.1/api/health`、`/h5-v/v1.0.2/api/health`：均返回 200。
- `curl -kfsSL https://hybird.aigcpop.com/h5-v/v1.0.2/_next/static/chunks/145or.f2pb6ie.js`：包含 `首页演练标记：第二次首页改动`。

## 发布记录

| 版本 | Git commit | Git tag | release id | rollbackVersion | 结果 |
| --- | --- | --- | --- | --- | --- |
| `v1.0.0` | `aaaf494` | `h5/v1.0.0` | `b1d5e148-c8fd-47ab-8a1d-b36d525917a8` | `2026.06.03-003` | 已部署并 promote 为 active，smoke 通过。 |
| `v1.0.1` | `b694225` | `h5/v1.0.1` | `89edd567-fa19-42f9-bc01-9e8f15120e1c` | `v1.0.0` | 已部署并 promote 为 active，smoke 通过。 |
| `v1.0.2` | `11d6020` | `h5/v1.0.2` | `81c2b308-fa13-4f61-919f-309652861e13` | `v1.0.1` | 已部署并 promote 为 active，smoke 通过。 |

最终 active manifest：

```text
stableVersion=v1.0.2
rollbackVersion=v1.0.1
assets.basePath=/h5-v/v1.0.2
routes=19
```

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-03 | implemented | 完成 H5 语义化版本、Git tag 校验、自动回滚版本读取和 Jenkins 参数收敛。 |
| 2026-06-03 | verified | 完成脚本语法、dry-run、release 注册测试、工作流检查和 Jenkins 同步验证。 |
| 2026-06-03 | released | 按 v1.0.0、v1.0.1、v1.0.2 连续发布三个 H5 版本，最终 active 指向 v1.0.2。 |
