#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_HOME="${ROOT_DIR}/meumall-ci"
JENKINS_URL="${JENKINS_URL:-http://127.0.0.1:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-meumall}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-meumall-local-2026}"
H5_GIT_URL="git@github.com:Tycalwayslove/hybird-meumall.git"
H5_BRANCH_CHOICES="$(
  git ls-remote --heads "${H5_GIT_URL}" 2>/dev/null \
    | awk '{sub("refs/heads/", "", $2); print $2}' \
    | sort -u
)"
if [ -z "${H5_BRANCH_CHOICES}" ]; then
  H5_BRANCH_CHOICES="main"
fi

mkdir -p "${CI_HOME}/jenkins/pipelines"
rm -f \
  "${CI_HOME}/jenkins/pipelines/hybird-meumall-local-deploy.groovy" \
  "${CI_HOME}/jenkins/pipelines/meu-mall-test-server-deploy.groovy"
cp "${ROOT_DIR}/deploy/jenkins/meu-mall-h5-version-deploy.groovy" \
  "${CI_HOME}/jenkins/pipelines/meu-mall-h5-version-deploy.groovy"

"${CI_HOME}/ops/start-all.sh"

for attempt in $(seq 1 30); do
  if curl -fsS --max-time 2 "${JENKINS_URL}/login" >/dev/null; then
    break
  fi
  sleep 2
done

sync_jenkins_jobs() {
  JENKINS_URL="${JENKINS_URL}" \
    JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID}" \
    JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD}" \
    H5_BRANCH_CHOICES="${H5_BRANCH_CHOICES}" \
    node <<'NODE'
const base = process.env.JENKINS_URL;
const user = process.env.JENKINS_ADMIN_ID;
const password = process.env.JENKINS_ADMIN_PASSWORD;
const auth = 'Basic ' + Buffer.from(`${user}:${password}`).toString('base64');
const branchChoices = (process.env.H5_BRANCH_CHOICES || 'main')
  .split(/\n+/)
  .map((branch) => branch.trim())
  .filter(Boolean);
const branchChoicesJson = JSON.stringify(branchChoices);

const crumbRes = await fetch(`${base}/crumbIssuer/api/json`, {
  headers: { Authorization: auth },
});
if (!crumbRes.ok) {
  throw new Error(`Failed to get Jenkins crumb: ${crumbRes.status}`);
}
const cookie = crumbRes.headers.get('set-cookie')?.split(';')[0] ?? '';
const crumb = await crumbRes.json();

const script = String.raw`
import hudson.model.BooleanParameterDefinition
import hudson.model.ChoiceParameterDefinition
import hudson.model.ParametersDefinitionProperty
import hudson.model.PasswordParameterDefinition
import hudson.model.StringParameterDefinition
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import groovy.json.JsonSlurper

Jenkins instance = Jenkins.get()
def branchChoices = new JsonSlurper().parseText('${branchChoicesJson.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}') as List<String>

def oldJob = instance.getItem('hybird-meumall-local-deploy')
if (oldJob != null) {
  oldJob.delete()
}
def oldServerJob = instance.getItem('meu-mall-test-server-deploy')
if (oldServerJob != null) {
  oldServerJob.delete()
}
def oldVersionJob = instance.getItem('meu-mall-h5-version-deploy')
if (oldVersionJob != null) {
  oldVersionJob.delete()
}

def h5VersionPipelineFile = new File('/var/jenkins_home/pipelines/meu-mall-h5-version-deploy.groovy')
if (!h5VersionPipelineFile.exists()) {
  throw new RuntimeException('Pipeline file not found: ' + h5VersionPipelineFile.path)
}

def h5VersionJob = instance.getItem('meu-mall-h5-test-release')
if (h5VersionJob == null) {
  h5VersionJob = instance.createProject(WorkflowJob, 'meu-mall-h5-test-release')
}
h5VersionJob.setDefinition(new CpsFlowDefinition(h5VersionPipelineFile.text, true))
h5VersionJob.removeProperty(ParametersDefinitionProperty)
h5VersionJob.addProperty(new ParametersDefinitionProperty([
  new ChoiceParameterDefinition('H5_GIT_BRANCH', branchChoices as String[], '选择要发布到测试环境的 H5 远程分支。')
]))
h5VersionJob.setConcurrentBuild(false)
h5VersionJob.save()
instance.save()
println('synced meu-mall-h5-test-release')
`;

const response = await fetch(`${base}/scriptText`, {
  method: 'POST',
  headers: {
    Authorization: auth,
    Cookie: cookie,
    [crumb.crumbRequestField]: crumb.crumb,
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: new URLSearchParams({ script }),
});
const text = await response.text();
if (!response.ok) {
  throw new Error(`Failed to sync Jenkins jobs: ${response.status}\n${text}`);
}
process.stdout.write(text);
NODE
}

sync_jenkins_jobs

CRUMB="$(
  curl -fsS \
    --user "${JENKINS_ADMIN_ID}:${JENKINS_ADMIN_PASSWORD}" \
    "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)" \
    2>/dev/null || true
)"
if [ -n "${CRUMB}" ]; then
  curl -fsS \
    --user "${JENKINS_ADMIN_ID}:${JENKINS_ADMIN_PASSWORD}" \
    -H "${CRUMB}" \
    -X POST \
    "${JENKINS_URL}/job/hybird-meumall-local-deploy/doDelete" \
    >/dev/null 2>&1 || true
fi

cat <<EOF

Jenkins 已启动：
- 地址：${JENKINS_URL}
- 用户：${JENKINS_ADMIN_ID}
- 密码：${JENKINS_ADMIN_PASSWORD}

用于 H5 测试环境发版的任务：
- meu-mall-h5-test-release

运行 job 时请在参数中填写：
- 只需要选择 H5_GIT_BRANCH 并点击构建

测试环境固定配置文件：
- ${CI_HOME}/config/h5-test-release.env
EOF
