#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${H5_TEST_RELEASE_CONFIG:-}"

if [ -n "${CONFIG_FILE}" ] && [ ! -f "${CONFIG_FILE}" ]; then
  echo "缺少 H5 测试发版配置：${CONFIG_FILE}" >&2
  exit 2
fi

if [ -n "${CONFIG_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${CONFIG_FILE}"
  set +a
fi

WORKSPACE_DIR="${H5_RELEASE_WORKSPACE_DIR:-${ROOT_DIR}/.workspaces/h5-release}"
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
ALLOW_REPEAT_H5_COMMIT_RELEASE="${ALLOW_REPEAT_H5_COMMIT_RELEASE:-false}"

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

PROFILE_JAVA_H5_RELEASE_API_BASE_URL="${JAVA_H5_RELEASE_API_BASE_URL:-}"
PROFILE_JAVA_H5_RELEASE_REGISTER_API_BASE_URL="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL:-}"

JAVA_H5_RELEASE_API_BASE_URL="${JAVA_H5_RELEASE_API_BASE_URL:-${JAVA_RELEASE_SERVER_URL:-${JAVA_H5_RELEASE_ADMIN_API_BASE_URL:-${PROFILE_JAVA_H5_RELEASE_API_BASE_URL}}}}"
JAVA_H5_RELEASE_REGISTER_API_BASE_URL="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL:-${JAVA_RELEASE_REGISTER_SERVER_URL:-${JAVA_H5_RELEASE_ADMIN_API_BASE_URL:-${PROFILE_JAVA_H5_RELEASE_REGISTER_API_BASE_URL:-${JAVA_H5_RELEASE_API_BASE_URL:-}}}}}"
JAVA_H5_RELEASE_TOKEN="${JAVA_H5_RELEASE_TOKEN:-${JAVA_RELEASE_TOKEN:-}}"
JAVA_H5_RELEASE_REGISTER_TOKEN="${JAVA_H5_RELEASE_REGISTER_TOKEN:-${JAVA_RELEASE_REGISTER_TOKEN:-${JAVA_H5_RELEASE_TOKEN}}}"

assert_java_h5_release_base_url() {
  local name="$1"
  local value="$2"

  if [ -z "${value}" ]; then
    echo "${name} 不能为空；Jenkins H5 发版必须显式配置 Java 管理系统接口前缀。" >&2
    exit 2
  fi

  case "${value}" in
    *"/api/h5/manifest"*|*"/api/releases"*|*"/mini_h5"*)
      {
        echo "${name} 指向了旧 Python manifest/release 或 Java 业务接口，不允许用于 H5 版本管理。"
        echo "${name}: ${value}"
        echo "请通过 Jenkins 环境变量或 H5_TEST_RELEASE_CONFIG 指向的配置文件配置 Java 管理系统前缀，例如：https://test.aigcpop.com:18088/apis"
      } >&2
      exit 2
      ;;
  esac
}

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
    echo "配置文件：${CONFIG_FILE:-未设置；当前仅使用环境变量}"
    echo "H5 环境配置：${H5_RUNTIME_ENV_FILE}"
    echo "请在外部 Jenkins 环境变量中配置测试环境地址、服务器凭据和 Java H5 版本管理地址，或用 H5_TEST_RELEASE_CONFIG 指向显式配置文件。"
  } >&2
  exit 2
fi

assert_java_h5_release_base_url "JAVA_H5_RELEASE_API_BASE_URL" "${JAVA_H5_RELEASE_API_BASE_URL}"
if [ "${REGISTER_RELEASE}" = "true" ]; then
  assert_java_h5_release_base_url "JAVA_H5_RELEASE_REGISTER_API_BASE_URL" "${JAVA_H5_RELEASE_REGISTER_API_BASE_URL}"
fi

find_h5_tags_for_commit() {
  local commit_sha="$1"
  local tag

  git -C "${WORKSPACE_DIR}" tag -l 'h5/v*' | while read -r tag; do
    if [ -n "${tag}" ] && [ "$(git -C "${WORKSPACE_DIR}" rev-list -n 1 "${tag}")" = "${commit_sha}" ]; then
      printf "%s\n" "${tag}"
    fi
  done
}

assert_commit_not_released() {
  local commit_sha="$1"
  local existing_tags

  if [ "${ALLOW_REPEAT_H5_COMMIT_RELEASE}" = "true" ]; then
    return 0
  fi

  existing_tags="$(find_h5_tags_for_commit "${commit_sha}")"
  if [ -n "${existing_tags}" ]; then
    {
      echo "当前 commit 已经存在 H5 版本 tag，不能为同一个 commit 生成新版本。"
      echo "commit: ${commit_sha}"
      echo "existing tags:"
      printf "%s\n" "${existing_tags}"
      echo "请先合入新的 H5 commit 后再发版；如确需重发同一 commit，请人工确认后设置 ALLOW_REPEAT_H5_COMMIT_RELEASE=true。"
    } >&2
    exit 2
  fi

  if [ "${REGISTER_RELEASE}" != "true" ]; then
    return 0
  fi

  RELEASE_LIST_ENDPOINT="${JAVA_H5_RELEASE_REGISTER_API_BASE_URL%/}/platform/h5Release/list" \
  JAVA_H5_RELEASE_REGISTER_TOKEN="${JAVA_H5_RELEASE_REGISTER_TOKEN}" \
  H5_COMMIT_SHA="${commit_sha}" \
  python3 <<'PY'
import json
import os
import sys
import urllib.request

endpoint = os.environ["RELEASE_LIST_ENDPOINT"]
commit_sha = os.environ["H5_COMMIT_SHA"]
token = os.environ.get("JAVA_H5_RELEASE_REGISTER_TOKEN")

headers = {"Accept": "application/json"}
if token:
    headers["Authorization"] = token

request = urllib.request.Request(endpoint, headers=headers, method="GET")
try:
    with urllib.request.urlopen(request, timeout=20) as response:
        body = json.loads(response.read().decode("utf-8"))
except Exception as exc:
    print(f"无法查询 Java H5 版本列表，不能确认 commit 是否已发版：{exc}", file=sys.stderr)
    print("请配置 JAVA_H5_RELEASE_REGISTER_TOKEN，或临时设置 ALLOW_REPEAT_H5_COMMIT_RELEASE=true 后人工确认。", file=sys.stderr)
    sys.exit(2)

if isinstance(body, dict) and body.get("success") is False:
    print(f"Java H5 版本列表查询失败：{body.get('msg') or body}", file=sys.stderr)
    print("请配置 JAVA_H5_RELEASE_REGISTER_TOKEN，或临时设置 ALLOW_REPEAT_H5_COMMIT_RELEASE=true 后人工确认。", file=sys.stderr)
    sys.exit(2)

items = body.get("data") if isinstance(body, dict) else body
if not isinstance(items, list):
    print(f"Java H5 版本列表返回格式异常：{body}", file=sys.stderr)
    sys.exit(2)

matches = []
for item in items:
    if not isinstance(item, dict):
        continue
    build_meta = item.get("buildMeta") or item.get("build_meta") or {}
    if isinstance(build_meta, str):
        try:
            build_meta = json.loads(build_meta)
        except Exception:
            build_meta = {}
    if isinstance(build_meta, dict) and build_meta.get("gitCommit") == commit_sha:
        matches.append(item)

if matches:
    print("当前 commit 已经存在 Java H5 版本记录，不能为同一个 commit 生成新版本。", file=sys.stderr)
    print(f"commit: {commit_sha}", file=sys.stderr)
    for item in matches:
        print(f"- {item.get('version')} [{item.get('environment')}] {item.get('status')} id={item.get('id')}", file=sys.stderr)
    sys.exit(2)
PY
}

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

H5_COMMIT_SHA="$(git -C "${WORKSPACE_DIR}" rev-parse HEAD)"
assert_commit_not_released "${H5_COMMIT_SHA}"
H5_VERSION="${H5_VERSION:-$(cd "${WORKSPACE_DIR}" && resolve_next_h5_version)}"

if [[ ! "${H5_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "H5_VERSION 必须是 vX.Y.Z 格式，例如 v1.0.15。当前值：${H5_VERSION}" >&2
  exit 2
fi

echo "== MeuMall Jenkins H5 test release =="
echo "H5 branch:     ${H5_GIT_BRANCH}"
echo "H5 commit:     ${H5_COMMIT_SHA}"
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
JAVA_H5_RELEASE_TOKEN="${JAVA_H5_RELEASE_TOKEN}" \
JAVA_H5_RELEASE_REGISTER_TOKEN="${JAVA_H5_RELEASE_REGISTER_TOKEN}" \
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
