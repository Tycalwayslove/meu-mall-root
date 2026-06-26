#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_HOME="${CI_HOME:-${ROOT_DIR}/meumall-ci}"
CONFIG_FILE="${H5_TEST_RELEASE_CONFIG:-${CI_HOME}/config/h5-test-release.env}"

if [ ! -f "${CONFIG_FILE}" ]; then
  echo "缺少 H5 测试发版配置：${CONFIG_FILE}" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "${CONFIG_FILE}"
set +a

WORKSPACE_DIR="${H5_RELEASE_WORKSPACE_DIR:-${CI_HOME}/workspaces/h5-release}"
H5_GIT_URL="${H5_GIT_URL:-git@github.com:Tycalwayslove/hybird-meumall.git}"
H5_GIT_BRANCH="${H5_GIT_BRANCH:-main}"
H5_RELEASE_ENV="${H5_RELEASE_ENV:-test}"
PROMOTE_RELEASE="${PROMOTE_RELEASE:-false}"
REGISTER_RELEASE="${REGISTER_RELEASE:-true}"
SEND_FEISHU_REVIEW="${SEND_FEISHU_REVIEW:-false}"
FEISHU_REVIEW_DRY_RUN="${FEISHU_REVIEW_DRY_RUN:-true}"
PUSH_TAG_AFTER_RELEASE="${PUSH_TAG_AFTER_RELEASE:-true}"
CLEAN_OLD_REMOTE_RELEASES="${CLEAN_OLD_REMOTE_RELEASES:-true}"
REMOTE_KEEP_RELEASES="${REMOTE_KEEP_RELEASES:-1}"
ALLOW_INITIAL_H5_RELEASE="${ALLOW_INITIAL_H5_RELEASE:-true}"

if [ -z "${H5_GIT_URL}" ]; then
  echo "H5_GIT_URL 不能为空；请配置 H5 远程 Git 地址。" >&2
  exit 2
fi

mkdir -p "${WORKSPACE_DIR}"
if [ ! -d "${WORKSPACE_DIR}/.git" ]; then
  rm -rf "${WORKSPACE_DIR}"
  git clone "${H5_GIT_URL}" "${WORKSPACE_DIR}"
else
  git -C "${WORKSPACE_DIR}" remote set-url origin "${H5_GIT_URL}"
fi

git -C "${WORKSPACE_DIR}" fetch --prune --tags origin

git -C "${WORKSPACE_DIR}" checkout -B "jenkins/${H5_GIT_BRANCH//\//-}" "origin/${H5_GIT_BRANCH}"

git -C "${WORKSPACE_DIR}" reset --hard
git -C "${WORKSPACE_DIR}" clean -fdx \
  -e node_modules \
  -e .next \
  -e archives/releases

H5_RUNTIME_ENV_FILE="${H5_RUNTIME_ENV_FILE:-${WORKSPACE_DIR}/config/env/h5.${H5_RELEASE_ENV}.env}"
if [ ! -f "${H5_RUNTIME_ENV_FILE}" ]; then
  echo "找不到 H5 环境配置：${H5_RUNTIME_ENV_FILE}" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "${H5_RUNTIME_ENV_FILE}"
set +a

JAVA_H5_RELEASE_API_BASE_URL="${JAVA_H5_RELEASE_API_BASE_URL:-${JAVA_RELEASE_SERVER_URL:-${JAVA_API_BASE_URL:-}}}"
JAVA_H5_RELEASE_REGISTER_API_BASE_URL="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL:-${JAVA_RELEASE_REGISTER_SERVER_URL:-${JAVA_H5_RELEASE_ADMIN_API_BASE_URL:-}}}"

missing_config=()
if [ -z "${JAVA_H5_RELEASE_API_BASE_URL}" ]; then
  missing_config+=("JAVA_H5_RELEASE_API_BASE_URL")
fi
if [ "${REGISTER_RELEASE}" = "true" ] && [ -z "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL}" ]; then
  missing_config+=("JAVA_H5_RELEASE_REGISTER_API_BASE_URL")
fi
if [ -z "${SERVER_PASSWORD:-}" ] && [ -z "${SSH_KEY:-}" ]; then
  missing_config+=("SERVER_PASSWORD 或 SSH_KEY")
fi
if [ "${#missing_config[@]}" -gt 0 ]; then
  {
    echo "H5 测试发版配置不完整：${missing_config[*]}"
    echo "固定配置文件：${CONFIG_FILE}"
    echo "H5 环境配置：${H5_RUNTIME_ENV_FILE}"
    echo "Jenkins 页面只保留分支选择，测试环境地址、服务器凭据等固定配置从文件读取。"
  } >&2
  exit 2
fi

resolve_next_h5_version() {
  node <<'NODE'
const { execSync } = require("child_process");
const fs = require("fs");

let packageVersion = "1.0.0";
try {
  packageVersion = JSON.parse(fs.readFileSync("package.json", "utf8")).version || packageVersion;
} catch (_) {}

const packageMatch = packageVersion.match(/^(\d+)\.(\d+)\.(\d+)(?:-.+)?$/);
const base = packageMatch ? packageMatch.slice(1, 4).map(Number) : [1, 0, 0];

let tags = [];
try {
  tags = execSync("git tag -l 'h5/v*'", { encoding: "utf8" })
    .split(/\n+/)
    .map((tag) => tag.trim())
    .filter(Boolean);
} catch (_) {
  tags = [];
}

const versions = tags
  .map((tag) => {
    const match = tag.match(/^h5\/v(\d+)\.(\d+)\.(\d+)(?:-.+)?$/);
    return match ? match.slice(1, 4).map(Number) : null;
  })
  .filter((version) => version && version[0] === base[0] && version[1] === base[1])
  .sort((a, b) => a[0] - b[0] || a[1] - b[1] || a[2] - b[2]);

const latest = versions.at(-1);
const nextPatch = latest ? Math.max(latest[2] + 1, base[2]) : base[2];
process.stdout.write(`v${base[0]}.${base[1]}.${nextPatch}`);
NODE
}

H5_VERSION="${H5_VERSION:-$(cd "${WORKSPACE_DIR}" && resolve_next_h5_version)}"

if [[ ! "${H5_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "H5_VERSION 必须是 vX.Y.Z 格式，例如 v1.0.15。当前值：${H5_VERSION}" >&2
  exit 2
fi

echo "== MeuMall Jenkins H5 test release =="
echo "H5 branch:     ${H5_GIT_BRANCH}"
echo "H5 commit:     $(git -C "${WORKSPACE_DIR}" rev-parse HEAD)"
echo "H5 version:    ${H5_VERSION}"
echo "Release env:   ${H5_RELEASE_ENV}"
echo "H5 env file:   ${H5_RUNTIME_ENV_FILE}"
echo "Promote:       ${PROMOTE_RELEASE}"
echo "Clean old:     ${CLEAN_OLD_REMOTE_RELEASES}"

H5_SOURCE_DIR="${WORKSPACE_DIR}" \
H5_VERSION="${H5_VERSION}" \
GIT_REF="HEAD" \
H5_RELEASE_ENV="${H5_RELEASE_ENV}" \
H5_RUNTIME_ENV_FILE="${H5_RUNTIME_ENV_FILE}" \
JAVA_H5_RELEASE_API_BASE_URL="${JAVA_H5_RELEASE_API_BASE_URL}" \
JAVA_H5_RELEASE_REGISTER_API_BASE_URL="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL}" \
REQUIRE_EXISTING_TAG=false \
PUSH_TAG_AFTER_RELEASE="${PUSH_TAG_AFTER_RELEASE}" \
CLEAN_OLD_REMOTE_RELEASES="${CLEAN_OLD_REMOTE_RELEASES}" \
REMOTE_KEEP_RELEASES="${REMOTE_KEEP_RELEASES}" \
REGISTER_RELEASE="${REGISTER_RELEASE}" \
PROMOTE_RELEASE="${PROMOTE_RELEASE}" \
ALLOW_INITIAL_H5_RELEASE="${ALLOW_INITIAL_H5_RELEASE}" \
SEND_FEISHU_REVIEW="${SEND_FEISHU_REVIEW}" \
FEISHU_REVIEW_DRY_RUN="${FEISHU_REVIEW_DRY_RUN}" \
  bash "${ROOT_DIR}/scripts/deploy/h5-version-deploy.sh"
