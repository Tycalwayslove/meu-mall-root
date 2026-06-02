#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

REMOTE_HOST="${REMOTE_HOST:-8.163.107.208}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_PATH="${REMOTE_PATH:-/opt/mail4j/meu-mall}"
DOMAIN="${DOMAIN:-hybird.aigcpop.com}"
INSTALL_NGINX="${INSTALL_NGINX:-true}"
RUN_REMOTE_SMOKE="${RUN_REMOTE_SMOKE:-true}"
SSH_KEY="${SSH_KEY:-}"
SERVER_PASSWORD="${SERVER_PASSWORD:-}"

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

run_rsync() {
  local rsync_command

  rsync_command="$(
    printf 'rsync -az --delete %s %q %q' \
      "--exclude=.git --exclude=node_modules --exclude=.next --exclude=dist --exclude=.venv --exclude=.pytest_cache --exclude=__pycache__ --exclude=runtime --exclude=data --exclude=.DS_Store --exclude=*.log -e \"ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=accept-new\"" \
      "${ROOT_DIR}/" \
      "${SSH_TARGET}:${REMOTE_PATH}/"
  )"

  if [ -n "${SSH_KEY}" ]; then
    rsync_command="$(
      printf 'rsync -az --delete %s %q %q' \
        "--exclude=.git --exclude=node_modules --exclude=.next --exclude=dist --exclude=.venv --exclude=.pytest_cache --exclude=__pycache__ --exclude=runtime --exclude=data --exclude=.DS_Store --exclude=*.log -e \"ssh -i ${SSH_KEY} -p ${REMOTE_PORT} -o StrictHostKeyChecking=accept-new\"" \
        "${ROOT_DIR}/" \
        "${SSH_TARGET}:${REMOTE_PATH}/"
    )"
  fi

  EXPECT_COMMAND="${rsync_command}" SERVER_PASSWORD="${SERVER_PASSWORD}" expect_password
}

remote_bootstrap_command() {
  cat <<REMOTE
set -euo pipefail
mkdir -p '${REMOTE_PATH}'
REMOTE
}

remote_nginx_command() {
  cat <<REMOTE
set -euo pipefail
if command -v nginx >/dev/null 2>&1; then
  cp '${REMOTE_PATH}/deploy/nginx/hybird.aigcpop.com.conf' '/etc/nginx/conf.d/meu-mall-hybird.aigcpop.com.conf'
  nginx -t
  nginx -s reload || systemctl reload nginx || service nginx reload
else
  echo 'nginx command not found on host; skipped nginx reload.' >&2
  exit 20
fi
REMOTE
}

remote_compose_command() {
  cat <<REMOTE
set -euo pipefail
cd '${REMOTE_PATH}'
mkdir -p runtime/server-data
if docker compose version >/dev/null 2>&1; then
  COMPOSE='docker compose'
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE='docker-compose'
else
  echo 'docker compose is not available on remote server.' >&2
  exit 21
fi
\${COMPOSE} -f deploy/docker-compose.test.yml up -d --build
REMOTE
}

remote_smoke_command() {
  cat <<REMOTE
set -euo pipefail
curl -fsS --max-time 10 http://127.0.0.1:4100/api/health >/dev/null
curl -fsS --max-time 10 http://127.0.0.1:3109/api/health >/dev/null
curl -fsS --max-time 10 -H 'Host: ${DOMAIN}' http://127.0.0.1/ >/dev/null
curl -fsS --max-time 10 -H 'Host: ${DOMAIN}' http://127.0.0.1/admin/ >/dev/null
echo 'remote smoke passed'
REMOTE
}

echo "== Meu Mall test-server deploy =="
echo "Remote: ${SSH_TARGET}:${REMOTE_PORT}"
echo "Path:   ${REMOTE_PATH}"
echo "Domain: ${DOMAIN}"

echo "== Bootstrap remote path =="
run_ssh "$(remote_bootstrap_command)"

echo "== Sync workspace =="
run_rsync

echo "== Start Docker services =="
run_ssh "$(remote_compose_command)"

if [ "${INSTALL_NGINX}" = "true" ]; then
  echo "== Install Nginx site =="
  run_ssh "$(remote_nginx_command)"
else
  echo "== Skip Nginx site install =="
fi

if [ "${RUN_REMOTE_SMOKE}" = "true" ]; then
  echo "== Remote smoke =="
  run_ssh "$(remote_smoke_command)"
fi

echo "Deploy complete: http://${DOMAIN}"
