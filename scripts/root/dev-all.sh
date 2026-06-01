#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cleanup() {
  local status=$?
  if [ -n "${SERVER_PID:-}" ]; then kill "${SERVER_PID}" 2>/dev/null || true; fi
  if [ -n "${H5_PID:-}" ]; then kill "${H5_PID}" 2>/dev/null || true; fi
  if [ -n "${ADMIN_PID:-}" ]; then kill "${ADMIN_PID}" 2>/dev/null || true; fi
  wait 2>/dev/null || true
  exit "${status}"
}
trap cleanup INT TERM EXIT

echo "Starting server-meumall on http://127.0.0.1:4100"
(
  cd "${ROOT_DIR}/server-meumall"
  . .venv/bin/activate
  python3 -m uvicorn app.main:app --host 127.0.0.1 --port 4100 --reload
) &
SERVER_PID=$!

echo "Starting hybird-meumall on http://127.0.0.1:3109/hybird"
(
  cd "${ROOT_DIR}/hybird-meumall"
  H5_BASE_PATH=/hybird \
  H5_MANIFEST_URL="http://127.0.0.1:4100/api/h5/manifest/active?environment=prod" \
  NEXT_PUBLIC_H5_MANIFEST_URL="http://127.0.0.1:4100/api/h5/manifest/active?environment=prod" \
    pnpm dev -- -p 3109
) &
H5_PID=$!

echo "Starting admin-meumall on http://127.0.0.1:5173"
(
  cd "${ROOT_DIR}/admin-meumall"
  pnpm dev -- --host 127.0.0.1 --port 5173
) &
ADMIN_PID=$!

echo
echo "Local services are starting:"
echo "- server: http://127.0.0.1:4100/api/health"
echo "- h5:     http://127.0.0.1:3109/hybird"
echo "- admin:  http://127.0.0.1:5173"
echo
echo "Press Ctrl+C to stop all services."

wait
