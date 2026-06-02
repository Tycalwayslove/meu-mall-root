#!/usr/bin/env bash

service_url() {
  local host="$1"
  local port="$2"
  local path="$3"
  local clean_path="/${path#/}"

  echo "http://${host}:${port}${clean_path}"
}

contains_port() {
  local ports="$1"
  local wanted="$2"
  local port

  for port in ${ports}; do
    if [ "${port}" = "${wanted}" ]; then
      return 0
    fi
  done

  return 1
}

http_ready() {
  local url="$1"
  local port="${url#http://*:}"
  port="${port%%/*}"

  if [ -n "${MEUMALL_TEST_HTTP_READY_PORTS:-}" ]; then
    contains_port "${MEUMALL_TEST_HTTP_READY_PORTS}" "${port}"
    return $?
  fi

  curl -fsS --max-time "${MEUMALL_HTTP_READY_TIMEOUT:-5}" "${url}" >/dev/null 2>&1
}

port_listening() {
  local port="$1"

  if [ -n "${MEUMALL_TEST_LISTENING_PORTS:-}" ]; then
    contains_port "${MEUMALL_TEST_LISTENING_PORTS}" "${port}"
    return $?
  fi

  lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
}

port_owner() {
  local port="$1"

  lsof -nP -iTCP:"${port}" -sTCP:LISTEN 2>/dev/null | tail -n +2 || true
}

service_start_decision() {
  local _name="$1"
  local port="$2"
  local health_url="$3"

  if http_ready "${health_url}"; then
    echo "reuse"
    return 0
  fi

  if port_listening "${port}"; then
    echo "blocked"
    return 0
  fi

  echo "start"
}

next_dev_lock_url() {
  local project_dir="$1"
  local base_path="$2"
  local lock_file="${project_dir}/.next/dev/lock"

  if [ ! -f "${lock_file}" ]; then
    return 1
  fi

  node - "${lock_file}" "${base_path}" <<'NODE'
const fs = require('node:fs');

const lockFile = process.argv[2];
const basePath = `/${String(process.argv[3] || '/').replace(/^\/+/, '')}`.replace(/\/$/, '') || '/';

try {
  const lock = JSON.parse(fs.readFileSync(lockFile, 'utf8'));
  const pid = Number(lock.pid);
  const port = Number(lock.port);

  if (!Number.isInteger(pid) || !Number.isInteger(port)) {
    process.exit(1);
  }

  try {
    process.kill(pid, 0);
  } catch {
    process.exit(1);
  }

  const appUrl = typeof lock.appUrl === 'string' && lock.appUrl
    ? lock.appUrl.replace(/\/+$/, '')
    : `http://${lock.hostname || 'localhost'}:${port}`;
  console.log(`${appUrl}${basePath === '/' ? '' : basePath}`);
} catch {
  process.exit(1);
}
NODE
}

next_dev_lock_pid() {
  local project_dir="$1"
  local lock_file="${project_dir}/.next/dev/lock"

  if [ ! -f "${lock_file}" ]; then
    return 1
  fi

  node - "${lock_file}" <<'NODE'
const fs = require('node:fs');

try {
  const lock = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const pid = Number(lock.pid);

  if (!Number.isInteger(pid)) {
    process.exit(1);
  }

  console.log(pid);
} catch {
  process.exit(1);
}
NODE
}
