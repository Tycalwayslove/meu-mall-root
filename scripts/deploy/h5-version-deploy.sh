#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

REMOTE_HOST="${REMOTE_HOST:-8.163.107.208}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_PATH="${REMOTE_PATH:-/opt/mail4j/meu-mall}"
DOMAIN="${DOMAIN:-hybird.aigcpop.com}"
SERVER_URL="${SERVER_URL:-https://${DOMAIN}}"
DRY_RUN="${DRY_RUN:-false}"

read_package_version() {
  node -e '
const packageJson = require(process.argv[1]);
if (!packageJson.version) process.exit(2);
process.stdout.write(packageJson.version);
' "${ROOT_DIR}/hybird-meumall/package.json"
}

resolve_git_commit() {
  local git_ref="$1"
  git -C "${ROOT_DIR}/hybird-meumall" rev-parse "${git_ref}^{commit}" 2>/dev/null
}

active_manifest_stable_version() {
  local manifest_url="${SERVER_URL%/}/api/h5/manifest/active?environment=prod"
  python3 - "${manifest_url}" <<'PY'
import json
import sys
import urllib.request

url = sys.argv[1]
with urllib.request.urlopen(url, timeout=20) as response:
    payload = json.loads(response.read().decode("utf-8"))

manifest = payload.get("data") if isinstance(payload, dict) and isinstance(payload.get("data"), dict) else payload
stable_version = manifest.get("stableVersion") if isinstance(manifest, dict) else None
if stable_version:
    print(stable_version)
PY
}

PACKAGE_VERSION="$(read_package_version || true)"
if [ -z "${PACKAGE_VERSION}" ]; then
  echo "hybird-meumall/package.json 必须声明 version，发布版本由该字段生成。" >&2
  exit 2
fi
if [[ ! "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "package.json version 必须是 npm 语义化版本，例如 1.0.1。当前值：${PACKAGE_VERSION}" >&2
  exit 2
fi

H5_VERSION="v${PACKAGE_VERSION}"
REQUIRED_GIT_TAG="h5/${H5_VERSION}"
GIT_REF="${GIT_REF:-${REQUIRED_GIT_TAG}}"
GIT_COMMIT_SHA="$(resolve_git_commit "${GIT_REF}" || true)"
if [ -z "${GIT_COMMIT_SHA}" ]; then
  if [ "${DRY_RUN}" = "true" ]; then
    GIT_REF="HEAD"
    GIT_COMMIT_SHA="$(resolve_git_commit "${GIT_REF}")"
  else
    echo "找不到 Git ref：${GIT_REF}。请先在 hybird-meumall 创建并推送 tag：${REQUIRED_GIT_TAG}" >&2
    exit 2
  fi
fi

CURRENT_HEAD_SHA="$(git -C "${ROOT_DIR}/hybird-meumall" rev-parse HEAD)"
if [ "${CURRENT_HEAD_SHA}" != "${GIT_COMMIT_SHA}" ]; then
  echo "当前 hybird-meumall HEAD 与 GIT_REF 不一致，不能发布。" >&2
  echo "HEAD:    ${CURRENT_HEAD_SHA}" >&2
  echo "GIT_REF: ${GIT_REF} -> ${GIT_COMMIT_SHA}" >&2
  exit 2
fi

GIT_TREE_STATE="clean"
if [ -n "$(git -C "${ROOT_DIR}/hybird-meumall" status --porcelain)" ]; then
  GIT_TREE_STATE="dirty"
  if [ "${DRY_RUN}" != "true" ]; then
    echo "hybird-meumall 存在未提交改动，不能发布。请先提交并创建 ${REQUIRED_GIT_TAG}。" >&2
    exit 2
  fi
fi

GIT_TAG=""
if git -C "${ROOT_DIR}/hybird-meumall" tag --points-at "${GIT_COMMIT_SHA}" | grep -qx "${REQUIRED_GIT_TAG}"; then
  GIT_TAG="${REQUIRED_GIT_TAG}"
elif [ "${DRY_RUN}" != "true" ]; then
  echo "提交 ${GIT_COMMIT_SHA} 缺少版本 tag：${REQUIRED_GIT_TAG}，不能发布。" >&2
  exit 2
fi

GIT_COMMIT_SHORT="$(git -C "${ROOT_DIR}/hybird-meumall" rev-parse --short "${GIT_COMMIT_SHA}")"
GIT_BRANCH="$(git -C "${ROOT_DIR}/hybird-meumall" rev-parse --abbrev-ref HEAD)"
GIT_COMMIT_SUBJECT="$(git -C "${ROOT_DIR}/hybird-meumall" log -1 --pretty=%s "${GIT_COMMIT_SHA}")"
ROLLBACK_VERSION="$(active_manifest_stable_version || true)"
if [ -z "${ROLLBACK_VERSION}" ]; then
  echo "无法从 active manifest 读取 rollbackVersion 来源：${SERVER_URL%/}/api/h5/manifest/active?environment=prod" >&2
  exit 2
fi

H5_RELEASE_LABEL="${H5_RELEASE_LABEL:-${H5_VERSION}}"
H5_RELEASE_VARIANT="green"
H5_BASE_PATH="/h5-v/${H5_VERSION}"
H5_IMAGE="meu-mall/h5:${H5_VERSION}"
H5_CONTAINER=""
H5_HOST_PORT="${H5_HOST_PORT:-}"
H5_ASSET_PREFIX="${H5_ASSET_PREFIX:-}"
NEXT_PUBLIC_H5_ASSET_BASE_URL="${NEXT_PUBLIC_H5_ASSET_BASE_URL:-}"
if [ -z "${H5_ASSET_PREFIX}" ] && [ -n "${NEXT_PUBLIC_H5_ASSET_BASE_URL}" ]; then
  H5_ASSET_PREFIX="${NEXT_PUBLIC_H5_ASSET_BASE_URL}"
fi

H5_ROUTES="${H5_ROUTES:-/,/promotion,/mine,/category,/messages,/seckill,/product/p-1001,/consult,/order-confirm,/orders,/favorites/products,/favorites/shops,/member,/promotion/products,/promotion/commission,/promotion/card,/promotion/level,/promotion/benefits,/promotion/activities,/promotion/rank-center,/promotion/ranking,/promotion/ranking/sales,/promotion/ranking/amount}"
REGISTER_RELEASE="${REGISTER_RELEASE:-true}"
PROMOTE_RELEASE="${PROMOTE_RELEASE:-false}"
INSTALL_NGINX="${INSTALL_NGINX:-true}"
RUN_REMOTE_SMOKE="${RUN_REMOTE_SMOKE:-true}"
SYNC_WORKSPACE="${SYNC_WORKSPACE:-true}"

SSH_KEY="${SSH_KEY:-}"
SERVER_PASSWORD="${SERVER_PASSWORD:-}"
SYNC_DIR=""

normalize_path() {
  local value="$1"
  if [ -z "${value}" ] || [ "${value}" = "/" ]; then
    printf "/"
    return
  fi
  value="${value#/}"
  value="${value%/}"
  printf "/%s" "${value}"
}

safe_slug() {
  printf "%s" "$1" | tr -c 'A-Za-z0-9_.-' '-'
}

H5_BASE_PATH="$(normalize_path "${H5_BASE_PATH}")"
SAFE_VERSION="$(safe_slug "${H5_VERSION}")"
if [ -z "${H5_CONTAINER}" ]; then
  H5_CONTAINER="meu-mall-h5-${SAFE_VERSION}"
fi

cleanup_local() {
  if [ -n "${SYNC_DIR}" ] && [ -d "${SYNC_DIR}" ]; then
    rm -rf "${SYNC_DIR}"
  fi
}
trap cleanup_local EXIT

print_summary() {
  cat <<SUMMARY
== Meu Mall H5 version deploy ==
Remote:       ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}
Path:         ${REMOTE_PATH}
Domain:       ${DOMAIN}
Package:      ${PACKAGE_VERSION}
Version:      ${H5_VERSION}
Git ref:      ${GIT_REF}
Git commit:   ${GIT_COMMIT_SHORT} (${GIT_TREE_STATE})
Git tag:      ${GIT_TAG:-missing}
Rollback:     ${ROLLBACK_VERSION}
Base path:    ${H5_BASE_PATH}
Image:        ${H5_IMAGE}
Container:    ${H5_CONTAINER}
Host port:    ${H5_HOST_PORT:-auto}
Register:     ${REGISTER_RELEASE}
Promote:      ${PROMOTE_RELEASE}
CDN asset:    ${NEXT_PUBLIC_H5_ASSET_BASE_URL:-none}
SUMMARY
}

if [ "${DRY_RUN}" = "true" ]; then
  print_summary
  echo "Dry run only; no SSH, Docker, Nginx, or release API changes."
  exit 0
fi

if [ -z "${SSH_KEY}" ] && [ -z "${SERVER_PASSWORD}" ]; then
  printf "SSH user [%s]: " "${REMOTE_USER}"
  read -r input_user
  if [ -n "${input_user}" ]; then
    REMOTE_USER="${input_user}"
  fi

  printf "Password for %s@%s: " "${REMOTE_USER}" "${REMOTE_HOST}"
  stty -echo
  read -r SERVER_PASSWORD
  stty echo
  printf "\n"
fi

if [ -z "${SSH_KEY}" ] && [ -z "${SERVER_PASSWORD}" ]; then
  echo "Missing password. Set SERVER_PASSWORD or SSH_KEY, or enter the password when prompted." >&2
  exit 2
fi

SSH_TARGET="${REMOTE_USER}@${REMOTE_HOST}"
SSH_BASE_OPTS=(-p "${REMOTE_PORT}" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="${HOME}/.ssh/known_hosts")
if [ -n "${SSH_KEY}" ]; then
  SSH_BASE_OPTS=(-i "${SSH_KEY}" "${SSH_BASE_OPTS[@]}")
fi

expect_password() {
  expect <<'EXPECT'
set timeout -1
set password $env(SERVER_PASSWORD)
set command $env(EXPECT_COMMAND)
spawn sh -lc $command
expect {
  -re "(?i)are you sure you want to continue connecting" {
    send "yes\r"
    exp_continue
  }
  -re "(?i)password:" {
    send "$password\r"
    exp_continue
  }
  eof {
    catch wait result
    exit [lindex $result 3]
  }
}
EXPECT
}

run_ssh() {
  local remote_command="$1"

  if [ -n "${SSH_KEY}" ]; then
    ssh "${SSH_BASE_OPTS[@]}" "${SSH_TARGET}" "${remote_command}"
    return $?
  fi

  EXPECT_COMMAND="$(printf 'ssh %q %q %q %q %q %q' \
    "-p" "${REMOTE_PORT}" "-o" "StrictHostKeyChecking=accept-new" "${SSH_TARGET}" "${remote_command}")" \
    SERVER_PASSWORD="${SERVER_PASSWORD}" \
    expect_password
}

copy_file_if_exists() {
  local source_path="$1"
  local target_path="$2"

  if [ -f "${ROOT_DIR}/${source_path}" ]; then
    mkdir -p "${SYNC_DIR}/$(dirname "${target_path}")"
    cp "${ROOT_DIR}/${source_path}" "${SYNC_DIR}/${target_path}"
  fi
}

copy_dir_if_exists() {
  local source_path="$1"
  local target_path="$2"

  if [ -d "${ROOT_DIR}/${source_path}" ]; then
    mkdir -p "${SYNC_DIR}/$(dirname "${target_path}")"
    rsync -a --delete \
      --exclude=node_modules \
      --exclude=.next \
      --exclude=dist \
      --exclude=.venv \
      --exclude=.pytest_cache \
      --exclude=__pycache__ \
      --exclude=.DS_Store \
      --exclude='*.log' \
      "${ROOT_DIR}/${source_path}/" \
      "${SYNC_DIR}/${target_path}/"
  fi
}

prepare_sync_bundle() {
  SYNC_DIR="$(mktemp -d)"

  copy_file_if_exists ".dockerignore" ".dockerignore"
  copy_dir_if_exists "deploy/docker" "deploy/docker"
  copy_dir_if_exists "deploy/nginx" "deploy/nginx"

  copy_file_if_exists "hybird-meumall/package.json" "hybird-meumall/package.json"
  copy_file_if_exists "hybird-meumall/pnpm-lock.yaml" "hybird-meumall/pnpm-lock.yaml"
  copy_file_if_exists "hybird-meumall/next.config.ts" "hybird-meumall/next.config.ts"
  copy_file_if_exists "hybird-meumall/next-env.d.ts" "hybird-meumall/next-env.d.ts"
  copy_file_if_exists "hybird-meumall/tsconfig.json" "hybird-meumall/tsconfig.json"
  copy_file_if_exists "hybird-meumall/tailwind.config.ts" "hybird-meumall/tailwind.config.ts"
  copy_file_if_exists "hybird-meumall/postcss.config.js" "hybird-meumall/postcss.config.js"
  copy_file_if_exists "hybird-meumall/eslint.config.mjs" "hybird-meumall/eslint.config.mjs"
  copy_file_if_exists "hybird-meumall/vitest.config.ts" "hybird-meumall/vitest.config.ts"
  copy_dir_if_exists "hybird-meumall/public" "hybird-meumall/public"
  copy_dir_if_exists "hybird-meumall/src" "hybird-meumall/src"
}

run_rsync() {
  local rsync_command

  prepare_sync_bundle

  rsync_command="$(
    printf 'rsync -az --delete %s %q %q' \
      "--exclude=/runtime --exclude=/data --exclude=/releases --exclude=.DS_Store --exclude=*.log -e \"ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=accept-new\"" \
      "${SYNC_DIR}/" \
      "${SSH_TARGET}:${REMOTE_PATH}/"
  )"

  if [ -n "${SSH_KEY}" ]; then
    rsync_command="$(
      printf 'rsync -az --delete %s %q %q' \
        "--exclude=/runtime --exclude=/data --exclude=/releases --exclude=.DS_Store --exclude=*.log -e \"ssh -i ${SSH_KEY} -p ${REMOTE_PORT} -o StrictHostKeyChecking=accept-new\"" \
        "${SYNC_DIR}/" \
        "${SSH_TARGET}:${REMOTE_PATH}/"
    )"
  fi

  EXPECT_COMMAND="${rsync_command}" SERVER_PASSWORD="${SERVER_PASSWORD}" expect_password
}

remote_deploy_command() {
  cat <<REMOTE
set -euo pipefail
cd '${REMOTE_PATH}'
mkdir -p 'runtime/h5-versions' 'releases/h5/${H5_VERSION}'

port_in_use() {
  local port="\$1"
  if docker ps --format '{{.Ports}}' | grep -q "127.0.0.1:\${port}->"; then
    return 0
  fi
  if command -v ss >/dev/null 2>&1 && ss -ltn | awk '{print \$4}' | grep -Eq "[:.]\${port}\$"; then
    return 0
  fi
  if command -v netstat >/dev/null 2>&1 && netstat -ltn | awk '{print \$4}' | grep -Eq "[:.]\${port}\$"; then
    return 0
  fi
  return 1
}

selected_port='${H5_HOST_PORT}'
if [ -z "\${selected_port}" ]; then
  for candidate_port in \$(seq 3200 3299); do
    if ! port_in_use "\${candidate_port}"; then
      selected_port="\${candidate_port}"
      break
    fi
  done
fi
if [ -z "\${selected_port}" ]; then
  echo 'No free H5 host port found in 3200-3299.' >&2
  exit 31
fi

docker build \
  -f deploy/docker/h5.Dockerfile \
  --build-arg H5_BASE_PATH='${H5_BASE_PATH}' \
  --build-arg H5_ASSET_PREFIX='${H5_ASSET_PREFIX}' \
  --build-arg H5_VERSION='${H5_VERSION}' \
  --build-arg H5_RELEASE_LABEL='${H5_RELEASE_LABEL}' \
  --build-arg NEXT_PUBLIC_H5_ASSET_BASE_URL='${NEXT_PUBLIC_H5_ASSET_BASE_URL}' \
  --build-arg NEXT_PUBLIC_CONFIG_API_BASE_URL='/' \
  --build-arg NEXT_PUBLIC_H5_MANIFEST_URL='/api/h5/manifest/active?environment=prod' \
  --build-arg H5_MANIFEST_URL='http://127.0.0.1:4100/api/h5/manifest/active?environment=prod' \
  -t '${H5_IMAGE}' \
  .

docker rm -f '${H5_CONTAINER}' >/dev/null 2>&1 || true
docker run -d \
  --name '${H5_CONTAINER}' \
  --restart unless-stopped \
  -e PORT=3109 \
  -e HOSTNAME=0.0.0.0 \
  -e H5_VERSION='${H5_VERSION}' \
  -e H5_RELEASE_LABEL='${H5_RELEASE_LABEL}' \
  -e H5_RELEASE_VARIANT='${H5_RELEASE_VARIANT}' \
  -p "127.0.0.1:\${selected_port}:3109" \
  '${H5_IMAGE}' >/dev/null

for attempt in \$(seq 1 30); do
  if curl -fsS --max-time 5 "http://127.0.0.1:\${selected_port}${H5_BASE_PATH}/api/health" >/dev/null; then
    break
  fi
  if [ "\${attempt}" = "30" ]; then
    docker logs '${H5_CONTAINER}' >&2 || true
    echo 'H5 version container health check failed.' >&2
    exit 32
  fi
  sleep 2
done

cat > 'releases/h5/${H5_VERSION}/runtime.json' <<RUNTIME
{
  "version": "${H5_VERSION}",
  "image": "${H5_IMAGE}",
  "container": "${H5_CONTAINER}",
  "hostPort": "\${selected_port}",
  "basePath": "${H5_BASE_PATH}",
  "domain": "${DOMAIN}",
  "releaseLabel": "${H5_RELEASE_LABEL}",
  "assetBaseUrl": "${NEXT_PUBLIC_H5_ASSET_BASE_URL}",
  "packageVersion": "${PACKAGE_VERSION}",
  "gitRef": "${GIT_REF}",
  "gitCommit": "${GIT_COMMIT_SHA}",
  "gitTag": "${GIT_TAG}",
  "gitTreeState": "${GIT_TREE_STATE}"
}
RUNTIME

echo "\${selected_port}" > 'releases/h5/${H5_VERSION}/host-port.txt'
echo "H5 version container is running on 127.0.0.1:\${selected_port}"
REMOTE
}

remote_nginx_command() {
  cat <<REMOTE
set -euo pipefail
cd '${REMOTE_PATH}'
selected_port="\$(cat 'releases/h5/${H5_VERSION}/host-port.txt')"

write_snippet() {
  local dir="\$1"
  mkdir -p "\${dir}"
  {
    printf '%s\n' 'location = ${H5_BASE_PATH} {'
    printf '%s\n' '  proxy_set_header Upgrade \$http_upgrade;'
    printf '%s\n' '  proxy_set_header Connection "upgrade";'
    printf '%s\n' "  proxy_pass http://127.0.0.1:\${selected_port};"
    printf '%s\n' '}'
    printf '%s\n' 'location ^~ ${H5_BASE_PATH}/ {'
    printf '%s\n' '  proxy_set_header Upgrade \$http_upgrade;'
    printf '%s\n' '  proxy_set_header Connection "upgrade";'
    printf '%s\n' "  proxy_pass http://127.0.0.1:\${selected_port};"
    printf '%s\n' '}'
  } > "\${dir}/${SAFE_VERSION}.conf"
}

if command -v nginx >/dev/null 2>&1; then
  mkdir -p /etc/nginx/conf.d/meu-mall-h5-versions
  cp '${REMOTE_PATH}/deploy/nginx/hybird.aigcpop.com.conf' '/etc/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf'
  write_snippet /etc/nginx/conf.d/meu-mall-h5-versions
  nginx -t
  nginx -s reload || systemctl reload nginx || service nginx reload
else
  echo 'nginx command not found on host; skipped host nginx reload.' >&2
fi

if docker ps --format '{{.Names}}' | grep -qx 'mall4j-nginx' && [ -d '/opt/mail4j/nginx/conf.d' ]; then
  mkdir -p /opt/mail4j/nginx/conf.d/meu-mall-h5-versions
  cp '${REMOTE_PATH}/deploy/nginx/hybird.aigcpop.com.ssl.conf' '/opt/mail4j/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf'
  write_snippet /opt/mail4j/nginx/conf.d/meu-mall-h5-versions
  docker exec mall4j-nginx nginx -t
  docker exec mall4j-nginx nginx -s reload
else
  echo 'mall4j-nginx HTTPS entry not found; skipped HTTPS version location install.' >&2
fi
REMOTE
}

remote_smoke_command() {
  cat <<REMOTE
set -euo pipefail
for attempt in \$(seq 1 15); do
  if curl -fsS --max-time 10 -H 'Host: ${DOMAIN}' 'http://127.0.0.1${H5_BASE_PATH}/api/health' >/dev/null &&
     curl -fsS --max-time 10 -H 'Host: ${DOMAIN}' 'http://127.0.0.1${H5_BASE_PATH}/' >/dev/null &&
     curl -kfsS --max-time 10 'https://${DOMAIN}${H5_BASE_PATH}/api/health' >/dev/null &&
     curl -kfsS --max-time 10 'https://${DOMAIN}${H5_BASE_PATH}/' >/dev/null; then
    echo 'version smoke passed'
    exit 0
  fi
  sleep 2
done
echo 'version smoke failed' >&2
exit 33
REMOTE
}

register_release() {
  local release_dir="${ROOT_DIR}/hybird-meumall/archives/releases/${H5_VERSION}"
  local payload_path="${release_dir}/release-registration.json"
  local response_path="${release_dir}/release-registration-response.json"
  local promote_path="${release_dir}/release-promote-response.json"
  local register_args=()

  mkdir -p "${release_dir}"
  register_args=(
    "--version" "${H5_VERSION}"
    "--environment" "prod"
    "--service-base-url" "https://${DOMAIN}"
    "--base-path" "${H5_BASE_PATH}"
    "--rollback-version" "${ROLLBACK_VERSION}"
    "--routes" "${H5_ROUTES}"
    "--rollout-percentage" "0"
    "--git-commit" "${GIT_COMMIT_SHA}"
    "--git-ref" "${GIT_REF}"
    "--package-version" "${PACKAGE_VERSION}"
    "--commit-subject" "${GIT_COMMIT_SUBJECT}"
    "--docker-image" "${H5_IMAGE}"
    "--container" "${H5_CONTAINER}"
    "--server-url" "${SERVER_URL}"
    "--output" "archives/releases/${H5_VERSION}/release-registration.json"
  )
  if [ -n "${BUILD_NUMBER:-}" ]; then
    register_args+=("--jenkins-build-number" "${BUILD_NUMBER}")
  fi
  if [ -n "${GIT_TAG}" ]; then
    register_args+=("--git-tag" "${GIT_TAG}")
  fi
  if [ -n "${NEXT_PUBLIC_H5_ASSET_BASE_URL}" ]; then
    register_args+=("--public-asset-base-url" "${NEXT_PUBLIC_H5_ASSET_BASE_URL}")
  fi

  (
    cd "${ROOT_DIR}/hybird-meumall"
    pnpm run ai:register-release "${register_args[@]}"
  )

  RELEASE_PAYLOAD_PATH="${payload_path}" \
  RELEASE_RESPONSE_PATH="${response_path}" \
  RELEASE_PROMOTE_PATH="${promote_path}" \
  RELEASE_ENDPOINT="${SERVER_URL%/}/api/releases" \
  PROMOTE_RELEASE="${PROMOTE_RELEASE}" \
  python3 <<'PY'
import json
import os
import urllib.request

payload_path = os.environ["RELEASE_PAYLOAD_PATH"]
response_path = os.environ["RELEASE_RESPONSE_PATH"]
promote_path = os.environ["RELEASE_PROMOTE_PATH"]
endpoint = os.environ["RELEASE_ENDPOINT"]
promote = os.environ.get("PROMOTE_RELEASE") == "true"

with open(payload_path, "rb") as handle:
    payload = handle.read()

request = urllib.request.Request(
    endpoint,
    data=payload,
    headers={"Content-Type": "application/json", "Accept": "application/json"},
    method="POST",
)
with urllib.request.urlopen(request, timeout=20) as response:
    created = json.loads(response.read().decode("utf-8"))

with open(response_path, "w", encoding="utf-8") as handle:
    json.dump(created, handle, ensure_ascii=False, indent=2)
    handle.write("\n")

print(f"registered release: {created.get('id')} {created.get('version')} {created.get('status')}")

if promote:
    promote_url = f"{endpoint.rstrip('/')}/{created['id']}/promote"
    promote_request = urllib.request.Request(
        promote_url,
        data=b"",
        headers={"Accept": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(promote_request, timeout=20) as response:
        promoted = json.loads(response.read().decode("utf-8"))
    with open(promote_path, "w", encoding="utf-8") as handle:
        json.dump(promoted, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(f"promoted release: {promoted.get('id')} {promoted.get('version')} {promoted.get('status')}")
PY
}

print_summary

if [ "${SYNC_WORKSPACE}" = "true" ]; then
  echo "== Sync H5 build context =="
  run_rsync
fi

echo "== Build and start H5 version container =="
run_ssh "$(remote_deploy_command)"

if [ "${INSTALL_NGINX}" = "true" ]; then
  echo "== Install version Nginx location =="
  run_ssh "$(remote_nginx_command)"
else
  echo "== Skip Nginx location install =="
fi

if [ "${RUN_REMOTE_SMOKE}" = "true" ]; then
  echo "== Remote version smoke =="
  run_ssh "$(remote_smoke_command)"
fi

if [ "${REGISTER_RELEASE}" = "true" ]; then
  echo "== Register release =="
  register_release
else
  echo "== Skip release registration =="
fi

echo "H5 version deploy complete: https://${DOMAIN}${H5_BASE_PATH}/"
