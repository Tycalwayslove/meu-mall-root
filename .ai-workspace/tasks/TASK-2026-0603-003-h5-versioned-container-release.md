# TASK-2026-0603-003-h5-versioned-container-release

## 状态

released

## 目标

将 H5 发布从单容器替换模型升级为多容器版本并存模型，并补齐本地 Jenkins H5 版本构建发布 job。

## 背景

当前线上测试环境已经可以通过 active manifest 切换 H5 版本，但 H5 SSR 产物本身仍是单容器运行。这样会导致：

- manifest 可以指向新版本，但旧版本容器不一定还在。
- 回滚可能需要重新部署旧版本，而不是只切 manifest。
- 灰度版本、稳定版本和回滚版本无法同时在线。

H5 是 Next.js SSR，不能只用静态版本目录解决。Next `basePath` 是构建期配置，因此每个版本应构建独立镜像，并以独立容器运行。

## 涉及项目

- 根目录部署脚本
- `hybird-meumall`
- `server-meumall`
- `meumall-ci`

## 范围

包含：

- 新增 H5 版本容器发布脚本。
- nginx 支持 `/h5-v/<version>/` 动态版本入口。
- Dockerfile 支持版本路径和 CDN 静态资源预留参数。
- 根目录 package 命令支持 H5 版本发布。
- 本地 Jenkins 增加 H5 版本发布 job。
- 发布文档更新为多容器 + CDN 分阶段模型。

不包含：

- 不立即清理旧 H5 容器。
- 不实现自动删除历史版本。
- 不实现 CDN 上传脚本。
- 不增加 release API 鉴权。
- 不修改 App 端 manifest 解析逻辑。

## 责任边界

根目录部署脚本：

- 负责构建版本镜像、启动版本容器、写 nginx location、执行 smoke、注册 release。

`hybird-meumall`：

- 负责按版本 `H5_BASE_PATH` 构建 SSR standalone。
- 负责页面版本标识和资源 basePath/CDN 变量消费。

`server-meumall`：

- 负责存储 release manifest 和 active 指针。

`meumall-ci`：

- 负责本地 Jenkins job 初始化和参数化触发。

## 契约影响

- 是否影响跨项目契约：是
- 契约类型：H5 release、manifest `assets.basePath`、CI 与 server release 注册
- 是否向后兼容：是，manifest schema 不变，`basePath` 值从根路径切换为版本路径。
- 是否需要迁移：已有 active manifest 不强制迁移；后续新 H5 release 使用 `/h5-v/<version>`。
- 是否需要灰度：脚本支持 candidate 注册；是否 promote 由 Jenkins 参数控制。

## 对接说明

- App 仍按 `assets.serviceBaseUrl + assets.basePath + routes[route].path` 拼接 URL。
- App 不需要知道容器端口或 nginx upstream。
- CDN 阶段 App 仍只读取 manifest，不直接拼 CDN 静态资源地址。

## Mock 和联调方式

- H5 版本 URL：

```text
https://hybird.aigcpop.com/h5-v/<version>/
```

- Jenkins job：

```text
meu-mall-h5-version-deploy
```

- 本地命令：

```bash
H5_VERSION=2026.06.03-002 \
ROLLBACK_VERSION=2026.06.03-001 \
PROMOTE_RELEASE=false \
pnpm run deploy:h5-version
```

## 验收标准

- [x] H5 版本发布脚本存在并可 dry run。
- [x] Dockerfile 支持 `H5_BASE_PATH`、`H5_VERSION`、`H5_RELEASE_LABEL`、`H5_ASSET_PREFIX` 和 `NEXT_PUBLIC_H5_ASSET_BASE_URL`。
- [x] nginx 主配置 include 版本 location snippet。
- [x] 根目录 package scripts 暴露 H5 版本发布命令。
- [x] Jenkins pipeline 文件存在。
- [x] `scripts/jenkins/start-local.sh` 同步 `meu-mall-h5-version-deploy` job。
- [x] Jenkins 初始化 groovy 支持创建 `meu-mall-h5-version-deploy` job。
- [x] 线上测试服务器实际跑通一个 `/h5-v/<version>/` 版本容器。
- [ ] admin-meumall 展示版本容器运行状态。
- [ ] CDN 上传脚本接入。

## 验证命令

```bash
git diff --check
DRY_RUN=true H5_VERSION=2026.06.03-002 bash scripts/deploy/h5-version-deploy.sh
DRY_RUN=true H5_VERSION=2026.06.03-002 ROLLBACK_VERSION=2026.06.03-001 pnpm run deploy:h5-version
bash -n scripts/deploy/h5-version-deploy.sh
bash -n scripts/deploy/test-server-deploy.sh
node -e "JSON.parse(require('fs').readFileSync('package.json','utf8')); console.log('package.json ok')"
cd hybird-meumall && pnpm test -- scripts/ai/release-manifest.test.ts scripts/ai/ssr-release.test.ts
cd server-meumall && .venv/bin/pytest
pnpm run check:workflow
pnpm run ci:jenkins
Jenkins job meu-mall-h5-version-deploy，参数 H5_VERSION=2026.06.03-002、ROLLBACK_VERSION=2026.06.03-001、REGISTER_RELEASE=true、PROMOTE_RELEASE=false
curl -kfsSL --max-time 20 'https://hybird.aigcpop.com/h5-v/2026.06.03-002/'
```

验证结果：

- `git diff --check`：通过。
- `DRY_RUN=true H5_VERSION=2026.06.03-002 bash scripts/deploy/h5-version-deploy.sh`：通过，输出版本路径 `/h5-v/2026.06.03-002`、镜像 `meu-mall/h5:2026.06.03-002`、容器 `meu-mall-h5-2026.06.03-002`。
- `DRY_RUN=true H5_VERSION=2026.06.03-002 ROLLBACK_VERSION=2026.06.03-001 pnpm run deploy:h5-version`：通过。
- `bash -n scripts/deploy/h5-version-deploy.sh`：通过。
- `bash -n scripts/deploy/test-server-deploy.sh`：通过。
- `node -e ... package.json`：通过。
- `hybird-meumall pnpm test -- scripts/ai/release-manifest.test.ts scripts/ai/ssr-release.test.ts`：通过，12 个测试文件、72 个测试通过。
- `server-meumall .venv/bin/pytest`：通过，14 个测试通过，1 个 Starlette/httpx deprecation warning。
- `pnpm run check:workflow`：通过，H5/server/admin/app 工作流检查均通过。
- `pnpm run ci:jenkins`：通过，Jenkins 已同步 `meu-mall-test-server-deploy` 和 `meu-mall-h5-version-deploy`。
- Jenkins `meu-mall-h5-version-deploy`：第 4 次构建成功，构建并启动 `2026.06.03-002` 版本容器，注册 release id `84f63d0e-b715-4f39-b7c2-44e48caedd72`，状态为 `candidate`。
- Jenkins `meu-mall-h5-version-deploy`：第 5 次构建成功，修正 nginx exact location 后，`https://hybird.aigcpop.com/h5-v/2026.06.03-002/` 和无尾斜杠地址均返回 200。
- 线上 promote：通过 `POST /api/releases/84f63d0e-b715-4f39-b7c2-44e48caedd72/promote` 将 `2026.06.03-002` 切为 active。
- active manifest：`stableVersion=2026.06.03-002`，`rollbackVersion=2026.06.03-001`，`assets.basePath=/h5-v/2026.06.03-002`，route 数量 19。
- 线上 smoke：`/h5-v/2026.06.03-002/api/health`、`/h5-v/2026.06.03-002/`、`/h5-v/2026.06.03-002/promotion`、`/h5-v/2026.06.03-002/mine` 均返回 200。

## 发布影响

- 是否需要发布：脚本和 Jenkins job 本身需要同步到本地 Jenkins；线上版本容器需要后续手动或 Jenkins 触发。
- 发布项目：H5 SSR 版本容器。
- 是否需要灰度：本次未灰度，直接将 `2026.06.03-002` promote 为 active。
- 回滚目标：manifest `rollbackVersion` 指向的旧版本容器。
- smoke check：`/h5-v/<version>/api/health` 和 `/h5-v/<version>/`。

## 风险和阻塞

- `basePath` 是构建期配置，不能复用同一镜像挂多个版本路径。
- 测试服务器资源有限，建议常驻 2 到 3 个 H5 容器。
- CDN 阶段必须保证旧版本静态资源不删除。
- release API 鉴权仍待后续任务补齐。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-03 | implemented | 新增 H5 版本容器发布脚本、nginx 版本入口、Jenkins job 和发布文档。 |
| 2026-06-03 | verified | Jenkins 实际构建 `2026.06.03-002` 版本容器成功，线上版本路径 200，release 为 candidate，未切 active。 |
| 2026-06-03 | released | 将 `2026.06.03-002` promote 为 active，active manifest 指向 `/h5-v/2026.06.03-002`，线上 smoke 通过。 |
