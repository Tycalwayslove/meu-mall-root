# Meu Mall 线上测试服务器部署说明

## 目标

- 服务器：`8.163.107.208`
- 部署目录：`/opt/mail4j/meu-mall`
- H5 域名：`hybird.aigcpop.com`
- 部署范围：`hybird-meumall`、`admin-meumall`、`server-meumall`

## 线上访问路径

- H5：`http://hybird.aigcpop.com/`
- 管理后台：`http://hybird.aigcpop.com/admin/`
- 后端健康检查：`http://hybird.aigcpop.com/api/health`
- HTTPS H5：`https://hybird.aigcpop.com/`

宿主机只暴露 Nginx 对外入口。Docker 服务绑定在 `127.0.0.1`：

- server：`127.0.0.1:4100`
- h5：`127.0.0.1:3109`
- admin：`127.0.0.1:5173`

## 本地手动部署

在根目录执行：

```bash
npm run deploy:test-server
```

脚本会提示输入 SSH 用户和密码。密码只用于当前进程，不会写入仓库、日志或配置文件。

也可以通过环境变量指定：

```bash
REMOTE_HOST=8.163.107.208 \
REMOTE_USER=root \
REMOTE_PATH=/opt/mail4j/meu-mall \
DOMAIN=hybird.aigcpop.com \
npm run deploy:test-server
```

如果服务器已经配置 SSH key：

```bash
SSH_KEY=/path/to/key.pem npm run deploy:test-server
```

## Jenkins 部署

启动本地 Jenkins：

```bash
npm run ci:jenkins
```

这个命令会先把整站部署 Pipeline 同步到本地 Jenkins 挂载目录，然后启动 Jenkins 和 Mac agent。

Pipeline 文件：

```text
deploy/jenkins/meu-mall-test-server-deploy.groovy
```

Jenkins 需要添加一个 Secret Text 凭据：

```text
credentialsId: meu-mall-test-server-password
```

凭据内容是测试服务器 SSH 密码。Pipeline 会把它注入为 `SERVER_PASSWORD`，然后调用：

```bash
bash scripts/deploy/test-server-deploy.sh
```

Jenkins 启动后访问：

```text
http://127.0.0.1:8082
```

默认登录信息：

```text
用户：meumall
密码：meumall-local-2026
```

整站测试部署任务：

```text
meu-mall-test-server-deploy
```

## Nginx

脚本会把独立站点配置写入：

```text
/etc/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf
```

源配置文件在仓库中：

```text
deploy/nginx/hybird.aigcpop.com.conf
```

脚本只新增或覆盖这个单独的 Meu Mall 配置文件，不修改服务器上其他 Nginx 配置。

服务器上 443 端口由既有的 `mall4j-nginx` 容器以 host 网络模式占用。为了避免浏览器因 HSTS 自动升级到 HTTPS 后落入 Mall4j 默认站点，部署脚本会在检测到 `mall4j-nginx` 时额外写入：

```text
/opt/mail4j/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf
```

源配置文件在仓库中：

```text
deploy/nginx/hybird.aigcpop.com.ssl.conf
```

这份 HTTPS 配置只新增 `hybird.aigcpop.com` server，不修改 `mall.aigcpop.com`、`shop.aigcpop.com`、`platform.aigcpop.com` 等既有 Mall4j 域名。

## Docker Compose

Compose 文件：

```text
deploy/docker-compose.test.yml
```

远端手动查看状态：

```bash
cd /opt/mail4j/meu-mall
docker compose -f deploy/docker-compose.test.yml ps
docker compose -f deploy/docker-compose.test.yml logs -f
```

重启：

```bash
cd /opt/mail4j/meu-mall
docker compose -f deploy/docker-compose.test.yml up -d --build
```

停止：

```bash
cd /opt/mail4j/meu-mall
docker compose -f deploy/docker-compose.test.yml down
```

## 远端目录边界

`/opt/mail4j/meu-mall` 是测试服务器部署目录，不是完整源码仓库。部署脚本会先在本地生成一个最小发布包，再同步到服务器：

- 保留：`deploy/docker-compose.test.yml`、`deploy/docker/`、`deploy/nginx/`、`scripts/deploy/test-server-deploy.sh`。
- 保留：`hybird-meumall` 构建所需的 `package.json`、`pnpm-lock.yaml`、配置文件、`src/` 和 `public/`。
- 保留：`admin-meumall` 构建所需的 `package.json`、`pnpm-lock.yaml`、配置文件和 `src/`。
- 保留：`server-meumall` 运行所需的 `requirements.txt` 和 `app/`。
- 不同步：`.ai-workspace/`、`docs/`、`app-meumall/`、`meumall-ci/`、子项目 AI 文档、本地缓存、构建产物和日志。

这样服务器目录只承担 Docker 构建和测试运行职责，Jenkins、原生 App、长期 AI 工作区文档仍留在本地仓库中管理。

## 数据

后端 SQLite 数据挂载在：

```text
/opt/mail4j/meu-mall/runtime/server-data
```

部署同步会排除 `runtime/`，避免覆盖线上测试数据。
