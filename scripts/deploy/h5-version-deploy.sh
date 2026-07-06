#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
H5_SOURCE_DIR="${H5_SOURCE_DIR:-${ROOT_DIR}/hybird-meumall}"

REMOTE_HOST="${REMOTE_HOST:-8.163.107.208}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_PATH="${REMOTE_PATH:-/opt/mail4j/meu-mall}"
DOMAIN="${DOMAIN:-hybird.aigcpop.com}"
SERVER_URL="${SERVER_URL:-https://${DOMAIN}}"
DRY_RUN="${DRY_RUN:-false}"
H5_RELEASE_ENV="${H5_RELEASE_ENV:-prod}"
H5_RUNTIME_ENV_FILE="${H5_RUNTIME_ENV_FILE:-${H5_SOURCE_DIR}/config/env/h5.${H5_RELEASE_ENV}.env}"
REGISTER_RESOLVER_PORT="${REGISTER_RESOLVER_PORT:-4110}"
REGISTER_RESOLVER_CONTAINER="${REGISTER_RESOLVER_CONTAINER:-meu-mall-register-resolver}"
INSTALL_REGISTER_RESOLVER="${INSTALL_REGISTER_RESOLVER:-true}"

read_h5_env_value() {
  local key="$1"
  if [ ! -f "${H5_RUNTIME_ENV_FILE}" ]; then
    return 0
  fi

  (
    set -a
    # shellcheck disable=SC1090
    . "${H5_RUNTIME_ENV_FILE}"
    set +a
    eval 'printf "%s" "${'"${key}"':-}"'
  )
}

PROFILE_JAVA_H5_RELEASE_API_BASE_URL="$(read_h5_env_value JAVA_H5_RELEASE_API_BASE_URL)"
PROFILE_JAVA_H5_RELEASE_REGISTER_API_BASE_URL="$(read_h5_env_value JAVA_H5_RELEASE_REGISTER_API_BASE_URL)"

JAVA_API_BASE_URL="${JAVA_API_BASE_URL:-$(read_h5_env_value JAVA_API_BASE_URL)}"
JAVA_H5_RELEASE_API_BASE_URL="${JAVA_H5_RELEASE_API_BASE_URL:-${JAVA_RELEASE_SERVER_URL:-${JAVA_H5_RELEASE_ADMIN_API_BASE_URL:-${PROFILE_JAVA_H5_RELEASE_API_BASE_URL}}}}"
JAVA_H5_RELEASE_REGISTER_API_BASE_URL="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL:-${JAVA_RELEASE_REGISTER_SERVER_URL:-${JAVA_H5_RELEASE_ADMIN_API_BASE_URL:-${PROFILE_JAVA_H5_RELEASE_REGISTER_API_BASE_URL:-${JAVA_H5_RELEASE_API_BASE_URL:-}}}}}"
JAVA_H5_RELEASE_TOKEN="${JAVA_H5_RELEASE_TOKEN:-${JAVA_RELEASE_TOKEN:-}}"
JAVA_H5_RELEASE_REGISTER_TOKEN="${JAVA_H5_RELEASE_REGISTER_TOKEN:-${JAVA_RELEASE_REGISTER_TOKEN:-${JAVA_H5_RELEASE_TOKEN}}}"

assert_java_h5_release_base_url() {
  local name="$1"
  local value="$2"

  if [ -z "${value}" ]; then
    echo "${name} 不能为空；H5 版本管理必须显式配置 Java 管理系统接口前缀。" >&2
    exit 2
  fi

  case "${value}" in
    *"/api/h5/manifest"*|*"/api/releases"*|*"/mini_h5"*)
      {
        echo "${name} 指向了旧 Python manifest/release 或 Java 业务接口，不允许用于 H5 版本管理。"
        echo "${name}: ${value}"
        echo "请配置 Java 管理系统前缀，例如：https://test.aigcpop.com:18088/apis"
      } >&2
      exit 2
      ;;
  esac
}

if [ -z "${JAVA_H5_RELEASE_API_BASE_URL}" ]; then
  echo "JAVA_H5_RELEASE_API_BASE_URL 不能为空；请配置 H5 版本管理 active manifest 前缀。" >&2
  exit 2
fi
if [ "${REGISTER_RELEASE:-true}" = "true" ] && [ -z "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL}" ]; then
  echo "JAVA_H5_RELEASE_REGISTER_API_BASE_URL 不能为空；注册 H5 版本记录需要管理系统接口前缀。" >&2
  exit 2
fi

assert_java_h5_release_base_url "JAVA_H5_RELEASE_API_BASE_URL" "${JAVA_H5_RELEASE_API_BASE_URL}"
if [ "${REGISTER_RELEASE:-true}" = "true" ]; then
  assert_java_h5_release_base_url "JAVA_H5_RELEASE_REGISTER_API_BASE_URL" "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL}"
fi

PUBLIC_H5_MANIFEST_URL="${PUBLIC_H5_MANIFEST_URL:-${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active}"
SERVER_H5_MANIFEST_URL="${SERVER_H5_MANIFEST_URL:-${PUBLIC_H5_MANIFEST_URL}}"
REQUIRE_EXISTING_TAG="${REQUIRE_EXISTING_TAG:-true}"
PUSH_TAG_AFTER_RELEASE="${PUSH_TAG_AFTER_RELEASE:-false}"
CLEAN_OLD_REMOTE_RELEASES="${CLEAN_OLD_REMOTE_RELEASES:-false}"
REMOTE_KEEP_RELEASES="${REMOTE_KEEP_RELEASES:-1}"
ALLOW_INITIAL_H5_RELEASE="${ALLOW_INITIAL_H5_RELEASE:-false}"

read_package_version() {
  node -e '
const packageJson = require(process.argv[1]);
if (!packageJson.version) process.exit(2);
process.stdout.write(packageJson.version);
' "${H5_SOURCE_DIR}/package.json"
}

discover_h5_routes() {
  node - "${H5_SOURCE_DIR}" <<'NODE'
const fs = require("fs");
const path = require("path");

const h5SourceDir = process.argv[2];
const appDir = path.join(h5SourceDir, "src/app");
const pageFilePattern = /^page\.(js|jsx|ts|tsx|mdx)$/;
const routes = new Set();

function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      walk(fullPath);
      continue;
    }
    if (!entry.isFile() || !pageFilePattern.test(entry.name)) {
      continue;
    }

    const routeDir = path.dirname(path.relative(appDir, fullPath));
    const segments = routeDir === "." ? [] : routeDir.split(path.sep).filter((segment) => {
      return segment && segment !== "api" && !segment.startsWith("(") && !segment.startsWith("_");
    });
    if (segments.includes("api")) {
      continue;
    }

    routes.add(segments.length === 0 ? "/" : `/${segments.join("/")}`);
  }
}

if (!fs.existsSync(appDir) || !fs.statSync(appDir).isDirectory()) {
  process.exit(2);
}

walk(appDir);
process.stdout.write(Array.from(routes).sort((left, right) => {
  if (left === "/") return -1;
  if (right === "/") return 1;
  return left.localeCompare(right);
}).join(","));
NODE
}

resolve_git_commit() {
  local git_ref="$1"
  git -C "${H5_SOURCE_DIR}" rev-parse "${git_ref}^{commit}" 2>/dev/null
}

active_manifest_stable_version() {
  local manifest_url="${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active"
  JAVA_H5_RELEASE_TOKEN="${JAVA_H5_RELEASE_TOKEN}" python3 - "${manifest_url}" <<'PY'
import json
import os
import sys
import urllib.request

url = sys.argv[1]
headers = {"Accept": "application/json"}
token = os.environ.get("JAVA_H5_RELEASE_TOKEN")
if token:
    headers["Authorization"] = token
request = urllib.request.Request(url, headers=headers, method="GET")
try:
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.loads(response.read().decode("utf-8"))
except Exception:
    sys.exit(0)

manifest = payload.get("data") if isinstance(payload, dict) and payload.get("data") is not None else payload
if isinstance(manifest, str):
    try:
        manifest = json.loads(manifest)
    except Exception:
        manifest = {}
stable_version = manifest.get("stableVersion") if isinstance(manifest, dict) else None
if stable_version:
    print(stable_version)
PY
}

PACKAGE_VERSION="$(read_package_version || true)"
if [ -z "${PACKAGE_VERSION}" ] && [ -z "${H5_VERSION:-}" ]; then
  echo "hybird-meumall/package.json 必须声明 version，发布版本由该字段生成。" >&2
  exit 2
fi
if [ -n "${PACKAGE_VERSION}" ] && [[ ! "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "package.json version 必须是 npm 语义化版本，例如 1.0.1。当前值：${PACKAGE_VERSION}" >&2
  exit 2
fi

H5_VERSION="${H5_VERSION:-v${PACKAGE_VERSION}}"
if [[ ! "${H5_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "H5_VERSION 必须是 vX.Y.Z 格式，例如 v1.0.15。当前值：${H5_VERSION}" >&2
  exit 2
fi
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

CURRENT_HEAD_SHA="$(git -C "${H5_SOURCE_DIR}" rev-parse HEAD)"
if [ "${CURRENT_HEAD_SHA}" != "${GIT_COMMIT_SHA}" ]; then
  echo "当前 hybird-meumall HEAD 与 GIT_REF 不一致，不能发布。" >&2
  echo "HEAD:    ${CURRENT_HEAD_SHA}" >&2
  echo "GIT_REF: ${GIT_REF} -> ${GIT_COMMIT_SHA}" >&2
  exit 2
fi

GIT_TREE_STATE="clean"
if [ -n "$(git -C "${H5_SOURCE_DIR}" status --porcelain)" ]; then
  GIT_TREE_STATE="dirty"
  if [ "${DRY_RUN}" != "true" ]; then
    echo "hybird-meumall 存在未提交改动，不能发布。请先提交并创建 ${REQUIRED_GIT_TAG}。" >&2
    exit 2
  fi
fi

GIT_TAG=""
if git -C "${H5_SOURCE_DIR}" tag --points-at "${GIT_COMMIT_SHA}" | grep -qx "${REQUIRED_GIT_TAG}"; then
  GIT_TAG="${REQUIRED_GIT_TAG}"
elif [ "${DRY_RUN}" != "true" ] && [ "${REQUIRE_EXISTING_TAG}" = "true" ]; then
  echo "提交 ${GIT_COMMIT_SHA} 缺少版本 tag：${REQUIRED_GIT_TAG}，不能发布。" >&2
  exit 2
fi

GIT_COMMIT_SHORT="$(git -C "${H5_SOURCE_DIR}" rev-parse --short "${GIT_COMMIT_SHA}")"
GIT_BRANCH="$(git -C "${H5_SOURCE_DIR}" rev-parse --abbrev-ref HEAD)"
GIT_COMMIT_SUBJECT="$(git -C "${H5_SOURCE_DIR}" log -1 --pretty=%s "${GIT_COMMIT_SHA}")"
ROLLBACK_VERSION="$(active_manifest_stable_version || true)"
if [ -z "${ROLLBACK_VERSION}" ]; then
  if [ "${ALLOW_INITIAL_H5_RELEASE}" = "true" ]; then
    ROLLBACK_VERSION="${H5_VERSION}"
    echo "Java active manifest 暂不可用，按初始版本使用自身作为 rollbackVersion：${ROLLBACK_VERSION}" >&2
  else
    echo "无法从 Java active manifest 读取 rollbackVersion 来源：${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active" >&2
    exit 2
  fi
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

APP_ENV="${APP_ENV:-$(read_h5_env_value APP_ENV)}"
NEXT_PUBLIC_APP_ENV="${NEXT_PUBLIC_APP_ENV:-$(read_h5_env_value NEXT_PUBLIC_APP_ENV)}"
NEXT_PUBLIC_API_BASE_URL="${NEXT_PUBLIC_API_BASE_URL:-$(read_h5_env_value NEXT_PUBLIC_API_BASE_URL)}"
JAVA_API_BASE_URL="${JAVA_API_BASE_URL:-$(read_h5_env_value JAVA_API_BASE_URL)}"
JAVA_OSS_ASSET_BASE_URL="${JAVA_OSS_ASSET_BASE_URL:-$(read_h5_env_value JAVA_OSS_ASSET_BASE_URL)}"
PYTHON_API_BASE_URL="${PYTHON_API_BASE_URL:-$(read_h5_env_value PYTHON_API_BASE_URL)}"
H5_BFF_LOG_BACKEND_RESPONSE="${H5_BFF_LOG_BACKEND_RESPONSE:-$(read_h5_env_value H5_BFF_LOG_BACKEND_RESPONSE)}"
H5_BFF_BACKEND_RESPONSE_LOG_LIMIT="${H5_BFF_BACKEND_RESPONSE_LOG_LIMIT:-$(read_h5_env_value H5_BFF_BACKEND_RESPONSE_LOG_LIMIT)}"

APP_ENV="${APP_ENV:-prod}"
NEXT_PUBLIC_APP_ENV="${NEXT_PUBLIC_APP_ENV:-${APP_ENV}}"
NEXT_PUBLIC_API_BASE_URL="${NEXT_PUBLIC_API_BASE_URL:-/api/bff}"
H5_BFF_LOG_BACKEND_RESPONSE="${H5_BFF_LOG_BACKEND_RESPONSE:-0}"
H5_BFF_BACKEND_RESPONSE_LOG_LIMIT="${H5_BFF_BACKEND_RESPONSE_LOG_LIMIT:-30000}"

if [ -z "${H5_ROUTES:-}" ]; then
  H5_ROUTES="$(discover_h5_routes)"
  echo "已从 H5 src/app 自动发现 release routes：$(printf '%s' "${H5_ROUTES}" | awk -F',' '{print NF}') 条"
fi
if [ -z "${H5_ROUTES}" ]; then
  echo "H5_ROUTES 不能为空，且未能从 ${H5_SOURCE_DIR}/src/app 自动发现页面路由。" >&2
  exit 2
fi
REGISTER_RELEASE="${REGISTER_RELEASE:-true}"
PROMOTE_RELEASE="${PROMOTE_RELEASE:-false}"
INSTALL_NGINX="${INSTALL_NGINX:-true}"
RUN_REMOTE_SMOKE="${RUN_REMOTE_SMOKE:-true}"
SYNC_WORKSPACE="${SYNC_WORKSPACE:-true}"
SEND_FEISHU_REVIEW="${SEND_FEISHU_REVIEW:-true}"
FEISHU_REVIEW_DRY_RUN="${FEISHU_REVIEW_DRY_RUN:-false}"

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

shell_quote() {
  printf "%q" "$1"
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
H5 source:    ${H5_SOURCE_DIR}
Remote:       ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}
Path:         ${REMOTE_PATH}
Domain:       ${DOMAIN}
Release env:  ${H5_RELEASE_ENV}
Java manifest:${JAVA_H5_RELEASE_API_BASE_URL}
Java register:${JAVA_H5_RELEASE_REGISTER_API_BASE_URL}
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
Feishu review:${SEND_FEISHU_REVIEW}
Feishu dry:   ${FEISHU_REVIEW_DRY_RUN}
Push tag:     ${PUSH_TAG_AFTER_RELEASE}
Remote clean: ${CLEAN_OLD_REMOTE_RELEASES} keep=${REMOTE_KEEP_RELEASES}
Resolver:     ${INSTALL_REGISTER_RESOLVER} ${REGISTER_RESOLVER_CONTAINER}:127.0.0.1:${REGISTER_RESOLVER_PORT}
CDN asset:    ${NEXT_PUBLIC_H5_ASSET_BASE_URL:-none}
H5 env file:  ${H5_RUNTIME_ENV_FILE}
App env:      ${APP_ENV}
Java API:     ${JAVA_API_BASE_URL:-missing}
Python API:   ${PYTHON_API_BASE_URL:-missing}
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

copy_h5_file_if_exists() {
  local source_path="$1"
  local target_path="$2"

  if [ -f "${H5_SOURCE_DIR}/${source_path}" ]; then
    mkdir -p "${SYNC_DIR}/$(dirname "${target_path}")"
    cp "${H5_SOURCE_DIR}/${source_path}" "${SYNC_DIR}/${target_path}"
  fi
}

copy_h5_dir_if_exists() {
  local source_path="$1"
  local target_path="$2"

  if [ -d "${H5_SOURCE_DIR}/${source_path}" ]; then
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
      "${H5_SOURCE_DIR}/${source_path}/" \
      "${SYNC_DIR}/${target_path}/"
  fi
}

prepare_sync_bundle() {
  SYNC_DIR="$(mktemp -d)"

  copy_file_if_exists ".dockerignore" ".dockerignore"
  copy_dir_if_exists "deploy/docker" "deploy/docker"
  copy_dir_if_exists "deploy/nginx" "deploy/nginx"
  copy_dir_if_exists "scripts/register-resolver" "scripts/register-resolver"

  copy_h5_file_if_exists "package.json" "hybird-meumall/package.json"
  copy_h5_file_if_exists "pnpm-lock.yaml" "hybird-meumall/pnpm-lock.yaml"
  copy_h5_file_if_exists "next.config.ts" "hybird-meumall/next.config.ts"
  copy_h5_file_if_exists "next-env.d.ts" "hybird-meumall/next-env.d.ts"
  copy_h5_file_if_exists "tsconfig.json" "hybird-meumall/tsconfig.json"
  copy_h5_file_if_exists "tailwind.config.ts" "hybird-meumall/tailwind.config.ts"
  copy_h5_file_if_exists "postcss.config.js" "hybird-meumall/postcss.config.js"
  copy_h5_file_if_exists "eslint.config.mjs" "hybird-meumall/eslint.config.mjs"
  copy_h5_file_if_exists "vitest.config.ts" "hybird-meumall/vitest.config.ts"
  copy_h5_dir_if_exists "public" "hybird-meumall/public"
  copy_h5_dir_if_exists "src" "hybird-meumall/src"
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
  --build-arg APP_ENV='${APP_ENV}' \
  --build-arg NEXT_PUBLIC_APP_ENV='${NEXT_PUBLIC_APP_ENV}' \
  --build-arg NEXT_PUBLIC_API_BASE_URL='${NEXT_PUBLIC_API_BASE_URL}' \
  --build-arg JAVA_API_BASE_URL='${JAVA_API_BASE_URL}' \
  --build-arg JAVA_OSS_ASSET_BASE_URL='${JAVA_OSS_ASSET_BASE_URL}' \
  --build-arg PYTHON_API_BASE_URL='${PYTHON_API_BASE_URL}' \
  --build-arg H5_BFF_LOG_BACKEND_RESPONSE='${H5_BFF_LOG_BACKEND_RESPONSE}' \
  --build-arg H5_BFF_BACKEND_RESPONSE_LOG_LIMIT='${H5_BFF_BACKEND_RESPONSE_LOG_LIMIT}' \
  --build-arg NEXT_PUBLIC_CONFIG_API_BASE_URL='/' \
  --build-arg NEXT_PUBLIC_H5_MANIFEST_URL='${PUBLIC_H5_MANIFEST_URL}' \
  --build-arg H5_MANIFEST_URL='${SERVER_H5_MANIFEST_URL}' \
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
  -e H5_BASE_PATH='${H5_BASE_PATH}' \
  -e NEXT_PUBLIC_H5_BASE_PATH='${H5_BASE_PATH}' \
  -e APP_ENV='${APP_ENV}' \
  -e NEXT_PUBLIC_APP_ENV='${NEXT_PUBLIC_APP_ENV}' \
  -e NEXT_PUBLIC_API_BASE_URL='${NEXT_PUBLIC_API_BASE_URL}' \
  -e JAVA_API_BASE_URL='${JAVA_API_BASE_URL}' \
  -e JAVA_OSS_ASSET_BASE_URL='${JAVA_OSS_ASSET_BASE_URL}' \
  -e PYTHON_API_BASE_URL='${PYTHON_API_BASE_URL}' \
  -e H5_BFF_LOG_BACKEND_RESPONSE='${H5_BFF_LOG_BACKEND_RESPONSE}' \
  -e H5_BFF_BACKEND_RESPONSE_LOG_LIMIT='${H5_BFF_BACKEND_RESPONSE_LOG_LIMIT}' \
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

remote_register_resolver_command() {
  local q_container q_port q_api_base q_token q_volume
  q_container="$(shell_quote "${REGISTER_RESOLVER_CONTAINER}")"
  q_port="$(shell_quote "${REGISTER_RESOLVER_PORT}")"
  q_api_base="$(shell_quote "${JAVA_H5_RELEASE_API_BASE_URL}")"
  q_token="$(shell_quote "${JAVA_H5_RELEASE_TOKEN}")"
  q_volume="$(shell_quote "${REMOTE_PATH}/scripts/register-resolver:/app:ro")"

  cat <<REMOTE
set -euo pipefail
cd '${REMOTE_PATH}'
if [ ! -f 'scripts/register-resolver/server.js' ]; then
  echo 'Register resolver source is missing: scripts/register-resolver/server.js' >&2
  exit 34
fi

docker rm -f ${q_container} >/dev/null 2>&1 || true
docker run -d \
  --name ${q_container} \
  --restart unless-stopped \
  --network host \
  -e PORT=${q_port} \
  -e REGISTER_ROUTE='/register' \
  -e JAVA_H5_RELEASE_API_BASE_URL=${q_api_base} \
  -e JAVA_H5_RELEASE_TOKEN=${q_token} \
  -v ${q_volume} \
  node:22-alpine \
  node /app/server.js >/dev/null

for attempt in \$(seq 1 15); do
  if curl -fsS --max-time 5 "http://127.0.0.1:${REGISTER_RESOLVER_PORT}/health" >/dev/null; then
    echo 'register resolver health passed'
    exit 0
  fi
  sleep 2
done

docker logs ${q_container} >&2 || true
echo 'Register resolver health check failed.' >&2
exit 35
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
  sed -i "s/127.0.0.1:4110/127.0.0.1:${REGISTER_RESOLVER_PORT}/g" '/etc/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf'
  write_snippet /etc/nginx/conf.d/meu-mall-h5-versions
  nginx -t
  nginx -s reload || systemctl reload nginx || service nginx reload
else
  echo 'nginx command not found on host; skipped host nginx reload.' >&2
fi

if docker ps --format '{{.Names}}' | grep -qx 'mall4j-nginx' && [ -d '/opt/mail4j/nginx/conf.d' ]; then
  mkdir -p /opt/mail4j/nginx/conf.d/meu-mall-h5-versions
  cp '${REMOTE_PATH}/deploy/nginx/hybird.aigcpop.com.ssl.conf' '/opt/mail4j/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf'
  sed -i "s/127.0.0.1:4110/127.0.0.1:${REGISTER_RESOLVER_PORT}/g" '/opt/mail4j/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf'
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
  local release_dir="${H5_SOURCE_DIR}/archives/releases/${H5_VERSION}"
  local payload_path="${release_dir}/release-registration.json"
  local response_path="${release_dir}/release-registration-response.json"
  local promote_path="${release_dir}/release-promote-response.json"
  local register_args=()

  mkdir -p "${release_dir}"
  register_args=(
    "--version" "${H5_VERSION}"
    "--environment" "${H5_RELEASE_ENV}"
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
    "--output" "archives/releases/${H5_VERSION}/release-registration.json"
  )
  if [ -n "${BUILD_NUMBER:-}" ]; then
    register_args+=("--jenkins-build-number" "${BUILD_NUMBER}")
  fi
  if [ -n "${GIT_TAG}" ]; then
    register_args+=("--git-tag" "${GIT_TAG}")
  elif [ "${PUSH_TAG_AFTER_RELEASE}" = "true" ]; then
    register_args+=("--git-tag" "${REQUIRED_GIT_TAG}")
  fi
  if [ -n "${NEXT_PUBLIC_H5_ASSET_BASE_URL}" ]; then
    register_args+=("--public-asset-base-url" "${NEXT_PUBLIC_H5_ASSET_BASE_URL}")
  fi

  (
    cd "${H5_SOURCE_DIR}"
    pnpm run ai:register-release "${register_args[@]}"
  )

  RELEASE_PAYLOAD_PATH="${payload_path}" \
  RELEASE_RESPONSE_PATH="${response_path}" \
  RELEASE_PROMOTE_PATH="${promote_path}" \
  RELEASE_ENDPOINT="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release" \
  JAVA_H5_RELEASE_REGISTER_TOKEN="${JAVA_H5_RELEASE_REGISTER_TOKEN}" \
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
token = os.environ.get("JAVA_H5_RELEASE_REGISTER_TOKEN")

with open(payload_path, "rb") as handle:
    payload = handle.read()

headers = {"Content-Type": "application/json", "Accept": "application/json"}
if token:
    headers["Authorization"] = token
request = urllib.request.Request(
    endpoint,
    data=payload,
    headers=headers,
    method="POST",
)
with urllib.request.urlopen(request, timeout=20) as response:
    body = json.loads(response.read().decode("utf-8"))

with open(response_path, "w", encoding="utf-8") as handle:
    json.dump(body, handle, ensure_ascii=False, indent=2)
    handle.write("\n")

if isinstance(body, dict) and body.get("success") is False:
    raise RuntimeError(f"release register failed: {body.get('msg') or body}")

created = body.get("data") if isinstance(body, dict) and isinstance(body.get("data"), dict) else body
if not isinstance(created, dict) or not created.get("id"):
    raise RuntimeError(f"release register returned invalid payload: {body}")

print(f"registered release: {created.get('id')} {created.get('version')} {created.get('status')}")

if promote:
    promote_url = f"{endpoint.rstrip('/')}/{created['id']}/promote"
    promote_request = urllib.request.Request(
        promote_url,
        data=b"",
        headers={k: v for k, v in headers.items() if k != "Content-Type"},
        method="POST",
    )
    with urllib.request.urlopen(promote_request, timeout=20) as response:
        promoted_body = json.loads(response.read().decode("utf-8"))
    if isinstance(promoted_body, dict) and promoted_body.get("success") is False:
        raise RuntimeError(f"release promote failed: {promoted_body.get('msg') or promoted_body}")
    promoted = promoted_body.get("data") if isinstance(promoted_body, dict) and isinstance(promoted_body.get("data"), dict) else promoted_body
    if not isinstance(promoted, dict) or not promoted.get("id"):
        raise RuntimeError(f"release promote returned invalid payload: {promoted_body}")
    with open(promote_path, "w", encoding="utf-8") as handle:
        json.dump(promoted_body, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(f"promoted release: {promoted.get('id')} {promoted.get('version')} {promoted.get('status')}")
PY
}

send_feishu_release_review() {
  local review_args=(
    "run" "feishu:h5-release-notice" "--" "request-review"
    "--version" "${H5_VERSION}"
    "--git-tag" "${REQUIRED_GIT_TAG}"
  )

  if [ "${FEISHU_REVIEW_DRY_RUN}" = "true" ]; then
    review_args+=("--dry-run")
  fi

  (
    cd "${ROOT_DIR}"
    H5_RELEASE_NOTICE_H5_DIR="${H5_SOURCE_DIR}" \
    H5_RELEASE_ENV="${H5_RELEASE_ENV}" \
    JAVA_H5_RELEASE_API_BASE_URL="${JAVA_H5_RELEASE_API_BASE_URL}" \
    JAVA_H5_RELEASE_REGISTER_API_BASE_URL="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL}" \
    JAVA_H5_RELEASE_TOKEN="${JAVA_H5_RELEASE_TOKEN}" \
    JAVA_H5_RELEASE_REGISTER_TOKEN="${JAVA_H5_RELEASE_REGISTER_TOKEN}" \
      pnpm "${review_args[@]}"
  )
}

push_git_tag_after_release() {
  local tag_name="${REQUIRED_GIT_TAG}"
  local remote_url

  if git -C "${H5_SOURCE_DIR}" rev-parse -q --verify "refs/tags/${tag_name}" >/dev/null; then
    local existing_commit
    existing_commit="$(git -C "${H5_SOURCE_DIR}" rev-list -n 1 "${tag_name}")"
    if [ "${existing_commit}" != "${GIT_COMMIT_SHA}" ]; then
      echo "Tag ${tag_name} 已存在，但指向 ${existing_commit}，不是本次提交 ${GIT_COMMIT_SHA}。" >&2
      exit 2
    fi
  else
    git -C "${H5_SOURCE_DIR}" tag "${tag_name}" "${GIT_COMMIT_SHA}"
  fi

  remote_url="$(git -C "${H5_SOURCE_DIR}" config --get remote.origin.url || true)"
  if [ -z "${remote_url}" ]; then
    echo "H5 仓库没有 remote.origin.url，无法推送 tag ${tag_name}。" >&2
    exit 2
  fi

  if git -C "${H5_SOURCE_DIR}" ls-remote --exit-code --tags origin "refs/tags/${tag_name}" >/dev/null 2>&1; then
    local remote_commit
    remote_commit="$(git -C "${H5_SOURCE_DIR}" ls-remote --tags origin "refs/tags/${tag_name}" | awk '{print $1}' | head -1)"
    if [ "${remote_commit}" != "${GIT_COMMIT_SHA}" ]; then
      echo "远程 tag ${tag_name} 已存在，但指向 ${remote_commit}，不是本次提交 ${GIT_COMMIT_SHA}。" >&2
      exit 2
    fi
    echo "Tag already exists on origin: ${tag_name}"
    return
  fi

  git -C "${H5_SOURCE_DIR}" push origin "${tag_name}"
}

remote_cleanup_command() {
  cat <<REMOTE
set -euo pipefail
keep='${REMOTE_KEEP_RELEASES}'
if ! printf '%s' "\${keep}" | grep -Eq '^[0-9]+$' || [ "\${keep}" -lt 1 ]; then
  keep=1
fi
cd '${REMOTE_PATH}'

current_container='${H5_CONTAINER}'
current_image='${H5_IMAGE}'
current_version='${H5_VERSION}'
current_snippet='${SAFE_VERSION}.conf'

keep_versions="\$(find releases/h5 -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V | tail -n "\${keep}" || true)"
if ! printf '%s\n' "\${keep_versions}" | grep -qx "\${current_version}"; then
  keep_versions="\$(printf '%s\n%s\n' "\${keep_versions}" "\${current_version}" | sed '/^$/d' | sort -uV)"
fi

is_kept_version() {
  printf '%s\n' "\${keep_versions}" | grep -qx "\$1"
}

echo "Keeping H5 versions:"
printf '%s\n' "\${keep_versions}"

docker ps -a --format '{{.Names}}' | grep '^meu-mall-h5-' | while read -r name; do
  version="\${name#meu-mall-h5-}"
  if ! is_kept_version "\${version}"; then
    docker rm -f "\${name}" >/dev/null 2>&1 || true
  fi
done

docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | awk '\$1 ~ /^meu-mall\\/h5:/ {print \$1}' | while read -r image; do
  version="\${image#meu-mall/h5:}"
  if ! is_kept_version "\${version}"; then
    docker rmi "\${image}" >/dev/null 2>&1 || true
  fi
done

find releases/h5 -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
  version="\$(basename "\${dir}")"
  if ! is_kept_version "\${version}"; then
    rm -rf "\${dir}"
  fi
done

for dir in /etc/nginx/conf.d/meu-mall-h5-versions /opt/mail4j/nginx/conf.d/meu-mall-h5-versions; do
  if [ -d "\${dir}" ]; then
    find "\${dir}" -maxdepth 1 -type f -name '*.conf' | while read -r file; do
      version="\$(basename "\${file}" .conf)"
      if ! is_kept_version "\${version}"; then
        rm -f "\${file}"
      fi
    done
  fi
done

if docker ps --format '{{.Names}}' | grep -qx 'mall4j-nginx'; then
  docker exec mall4j-nginx nginx -t
  docker exec mall4j-nginx nginx -s reload
elif command -v nginx >/dev/null 2>&1; then
  nginx -t
  nginx -s reload || systemctl reload nginx || service nginx reload
fi
REMOTE
}

print_summary

if [ "${SYNC_WORKSPACE}" = "true" ]; then
  echo "== Sync H5 build context =="
  run_rsync
fi

echo "== Build and start H5 version container =="
run_ssh "$(remote_deploy_command)"

if [ "${INSTALL_REGISTER_RESOLVER}" = "true" ]; then
  echo "== Start register resolver =="
  run_ssh "$(remote_register_resolver_command)"
else
  echo "== Skip register resolver =="
fi

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

if [ "${PUSH_TAG_AFTER_RELEASE}" = "true" ]; then
  echo "== Push H5 git tag =="
  push_git_tag_after_release
else
  echo "== Skip H5 git tag push =="
fi

if [ "${CLEAN_OLD_REMOTE_RELEASES}" = "true" ]; then
  echo "== Clean old remote H5 releases =="
  run_ssh "$(remote_cleanup_command)"
else
  echo "== Skip old remote H5 release cleanup =="
fi

if [ "${SEND_FEISHU_REVIEW}" = "true" ]; then
  echo "== Send Feishu release review =="
  send_feishu_release_review
else
  echo "== Skip Feishu release review =="
fi

echo "H5 version deploy complete: https://${DOMAIN}${H5_BASE_PATH}/"
