#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_HOME="${ROOT_DIR}/meumall-ci"
JENKINS_URL="${JENKINS_URL:-http://127.0.0.1:8082}"
JENKINS_ADMIN_ID="${JENKINS_ADMIN_ID:-meumall}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-meumall-local-2026}"

mkdir -p "${CI_HOME}/jenkins/pipelines"
rm -f "${CI_HOME}/jenkins/pipelines/hybird-meumall-local-deploy.groovy"
cp "${ROOT_DIR}/deploy/jenkins/meu-mall-test-server-deploy.groovy" \
  "${CI_HOME}/jenkins/pipelines/meu-mall-test-server-deploy.groovy"

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
    node <<'NODE'
const base = process.env.JENKINS_URL;
const user = process.env.JENKINS_ADMIN_ID;
const password = process.env.JENKINS_ADMIN_PASSWORD;
const auth = 'Basic ' + Buffer.from(`${user}:${password}`).toString('base64');

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
import hudson.model.ParametersDefinitionProperty
import hudson.model.StringParameterDefinition
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob

Jenkins instance = Jenkins.get()

def oldJob = instance.getItem('hybird-meumall-local-deploy')
if (oldJob != null) {
  oldJob.delete()
}

def pipelineFile = new File('/var/jenkins_home/pipelines/meu-mall-test-server-deploy.groovy')
if (!pipelineFile.exists()) {
  throw new RuntimeException('Pipeline file not found: ' + pipelineFile.path)
}

def job = instance.getItem('meu-mall-test-server-deploy')
if (job == null) {
  job = instance.createProject(WorkflowJob, 'meu-mall-test-server-deploy')
}
job.setDefinition(new CpsFlowDefinition(pipelineFile.text, true))
job.removeProperty(ParametersDefinitionProperty)
job.addProperty(new ParametersDefinitionProperty([
  new StringParameterDefinition('REMOTE_HOST', '8.163.107.208', '测试服务器 IP'),
  new StringParameterDefinition('REMOTE_USER', 'root', 'SSH 用户'),
  new StringParameterDefinition('REMOTE_PORT', '22', 'SSH 端口'),
  new StringParameterDefinition('REMOTE_PATH', '/opt/mail4j/meu-mall', '远端部署目录'),
  new StringParameterDefinition('DOMAIN', 'hybird.aigcpop.com', 'H5 测试域名'),
  new BooleanParameterDefinition('INSTALL_NGINX', true, '是否安装并 reload Nginx 站点配置'),
  new BooleanParameterDefinition('RUN_REMOTE_SMOKE', true, '是否执行远端 smoke check')
]))
job.setConcurrentBuild(false)
job.save()
instance.save()
println('synced meu-mall-test-server-deploy')
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

用于测试服务器整站部署的任务：
- meu-mall-test-server-deploy

如果这台机器还没有配置测试服务器凭据，请在 Jenkins 凭据里添加 Secret Text：
- ID: meu-mall-test-server-password
- Secret: 测试服务器 SSH 密码
EOF
