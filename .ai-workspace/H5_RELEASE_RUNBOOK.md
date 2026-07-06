# H5 发版操作手册

本文说明 MeuMall H5 从代码提交到线上 active 的完整发版流程。目标是让开发者不依赖 Codex，也可以自己完成候选版本发布、线上切换、验证和回滚。

## 适用范围

本文只覆盖 `hybird-meumall` 的 H5 多版本容器发布。

相关项目职责：

| 项目 | 职责 |
| --- | --- |
| `hybird-meumall` | H5 源码、Next.js 构建、版本号、Git tag、发布记录 |
| `server-meumall` | 历史 Python release/manifest 服务，仅作为旧链路参考 |
| `admin-meumall` | Java H5 版本管理台：版本列表、发布 active、灰度、回滚 |
| `meumall-ci` | 本地 Jenkins 和发布流水线 |
| 根目录 `scripts/deploy/h5-version-deploy.sh` | 真正执行 H5 多版本部署的核心脚本 |

## 当前发布模型

H5 不是覆盖式发布，而是“多版本容器并存”。

每次发版都会生成一个独立版本：

```text
版本号：v1.0.11
basePath：/h5-v/v1.0.11
Docker 镜像：meu-mall/h5:v1.0.11
Docker 容器：meu-mall-h5-v1.0.11
线上 URL：https://hybird.aigcpop.com/h5-v/v1.0.11/
```

App 不应该写死某个 H5 URL，而是先读取 Java H5 版本管理 active manifest：

```text
{JAVA_H5_RELEASE_API_BASE_URL}/platform/h5Release/active?environment={environment}
```

manifest 中的 `stableVersion`、`assets.serviceBaseUrl`、`assets.basePath` 和 `routes` 决定当前 App 应加载哪个 H5 版本。

`routes` 的事实源是 `hybird-meumall/src/app/**/page.*`。Jenkins 核心脚本会在发布时自动扫描 App Router 页面并写入 release payload；`hybird-meumall/scripts/ai/register-release.ts` 在未传 `--routes` 时也会自动扫描。除临时兼容验证外，不应在 Jenkins 参数里手写 `H5_ROUTES`，否则新增页面容易漏进 Java active manifest。

## 发版前必须确认

发版前先确认这些条件：

| 检查项 | 要求 |
| --- | --- |
| 代码状态 | `hybird-meumall` 必须没有未提交改动 |
| 版本号 | `hybird-meumall/package.json` 的 `version` 必须是语义化版本，例如 `1.0.12` |
| Git tag | 发布 commit 必须有 `h5/vX.Y.Z` tag，例如 `h5/v1.0.12` |
| 当前分支 | 本地 `hybird-meumall` 的 `HEAD` 必须正好指向要发布的 tag |
| 服务端 | Java H5 版本管理 active 接口可访问，例如 `https://test.aigcpop.com:18088/apis/platform/h5Release/active?environment=test` |
| 服务器 | 测试服务器 `8.163.107.208` Docker 可用，`/opt/mail4j/meu-mall` 可写 |

核心脚本会自动拦截以下情况：

- `package.json` 没有 `version`。
- `version` 不是 `1.0.1` 这种 npm 语义化版本。
- 找不到 `h5/vX.Y.Z` tag。
- 当前 `HEAD` 和要发布的 tag 不一致。
- `hybird-meumall` 有未提交改动。
- 无法读取 Java H5 版本管理 active manifest。

## 标准发版流程

### 1. 进入项目

```bash
cd /Users/mac/person_code/meu-mall
```

### 2. 更新 H5 代码并自测

```bash
cd hybird-meumall
pnpm install
pnpm test
pnpm typecheck
pnpm lint
```

如果 `.next/types` 因删除路由等原因残留旧类型，可以先清理再跑：

```bash
rm -rf .next
pnpm typecheck
```

### 3. 修改版本号

例如从 `1.0.11` 升到 `1.0.12`：

```bash
pnpm version patch --no-git-tag-version
```

也可以手动修改：

```text
hybird-meumall/package.json
```

注意：`package.json` 里写 `1.0.12`，不要写 `v1.0.12`。脚本会自动加 `v`，最终 H5 版本是 `v1.0.12`。

### 4. 提交 H5 代码

```bash
git status --short
git add .
git commit -m "feat(xxx): 描述本次 H5 变更"
```

### 5. 创建并推送 H5 tag

假设版本是 `1.0.12`：

```bash
git tag h5/v1.0.12
git push origin HEAD
git push origin h5/v1.0.12
```

发布脚本默认会找 `h5/v{package.json version}`，所以 `package.json` 和 tag 必须一致。

### 6. 回到根目录做 dry run

```bash
cd /Users/mac/person_code/meu-mall
DRY_RUN=true pnpm run deploy:h5-version
```

dry run 只打印将要发布的版本、tag、basePath、镜像、容器、回滚版本等信息，不会连接服务器，也不会改 Docker、Nginx 或 release API。

你应该重点看：

```text
Version:      v1.0.12
Git ref:      h5/v1.0.12
Git tag:      h5/v1.0.12
Rollback:     v1.0.11
Base path:    /h5-v/v1.0.12
Image:        meu-mall/h5:v1.0.12
Container:    meu-mall-h5-v1.0.12
```

### 7. 发布 candidate

candidate 表示“版本容器已经在线上跑起来，也注册到了 release 服务，但还没有切 active”。

```bash
PROMOTE_RELEASE=false \
REGISTER_RELEASE=true \
RUN_REMOTE_SMOKE=true \
INSTALL_NGINX=true \
pnpm run deploy:h5-version
```

脚本会提示输入服务器用户和密码。默认用户是 `root`，服务器是 `8.163.107.208`。

也可以通过环境变量传入密码：

```bash
SERVER_PASSWORD='你的服务器密码' \
PROMOTE_RELEASE=false \
REGISTER_RELEASE=true \
RUN_REMOTE_SMOKE=true \
INSTALL_NGINX=true \
pnpm run deploy:h5-version
```

candidate 发布成功后，可以直接访问版本 URL 验证：

```text
https://hybird.aigcpop.com/h5-v/v1.0.12/
https://hybird.aigcpop.com/h5-v/v1.0.12/promotion
https://hybird.aigcpop.com/h5-v/v1.0.12/mine
```

此时 active manifest 还不会指向新版本。

### 8. 验证 candidate

至少验证这些地址：

```bash
curl -kfsSL https://hybird.aigcpop.com/h5-v/v1.0.12/api/health
curl -kfsSL https://hybird.aigcpop.com/h5-v/v1.0.12/promotion -o /tmp/promotion.html
curl -kfsSL https://hybird.aigcpop.com/h5-v/v1.0.12/mine -o /tmp/mine.html
curl -kfsSL "${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active?environment=${H5_RELEASE_ENV:-test}"
```

页面类 smoke 建议用浏览器看：

- 页面是否白屏。
- 静态图片是否正常显示。
- 路由是否正常。
- 右上角 H5 版本标识是否是新版本。
- Bridge 调试按钮或关键跳转是否正常。

### 9. 切 active

有两种方式。

第一种：发布时直接切 active。适合已经本地验证过、风险较小的版本：

```bash
PROMOTE_RELEASE=true \
REGISTER_RELEASE=true \
RUN_REMOTE_SMOKE=true \
INSTALL_NGINX=true \
pnpm run deploy:h5-version
```

第二种：先发布 candidate，再通过管理台或 API 切 active。适合需要先验版本 URL 的版本。

API 方式：

```bash
curl -kfsSL "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release/list?environment=${H5_RELEASE_ENV:-test}"
```

找到目标版本对应的 `id` 后执行：

```bash
curl -kfsSL -X POST "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release/{releaseId}/promote"
```

切 active 后再次确认：

```bash
curl -kfsSL "${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active?environment=${H5_RELEASE_ENV:-test}"
```

确认返回里：

```json
{
  "stableVersion": "v1.0.12",
  "assets": {
    "serviceBaseUrl": "https://hybird.aigcpop.com",
    "basePath": "/h5-v/v1.0.12"
  }
}
```

### 10. 发布后记录

发布脚本会在 H5 项目下生成 release 记录：

```text
hybird-meumall/archives/releases/v1.0.12/release-registration.json
hybird-meumall/archives/releases/v1.0.12/release-registration-response.json
hybird-meumall/archives/releases/v1.0.12/release-promote-response.json
```

如果这些记录需要进入 Git，由于 `archives` 可能被 ignore，需要强制添加：

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
git add .ai/CHANGE_SUMMARY.md .ai/test-reports
git add -f archives/releases/v1.0.12
git commit -m "docs(release): 记录H5 v1.0.12发布结果"
git push origin HEAD
```

### 11. 发送飞书发版通报

发版完成后，按飞书审核流程发送发版通报。流程规则见：

```text
.ai-workspace/H5_FEISHU_RELEASE_NOTIFICATION_WORKFLOW.md
```

本项目推荐由 `company-feishu` 发送审核消息和正式群通报。你需要在本地配置中确认：

```json
{
  "profile": "company-feishu",
  "sendAs": "bot",
  "senderDisplayName": "company-feishu",
  "reviewChatId": "审核会话 chat_id",
  "targetChatId": "正式对接群 chat_id"
}
```

如果这是第一次把项目进展同步给正式对接群，先发送“项目迭代总览”。这条消息用于告诉原生、后端、测试和管理台：H5 到今天为止做了哪些体系、页面、发布能力和协作机制，后续还缺什么。

```bash
cd /Users/mac/person_code/meu-mall
pnpm run feishu:h5-release-notice -- overview-preview
pnpm run feishu:h5-release-notice -- request-overview-review
```

审核人在飞书审核会话回复：

```text
同意 总览
```

由于当前不依赖自动读取审核群消息，审核确认后执行显式审核短命令：

```bash
pnpm run feishu:h5-overview-approve
```

然后发送正式对接群：

```bash
pnpm run feishu:h5-release-notice -- send-overview-approved
```

总览发出后，后续每个 H5 版本只发送单版本增量通报。

单版本发版时，`scripts/deploy/h5-version-deploy.sh` 默认会在 release 注册完成后自动发送待审核通报到审核群：

```text
SEND_FEISHU_REVIEW=true
```

如果只是演练飞书消息，不真实发送，可以传：

```bash
FEISHU_REVIEW_DRY_RUN=true pnpm run deploy:h5-version
```

如果某次发版明确不需要发送审核消息，可以传：

```bash
SEND_FEISHU_REVIEW=false pnpm run deploy:h5-version
```

也可以手动生成预览：

```bash
cd /Users/mac/person_code/meu-mall
pnpm run feishu:h5-release-notice -- preview
```

或者手动发送审核消息：

```bash
pnpm run feishu:h5-release-notice -- request-review
```

审核人在飞书审核会话回复：

```text
同意 v1.0.12
```

审核确认后执行显式审核短命令：

```bash
pnpm run feishu:h5-release-approve
```

然后发送正式对接群：

```bash
pnpm run feishu:h5-release-notice -- send-approved
```

## 脚本到底做了什么

根目录命令：

```bash
pnpm run deploy:h5-version
```

实际执行：

```bash
bash scripts/deploy/h5-version-deploy.sh
```

脚本流程如下：

1. 读取 `hybird-meumall/package.json` 的 `version`。
2. 生成 H5 版本号：`v{version}`。
3. 生成默认 Git tag：`h5/v{version}`。
4. 校验当前 H5 `HEAD` 必须等于要发布的 tag。
5. 校验 H5 工作区必须干净。
6. 请求 Java H5 版本管理 active manifest（`/platform/h5Release/active?environment=<env>`），读取当前 `stableVersion` 作为新版本的 `rollbackVersion`。脚本不再允许用旧 Python `/api/h5/manifest/active` 或 Java 业务 `/mini_h5` 作为版本管理来源。
7. 打包同步部署上下文到服务器 `/opt/mail4j/meu-mall`，包含：
   - `deploy/docker`
   - `deploy/nginx`
   - `hybird-meumall/package.json`
   - `hybird-meumall/pnpm-lock.yaml`
   - `hybird-meumall/src`
   - `hybird-meumall/public`
   - Next、Tailwind、TypeScript、ESLint 等配置文件
8. 在服务器执行 Docker build：
   - Dockerfile：`deploy/docker/h5.Dockerfile`
   - 镜像：`meu-mall/h5:vX.Y.Z`
   - basePath：`/h5-v/vX.Y.Z`
9. 启动独立版本容器：
   - 容器名：`meu-mall-h5-vX.Y.Z`
   - 容器内端口：`3109`
   - 宿主机端口：默认自动选 `3200-3299`
   - 只绑定 `127.0.0.1`，不直接暴露公网
10. 请求容器内健康检查：
    - `http://127.0.0.1:{port}/h5-v/vX.Y.Z/api/health`
11. 写入服务器运行记录：
    - `/opt/mail4j/meu-mall/releases/h5/vX.Y.Z/runtime.json`
    - `/opt/mail4j/meu-mall/releases/h5/vX.Y.Z/host-port.txt`
12. 写入 Nginx 版本 location：
    - `/opt/mail4j/nginx/conf.d/meu-mall-h5-versions/vX.Y.Z.conf`
13. reload `mall4j-nginx`。
14. 远端 smoke：
    - HTTP Host 头访问版本 health。
    - HTTPS 域名访问版本 health。
    - HTTPS 域名访问版本首页。
    - 版本容器已注入 Java / Python BFF 运行时环境，避免 API route 报 `JAVA_API_BASE_URL is required.` 或 `PYTHON_API_BASE_URL is required.`。
15. 调用 `hybird-meumall/scripts/ai/register-release.ts` 生成 release payload。
16. 请求 Java `POST /platform/h5Release` 注册 candidate release。
17. 如果 `PROMOTE_RELEASE=true`，继续请求 Java `POST /platform/h5Release/{id}/promote` 切 active。
18. 如果 `SEND_FEISHU_REVIEW=true`，执行 `pnpm run feishu:h5-release-notice -- request-review`，并把 `H5_RELEASE_ENV`、`JAVA_H5_RELEASE_API_BASE_URL`、`JAVA_H5_RELEASE_REGISTER_API_BASE_URL` 等 Java release 配置显式传给飞书通知脚本；通知脚本会从 Java active/list 取当前版本和 commit。

## 常用发布参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `REMOTE_HOST` | `8.163.107.208` | 测试服务器 IP |
| `REMOTE_USER` | `root` | SSH 用户 |
| `REMOTE_PORT` | `22` | SSH 端口 |
| `REMOTE_PATH` | `/opt/mail4j/meu-mall` | 服务器部署目录 |
| `DOMAIN` | `hybird.aigcpop.com` | H5 域名 |
| `SERVER_PASSWORD` | 空 | 服务器密码；不传会交互式输入 |
| `SSH_KEY` | 空 | SSH 私钥路径；配置后可不用密码 |
| `GIT_REF` | `h5/v{version}` | 要发布的 Git ref |
| `H5_HOST_PORT` | 空 | 指定宿主机端口；空则自动选 `3200-3299` |
| `H5_RUNTIME_ENV_FILE` | `hybird-meumall/config/env/h5.prod.env` | 发布版本容器的运行时环境来源；脚本会读取并注入 `APP_ENV`、`JAVA_API_BASE_URL`、`PYTHON_API_BASE_URL`、`JAVA_OSS_ASSET_BASE_URL` 和 BFF 日志配置 |
| `NEXT_PUBLIC_H5_ASSET_BASE_URL` | 空 | CDN 静态资源根地址；当前可留空 |
| `REGISTER_RELEASE` | `true` | 是否注册 release |
| `PROMOTE_RELEASE` | `false` | 是否发布后立即切 active |
| `INSTALL_NGINX` | `true` | 是否写入 Nginx 版本 location 并 reload |
| `RUN_REMOTE_SMOKE` | `true` | 是否执行远端 smoke |
| `SYNC_WORKSPACE` | `true` | 是否同步构建上下文到服务器 |
| `SEND_FEISHU_REVIEW` | `true` | 发版完成后是否发送飞书待审核通报到审核群 |
| `FEISHU_REVIEW_DRY_RUN` | `false` | 飞书待审核通报是否只 dry-run 不真实发送 |
| `DRY_RUN` | `false` | 只打印计划，不执行发布 |

## Jenkins 发版

当前轻量流程下，Jenkins 负责测试环境 H5 版本构建、部署、smoke、Git tag 和 Java candidate 注册；管理后台继续负责版本 promote、gray 和 rollback。

Jenkins 任务：

```text
meu-mall-h5-test-release
```

任务执行脚本：

```bash
bash scripts/deploy/h5-jenkins-release.sh
```

版本控制已迁移到 Java H5 版本管理接口，Jenkins 不再调用旧 Python `/api/releases` 或 `/api/h5/manifest/active`。Java 接口使用：

```text
GET  /platform/h5Release/active?environment=test
GET  /platform/h5Release/list?environment=test
POST /platform/h5Release
```

active manifest、注册、promote、gray、rollback 接口按 Java `data` wrapper 兼容解析；如果接口直接返回业务对象，也会按业务对象处理。

旧 Python/prod active manifest 只能作为历史生产链路兜底，不能作为 Jenkins/Java 测试发版审核的线上版本来源。当前测试发版线上 active 版本必须以 Java H5 版本管理为准。

### 启动本地 Jenkins

```bash
cd /Users/mac/person_code/meu-mall
pnpm run ci:jenkins
```

默认信息：

```text
地址：http://127.0.0.1:8082
用户：meumall
密码：meumall-local-2026
```

H5 测试环境发版 job：

```text
meu-mall-h5-test-release
```

### Jenkins 参数怎么填

Jenkins 页面只需要选择：

| 参数 | 建议 |
| --- | --- |
| `H5_GIT_BRANCH` | 从下拉列表选择要发布到测试环境的远程 H5 分支 |

其余测试环境参数固定从本机配置文件读取：

```text
/Users/mac/person_code/meu-mall/meumall-ci/config/h5-test-release.env
```

该配置文件保存：

- H5 固定仓库：`git@github.com:Tycalwayslove/hybird-meumall.git`
- Java H5 版本管理 active/list base URL 和 token。测试环境管理系统前缀为 `https://test.aigcpop.com:18088/apis`，通过 `JAVA_H5_RELEASE_API_BASE_URL` 配置。
- Jenkins 注册 H5 版本记录的写接口同样属于管理系统前缀，测试环境为 `https://test.aigcpop.com:18088/apis`，通过 `JAVA_H5_RELEASE_REGISTER_API_BASE_URL` 配置。
- 注册写接口如需鉴权，配置 `JAVA_H5_RELEASE_REGISTER_TOKEN`；未配置时复用 `JAVA_H5_RELEASE_TOKEN`。若 Jenkins 报 `Unauthorized`，说明管理端注册接口尚未放行或 token 未配置。
- H5 容器运行时业务接口仍从所选 H5 分支的 `config/env/h5.test.env` 读取 `JAVA_API_BASE_URL`。
- 测试服务器 IP、用户、端口、目录、域名和 SSH 密码。
- 是否注册 Java candidate、是否推 tag、是否清理旧 H5 容器/image/nginx location。测试环境默认 `REMOTE_KEEP_RELEASES=5`，即保留最近 5 个版本的容器、镜像、release 目录和 Nginx snippet。
- 是否发送飞书审核群通知。测试环境默认 `SEND_FEISHU_REVIEW=true`，Jenkins 发版成功后只发送审核群待确认通报，不直接发送正式对接群。

Jenkins 发版前不再要求本地 H5 工作区切到目标提交，也不要求提前创建 tag。Jenkins 会在独立工作目录拉取远程 H5 仓库的所选分支，部署和 smoke 通过后再创建并推送 `h5/vX.Y.Z` tag。

默认版本号由 H5 仓库 `package.json` 的 major/minor 和远程 `h5/v*` tag 共同决定：同一 major/minor 下 patch 每次成功发版递增；当 `package.json` 从 `1.0.x` 升到 `2.0.0` 时，默认从 `v2.0.0` 开始。

Jenkins 发版脚本现在会强制校验 release 管理接口：

- `JAVA_H5_RELEASE_API_BASE_URL` 必须显式配置为 Java 管理系统前缀。
- `JAVA_H5_RELEASE_REGISTER_API_BASE_URL` 必须显式配置为 Java 管理系统前缀。
- 如果配置值包含旧 Python `/api/h5/manifest`、旧 `/api/releases` 或 Java 业务 `/mini_h5`，脚本会在构建前失败。
- 运行时 H5 业务接口仍使用 `JAVA_API_BASE_URL`，但它只用于 H5 BFF 调业务接口，不允许作为版本管理接口 fallback。

同一个 Git commit 默认只能生成一个 H5 版本。Jenkins 会在构建前检查：

- 当前 commit 是否已经存在 `h5/v*` tag。
- Java H5 版本列表中是否已经存在相同 `buildMeta.gitCommit`。

命中任一条件时，构建会在 Docker build 前失败。只有人工确认需要重发同一 commit 时，才允许临时设置：

```bash
ALLOW_REPEAT_H5_COMMIT_RELEASE=true
```

Java H5版本管理也应在注册接口侧做同样约束：同一 `environment + buildMeta.gitCommit` 不允许创建多个 release 版本，除非显式走重发/覆盖语义。

### 飞书通知流程

Jenkins 发版成功后自动执行：

```bash
pnpm run feishu:h5-release-notice -- request-review --version vX.Y.Z --git-tag h5/vX.Y.Z
```

这一步只发送到审核群。审核通过后，再人工执行：

```bash
pnpm run feishu:h5-release-approve
pnpm run feishu:h5-release-notice -- send-approved --version vX.Y.Z --git-tag h5/vX.Y.Z
```

正式对接群只允许通过 `send-approved` 发送，避免未审核内容直接打扰对接群。

### 发版审核基准确认

每次发送飞书审核前，必须先确认当前 Java active 和本次目标版本，不能沿用旧聊天上下文或旧 Python/prod manifest。

标准确认步骤：

```bash
cd /Users/mac/person_code/meu-mall
set -a
. meumall-ci/config/h5-test-release.env
set +a

curl -kfsSL "${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active?environment=${H5_RELEASE_ENV:-test}"
curl -kfsSL "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release/list?environment=${H5_RELEASE_ENV:-test}"
```

需要从返回中记录：

- 当前线上 `activeVersion`：active manifest 的 `stableVersion`。
- 当前线上 `activeCommit`：list 中 `status=active` 且 `version=activeVersion` 的 `buildMeta.gitCommit`。
- 本次待审核 `targetVersion`：Jenkins 本次生成的版本号，例如 `v1.0.22`。
- 本次待审核 `targetCommit`：list 中目标版本的 `buildMeta.gitCommit`，或目标 tag `h5/vX.Y.Z` 反查出的 commit。
- 本次 diff：`activeCommit..targetCommit`。

改动统计命令：

```bash
git -C hybird-meumall log --oneline <activeCommit>..<targetCommit>
git -C hybird-meumall diff --shortstat <activeCommit>..<targetCommit>
```

审核消息必须写清楚：

```text
当前线上 active：vX.Y.Z / <activeCommitShort>
本次待审核版本：vA.B.C / <targetCommitShort>
对比范围：<activeCommitShort>..<targetCommitShort>
```

如果 Java active 接口的 `data` 字段是 JSON 字符串，需要先把外层响应解析成对象，再把 `data` 字符串二次解析为 manifest。若 active 接口只能拿到 manifest，commit 必须从 Java list 的 `buildMeta.gitCommit` 补齐。

## 回滚流程

如果新版本切 active 后出现问题，优先使用 release 服务回滚，不要手动改 Nginx。

### 1. 查看 release 列表

```bash
curl -kfsSL "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release/list?environment=${H5_RELEASE_ENV:-test}"
```

找到当前异常 active release 的 `id`。

### 2. 回滚到默认 rollbackVersion

```bash
curl -kfsSL \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"reason":"线上异常，回滚到上一稳定版本"}' \
  "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release/{releaseId}/rollback"
```

### 3. 指定目标版本回滚

```bash
curl -kfsSL \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"targetVersion":"v1.0.11","reason":"指定回滚到 v1.0.11"}' \
  "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release/{releaseId}/rollback"
```

### 4. 回滚后验证

```bash
curl -kfsSL "${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active?environment=${H5_RELEASE_ENV:-test}"
```

确认：

- `stableVersion` 已变为目标版本。
- `assets.basePath` 已变为目标版本路径。
- 异常版本进入 `blacklistVersions`。
- App 重新读取 manifest 后会加载回滚版本。

## 常见问题

### 1. 提示找不到 Git ref

原因：没有创建 tag，或 tag 名不对。

处理：

```bash
cd hybird-meumall
git tag h5/v1.0.12
git push origin h5/v1.0.12
```

### 2. 提示 HEAD 与 GIT_REF 不一致

原因：当前代码不是 tag 对应的 commit。

处理：

```bash
cd hybird-meumall
git checkout h5/v1.0.12
```

或者切回包含该 tag 的分支，并确保 `HEAD` 正好是发布 commit。

### 3. 提示存在未提交改动

原因：H5 工作区 dirty。

处理：

```bash
cd hybird-meumall
git status --short
```

该提交的提交，不该提交的先处理掉。不要带着 dirty 工作区发版。

### 4. 版本 URL 能访问，但 active 还是旧版本

原因：发布时 `PROMOTE_RELEASE=false`，只注册了 candidate。

处理：

- 到 admin 管理台点击发布 active。
- 或调用 Java `POST /platform/h5Release/{id}/promote`。
- 或重新执行一次 `PROMOTE_RELEASE=true` 的发布。

### 5. 图片线上不显示

优先检查是否用了裸路径 `/assets/...`。H5 页面里引用本地静态资源必须走项目封装的 basePath 工具，确保线上版本路径是：

```text
/h5-v/vX.Y.Z/assets/...
```

不要写死：

```text
/assets/...
```

### 6. Docker 端口冲突

默认会自动选择 `3200-3299` 中未占用的端口。如果需要强制指定：

```bash
H5_HOST_PORT=3212 pnpm run deploy:h5-version
```

### 7. Nginx reload 失败

脚本会先执行：

```bash
docker exec mall4j-nginx nginx -t
```

如果失败，不会 reload。需要先看错误位置，不要手动覆盖其他服务的 Nginx 配置。

## 推荐发版节奏

日常开发推荐：

1. H5 功能开发完成。
2. 本地验证 `test/typecheck/lint/build`。
3. 升版本号。
4. commit。
5. tag `h5/vX.Y.Z`。
6. push branch 和 tag。
7. Jenkins 或命令行发布 candidate。
8. 打开版本 URL 验证。
9. 切 active。
10. 验证 active manifest 和 App 实机。
11. 补充 release 记录。

低风险快速发版可以把第 7 和第 9 步合并：

```bash
PROMOTE_RELEASE=true REGISTER_RELEASE=true RUN_REMOTE_SMOKE=true INSTALL_NGINX=true pnpm run deploy:h5-version
```

高风险版本必须先 candidate，确认后再 promote。
