#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_HOME="${ROOT_DIR}/meumall-ci"

mkdir -p "${CI_HOME}/jenkins/pipelines"
rm -f "${CI_HOME}/jenkins/pipelines/hybird-meumall-local-deploy.groovy"
cp "${ROOT_DIR}/deploy/jenkins/meu-mall-test-server-deploy.groovy" \
  "${CI_HOME}/jenkins/pipelines/meu-mall-test-server-deploy.groovy"

"${CI_HOME}/ops/start-all.sh"

for attempt in $(seq 1 30); do
  if curl -fsS --max-time 2 http://127.0.0.1:8082/login >/dev/null; then
    break
  fi
  sleep 2
done

CRUMB="$(
  curl -fsS \
    --user meumall:meumall-local-2026 \
    http://127.0.0.1:8082/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\) \
    2>/dev/null || true
)"
if [ -n "${CRUMB}" ]; then
  curl -fsS \
    --user meumall:meumall-local-2026 \
    -H "${CRUMB}" \
    -X POST \
    http://127.0.0.1:8082/job/hybird-meumall-local-deploy/doDelete \
    >/dev/null 2>&1 || true
fi

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
