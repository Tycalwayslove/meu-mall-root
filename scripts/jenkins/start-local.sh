#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_HOME="${ROOT_DIR}/meumall-ci"

mkdir -p "${CI_HOME}/jenkins/pipelines"
cp "${ROOT_DIR}/deploy/jenkins/meu-mall-test-server-deploy.groovy" \
  "${CI_HOME}/jenkins/pipelines/meu-mall-test-server-deploy.groovy"

"${CI_HOME}/ops/start-all.sh"

cat <<EOF

Jenkins 已启动：
- 地址：http://127.0.0.1:8082
- 用户：meumall
- 密码：meumall-local-2026

用于测试服务器整站部署的任务：
- meu-mall-test-server-deploy

首次运行前，请在 Jenkins 凭据里添加 Secret Text：
- ID: meu-mall-test-server-password
- Secret: 测试服务器 SSH 密码
EOF
