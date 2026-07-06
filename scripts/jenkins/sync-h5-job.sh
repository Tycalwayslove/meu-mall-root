#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

JENKINS_URL="${JENKINS_URL:-http://127.0.0.1:8080}"
JENKINS_URL="${JENKINS_URL%/}"
JENKINS_JOB_NAME="${JENKINS_JOB_NAME:-meu-mall-h5-test-release}"
JENKINS_PIPELINE_FILE="${JENKINS_PIPELINE_FILE:-${ROOT_DIR}/deploy/jenkins/meu-mall-h5-version-deploy.groovy}"
DRY_RUN="${DRY_RUN:-false}"

if [ ! -f "${JENKINS_PIPELINE_FILE}" ]; then
  echo "找不到 Jenkins Pipeline 文件：${JENKINS_PIPELINE_FILE}" >&2
  exit 2
fi

JENKINS_SECRET="${JENKINS_TOKEN:-${JENKINS_PASSWORD:-}}"
if [ -n "${JENKINS_USER:-}" ] || [ -n "${JENKINS_SECRET}" ]; then
  if [ -z "${JENKINS_USER:-}" ] || [ -z "${JENKINS_SECRET}" ]; then
    echo "Jenkins 鉴权参数不完整：请同时配置 JENKINS_USER 和 JENKINS_TOKEN。也可以都不配置以访问未开启鉴权的 Jenkins。" >&2
    exit 2
  fi
fi

jenkins_curl() {
  if [ -n "${JENKINS_USER:-}" ]; then
    curl -u "${JENKINS_USER}:${JENKINS_SECRET}" "$@"
  else
    curl "$@"
  fi
}

CONFIG_XML="$(mktemp "${TMPDIR:-/tmp}/meumall-h5-jenkins-job.XXXXXX")"
trap 'rm -f "${CONFIG_XML}"' EXIT

JENKINS_JOB_NAME="${JENKINS_JOB_NAME}" \
JENKINS_PIPELINE_FILE="${JENKINS_PIPELINE_FILE}" \
python3 >"${CONFIG_XML}" <<'PY'
import os
from html import escape
from pathlib import Path

job_name = os.environ["JENKINS_JOB_NAME"]
pipeline_file = Path(os.environ["JENKINS_PIPELINE_FILE"])
script = pipeline_file.read_text(encoding="utf-8")

print("""<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>{description}</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>H5_GIT_BRANCH</name>
          <description>可选。未配置 H5_GIT_URL 时，发版脚本使用当前工作区 hybird-meumall 并忽略该参数；配置 H5_GIT_URL 后按该远程分支构建。</description>
          <defaultValue></defaultValue>
          <trim>true</trim>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script>{script}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>""".format(
    description=escape(f"MeuMall H5 测试环境发版 Pipeline，由 scripts/jenkins/sync-h5-job.sh 同步生成。Job: {job_name}"),
    script=escape(script),
))
PY

job_encoded="$(
  JENKINS_JOB_NAME="${JENKINS_JOB_NAME}" python3 <<'PY'
import os
from urllib.parse import quote

print(quote(os.environ["JENKINS_JOB_NAME"], safe=""))
PY
)"

if [ "${DRY_RUN}" = "true" ]; then
  {
    echo "== MeuMall Jenkins H5 job sync dry-run =="
    echo "Jenkins URL: ${JENKINS_URL}"
    echo "Job:         ${JENKINS_JOB_NAME}"
    echo "Pipeline:    ${JENKINS_PIPELINE_FILE}"
    echo
    cat "${CONFIG_XML}"
  }
  exit 0
fi

crumb_header_value=""
crumb_json="$(jenkins_curl -fsS "${JENKINS_URL}/crumbIssuer/api/json" 2>/dev/null || true)"
if [ -n "${crumb_json}" ]; then
  crumb_value="$(
    CRUMB_JSON="${crumb_json}" python3 <<'PY'
import json
import os

try:
    payload = json.loads(os.environ["CRUMB_JSON"])
    field = payload.get("crumbRequestField")
    crumb = payload.get("crumb")
    if field and crumb:
        print(f"{field}: {crumb}")
except Exception:
    pass
PY
  )"
  if [ -n "${crumb_value}" ]; then
    crumb_header_value="${crumb_value}"
  fi
fi

job_status="$(
  jenkins_curl -sS -o /dev/null -w "%{http_code}" \
    "${JENKINS_URL}/job/${job_encoded}/api/json" || true
)"

post_config_xml() {
  local target_url="$1"

  if [ -n "${crumb_header_value}" ]; then
    jenkins_curl -fsS -X POST \
      -H "${crumb_header_value}" \
      -H "Content-Type: application/xml" \
      --data-binary "@${CONFIG_XML}" \
      "${target_url}" >/dev/null
  else
    jenkins_curl -fsS -X POST \
      -H "Content-Type: application/xml" \
      --data-binary "@${CONFIG_XML}" \
      "${target_url}" >/dev/null
  fi
}

case "${job_status}" in
  200)
    echo "Jenkins job 已存在，更新配置：${JENKINS_JOB_NAME}"
    post_config_xml "${JENKINS_URL}/job/${job_encoded}/config.xml"
    ;;
  404)
    echo "Jenkins job 不存在，创建：${JENKINS_JOB_NAME}"
    post_config_xml "${JENKINS_URL}/createItem?name=${job_encoded}"
    ;;
  *)
    {
      echo "无法读取 Jenkins job 状态。"
      echo "Jenkins URL: ${JENKINS_URL}"
      echo "Job: ${JENKINS_JOB_NAME}"
      echo "HTTP status: ${job_status}"
      echo "请确认 Jenkins 可访问，并配置 JENKINS_USER/JENKINS_TOKEN。"
    } >&2
    exit 2
    ;;
esac

echo "Jenkins H5 发版管道已同步：${JENKINS_URL}/job/${job_encoded}/"
