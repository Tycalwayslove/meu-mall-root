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

## 数据

后端 SQLite 数据挂载在：

```text
/opt/mail4j/meu-mall/runtime/server-data
```

部署同步会排除 `runtime/`，避免覆盖线上测试数据。
