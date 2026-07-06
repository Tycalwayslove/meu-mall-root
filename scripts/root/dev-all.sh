#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/root/dev-lib.sh"

H5_ENV="${H5_ENV:-local}"
H5_ENV_FILE="${H5_ENV_FILE:-${ROOT_DIR}/hybird-meumall/config/env/h5.${H5_ENV}.env}"

if [ -f "${H5_ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${H5_ENV_FILE}"
  set +a
else
  echo "H5 env file not found: ${H5_ENV_FILE}; falling back to inline defaults." >&2
fi

for local_env_file in "${ROOT_DIR}/.env.local" "${ROOT_DIR}/hybird-meumall/.env.local"; do
  if [ -f "${local_env_file}" ]; then
    set -a
    # shellcheck disable=SC1090
    . "${local_env_file}"
    set +a
  fi
done

H5_HOST="${H5_HOST:-localhost}"
H5_PORT="${H5_PORT:-${PORT:-3109}}"
H5_BASE_PATH="${H5_BASE_PATH:-/hybird}"
H5_URL="$(service_url "${H5_HOST}" "${H5_PORT}" "${H5_BASE_PATH}")"
MANIFEST_URL="${H5_MANIFEST_URL:-${JAVA_H5_RELEASE_API_BASE_URL:+${JAVA_H5_RELEASE_API_BASE_URL%/}/platform/h5Release/active}}"

STARTED_PID=""

cleanup() {
  local status=$?
  if [ -n "${STARTED_PID}" ]; then
    kill "${STARTED_PID}" 2>/dev/null || true
    wait "${STARTED_PID}" 2>/dev/null || true
  fi
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
    echo "Note: restart the existing H5 dev server if you need to apply ${H5_ENV_FILE}."
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
      APP_ENV="${APP_ENV:-${H5_ENV}}" \
      NEXT_PUBLIC_APP_ENV="${NEXT_PUBLIC_APP_ENV:-${APP_ENV:-${H5_ENV}}}" \
      NEXT_PUBLIC_H5_VERSION="${NEXT_PUBLIC_H5_VERSION:-}" \
      H5_BASE_PATH="${H5_BASE_PATH}" \
      NEXT_PUBLIC_H5_BASE_PATH="${NEXT_PUBLIC_H5_BASE_PATH:-${H5_BASE_PATH}}" \
      H5_SERVICE_BASE_URL="${H5_SERVICE_BASE_URL:-}" \
      H5_RELEASE_SERVER_URL="${H5_RELEASE_SERVER_URL:-}" \
      H5_MANIFEST_URL="${MANIFEST_URL:-}" \
      NEXT_PUBLIC_H5_MANIFEST_URL="${NEXT_PUBLIC_H5_MANIFEST_URL:-${MANIFEST_URL:-}}" \
      NEXT_PUBLIC_CONFIG_API_BASE_URL="${NEXT_PUBLIC_CONFIG_API_BASE_URL:-}" \
      NEXT_PUBLIC_API_BASE_URL="${NEXT_PUBLIC_API_BASE_URL:-/api/bff}" \
      H5_HEALTH_CHECK_PATH="${H5_HEALTH_CHECK_PATH:-/api/health}" \
      H5_RELEASE_VARIANT="${H5_RELEASE_VARIANT:-}" \
      H5_RELEASE_LABEL="${H5_RELEASE_LABEL:-}" \
      JAVA_API_BASE_URL="${JAVA_API_BASE_URL:-}" \
      JAVA_OSS_ASSET_BASE_URL="${JAVA_OSS_ASSET_BASE_URL:-}" \
      PYTHON_API_BASE_URL="${PYTHON_API_BASE_URL:-}" \
      pnpm exec next dev --webpack -H "${H5_HOST}" -p "${H5_PORT}"
  ) &
  STARTED_PID="$!"
}

start_h5

echo
echo "Local H5 service:"
echo "- h5:       ${H5_URL}"
echo "- h5 env:   ${H5_ENV} (${H5_ENV_FILE})"
echo "- java:     ${JAVA_API_BASE_URL:-not configured}"
echo "- manifest: ${MANIFEST_URL:-not configured}"
echo
if [ -n "${STARTED_PID}" ]; then
  echo "Press Ctrl+C to stop the H5 service started by this command."

  wait "${STARTED_PID}"
else
  echo "No new H5 service was started by this command."
fi
