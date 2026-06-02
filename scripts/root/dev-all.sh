#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/root/dev-lib.sh"

SERVER_HOST="${SERVER_HOST:-127.0.0.1}"
SERVER_PORT="${SERVER_PORT:-4100}"
H5_HOST="${H5_HOST:-localhost}"
H5_PORT="${H5_PORT:-3109}"
ADMIN_HOST="${ADMIN_HOST:-localhost}"
ADMIN_PORT="${ADMIN_PORT:-5173}"
H5_BASE_PATH="${H5_BASE_PATH:-/hybird}"
ENVIRONMENT="${ENVIRONMENT:-prod}"

SERVER_URL="$(service_url "${SERVER_HOST}" "${SERVER_PORT}" "/api/health")"
H5_URL="$(service_url "${H5_HOST}" "${H5_PORT}" "${H5_BASE_PATH}")"
ADMIN_URL="$(service_url "${ADMIN_HOST}" "${ADMIN_PORT}" "/")"
MANIFEST_URL="http://${SERVER_HOST}:${SERVER_PORT}/api/h5/manifest/active?environment=${ENVIRONMENT}"
CONFIG_API_BASE_URL="http://${SERVER_HOST}:${SERVER_PORT}"

STARTED_PIDS=()
STARTED_NAMES=()

cleanup() {
  local status=$?
  local pid
  local attempt

  for pid in "${STARTED_PIDS[@]:-}"; do
    kill "${pid}" 2>/dev/null || true
  done

  for pid in "${STARTED_PIDS[@]:-}"; do
    attempt=0
    while kill -0 "${pid}" 2>/dev/null && [ "${attempt}" -lt 10 ]; do
      sleep 0.2
      attempt=$((attempt + 1))
    done
    if kill -0 "${pid}" 2>/dev/null; then
      kill -KILL "${pid}" 2>/dev/null || true
    fi
  done

  wait 2>/dev/null || true
  exit "${status}"
}
trap cleanup INT TERM EXIT

print_blocked_port() {
  local name="$1"
  local port="$2"
  local health_url="$3"

  echo "Cannot start ${name}: port ${port} is already in use, but ${health_url} is not responding as expected." >&2
  echo "Port owner:" >&2
  port_owner "${port}" >&2
}

remember_started() {
  local name="$1"
  local pid="$2"

  STARTED_NAMES+=("${name}")
  STARTED_PIDS+=("${pid}")
}

start_server() {
  local decision
  decision="$(service_start_decision "server-meumall" "${SERVER_PORT}" "${SERVER_URL}")"

  if [ "${decision}" = "reuse" ]; then
    echo "Reusing server-meumall on ${SERVER_URL}"
    return 0
  fi

  if [ "${decision}" = "blocked" ]; then
    print_blocked_port "server-meumall" "${SERVER_PORT}" "${SERVER_URL}"
    return 1
  fi

  echo "Starting server-meumall on ${SERVER_URL}"
  (
    cd "${ROOT_DIR}/server-meumall"
    . .venv/bin/activate
    exec python3 -m uvicorn app.main:app --host "${SERVER_HOST}" --port "${SERVER_PORT}" --reload
  ) &
  remember_started "server-meumall" "$!"
}

start_h5() {
  local decision
  local locked_url
  local locked_root_url

  locked_url="$(next_dev_lock_url "${ROOT_DIR}/hybird-meumall" "${H5_BASE_PATH}" || true)"
  if [ -n "${locked_url}" ]; then
    if http_ready "${locked_url}"; then
      H5_URL="${locked_url}"
      echo "Reusing hybird-meumall on ${H5_URL}"
      return 0
    fi

    locked_root_url="$(next_dev_lock_url "${ROOT_DIR}/hybird-meumall" "/" || true)"
    if [ -n "${locked_root_url}" ] && http_ready "${locked_root_url}"; then
      H5_URL="${locked_root_url}"
      echo "Reusing hybird-meumall on ${H5_URL}"
      echo "Note: existing H5 dev server is running without ${H5_BASE_PATH}; using its root URL."
      return 0
    fi

    if [ "${MEUMALL_RESTART_STALE_NEXT:-1}" = "1" ]; then
      local locked_pid
      local attempt

      locked_pid="$(next_dev_lock_pid "${ROOT_DIR}/hybird-meumall" || true)"
      if [ -n "${locked_pid}" ]; then
        echo "Restarting stale hybird-meumall Next dev process ${locked_pid}; its registered URL is not responding."
        kill "${locked_pid}" 2>/dev/null || true
        attempt=0
        while kill -0 "${locked_pid}" 2>/dev/null && [ "${attempt}" -lt 10 ]; do
          sleep 0.5
          attempt=$((attempt + 1))
        done
        if kill -0 "${locked_pid}" 2>/dev/null; then
          kill -KILL "${locked_pid}" 2>/dev/null || true
        fi
      fi

      rm -f "${ROOT_DIR}/hybird-meumall/.next/dev/lock"
    else
      echo "Cannot start hybird-meumall: an existing Next dev server is registered at ${locked_url}, but neither that URL nor its root URL is responding." >&2
      echo "Stop that process or remove the stale lock at hybird-meumall/.next/dev/lock after confirming the process is gone." >&2
      return 1
    fi
  fi

  decision="$(service_start_decision "hybird-meumall" "${H5_PORT}" "${H5_URL}")"

  if [ "${decision}" = "reuse" ]; then
    echo "Reusing hybird-meumall on ${H5_URL}"
    return 0
  fi

  if [ "${decision}" = "blocked" ]; then
    print_blocked_port "hybird-meumall" "${H5_PORT}" "${H5_URL}"
    return 1
  fi

  echo "Starting hybird-meumall on ${H5_URL}"
  (
    cd "${ROOT_DIR}/hybird-meumall"
    exec env \
      H5_BASE_PATH="${H5_BASE_PATH}" \
      H5_MANIFEST_URL="${MANIFEST_URL}" \
      NEXT_PUBLIC_H5_MANIFEST_URL="${MANIFEST_URL}" \
      NEXT_PUBLIC_CONFIG_API_BASE_URL="${CONFIG_API_BASE_URL}" \
      pnpm exec next dev -H "${H5_HOST}" -p "${H5_PORT}"
  ) &
  remember_started "hybird-meumall" "$!"
}

start_admin() {
  local decision
  decision="$(service_start_decision "admin-meumall" "${ADMIN_PORT}" "${ADMIN_URL}")"

  if [ "${decision}" = "reuse" ]; then
    echo "Reusing admin-meumall on ${ADMIN_URL}"
    return 0
  fi

  if [ "${decision}" = "blocked" ]; then
    print_blocked_port "admin-meumall" "${ADMIN_PORT}" "${ADMIN_URL}"
    return 1
  fi

  echo "Starting admin-meumall on ${ADMIN_URL}"
  (
    cd "${ROOT_DIR}/admin-meumall"
    exec env \
      VITE_CONFIG_API_BASE_URL="${CONFIG_API_BASE_URL}" \
      pnpm dev -- --host "${ADMIN_HOST}" --port "${ADMIN_PORT}"
  ) &
  remember_started "admin-meumall" "$!"
}

monitor_started_services() {
  local pid
  local index
  local status

  if [ "${#STARTED_PIDS[@]}" -eq 0 ]; then
    echo "All services were already running. Nothing new was started."
    return 0
  fi

  echo
  echo "Press Ctrl+C to stop services started by this command."

  while true; do
    index=0
    for pid in "${STARTED_PIDS[@]}"; do
      if ! kill -0 "${pid}" 2>/dev/null; then
        status=0
        wait "${pid}" || status=$?
        echo "${STARTED_NAMES[${index}]} exited with status ${status}." >&2
        return "${status}"
      fi
      index=$((index + 1))
    done
    sleep 1
  done
}

start_server
start_h5
start_admin

echo
echo "Local services:"
echo "- server: ${SERVER_URL}"
echo "- h5:     ${H5_URL}"
echo "- admin:  ${ADMIN_URL}"

monitor_started_services
