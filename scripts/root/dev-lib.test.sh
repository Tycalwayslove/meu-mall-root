#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/root/dev-lib.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local label="$3"

  if [ "${actual}" != "${expected}" ]; then
    echo "FAIL: ${label}" >&2
    echo "expected: ${expected}" >&2
    echo "actual:   ${actual}" >&2
    exit 1
  fi
}

MEUMALL_TEST_HTTP_READY_PORTS="3109"
MEUMALL_TEST_LISTENING_PORTS="3109 9999"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
mkdir -p "${TMP_DIR}/.next/dev"
cat > "${TMP_DIR}/.next/dev/lock" <<JSON
{"pid":$$,"port":3000,"hostname":"localhost","appUrl":"http://localhost:3000","startedAt":1780304875594}
JSON

assert_eq "$(service_url "127.0.0.1" "3109" "/api/health")" "http://127.0.0.1:3109/api/health" "builds service URL"
assert_eq "$(service_url "127.0.0.1" "3109" "/hybird")" "http://127.0.0.1:3109/hybird" "builds base-path URL"
assert_eq "$(next_dev_lock_url "${TMP_DIR}" "/hybird")" "http://localhost:3000/hybird" "reads an existing Next dev lock"
assert_eq "$(next_dev_lock_url "${TMP_DIR}" "/")" "http://localhost:3000" "reads an existing Next dev root URL"
assert_eq "$(next_dev_lock_pid "${TMP_DIR}")" "$$" "reads an existing Next dev pid"
assert_eq "$(service_start_decision "h5" "3109" "http://127.0.0.1:3109/api/health")" "reuse" "reuses healthy existing service"
assert_eq "$(service_start_decision "h5" "3120" "http://127.0.0.1:3120/hybird")" "start" "starts free service port"
assert_eq "$(service_start_decision "external" "9999" "http://127.0.0.1:9999/")" "blocked" "blocks occupied unhealthy port"

echo "dev-lib tests passed"
