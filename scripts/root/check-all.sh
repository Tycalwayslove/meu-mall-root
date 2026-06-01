#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "== hybird-meumall workflow =="
(cd "${ROOT_DIR}/hybird-meumall" && pnpm run ai:check-workflow)

echo
echo "== server-meumall workflow =="
(cd "${ROOT_DIR}/server-meumall" && python3 scripts/ai/check_workflow.py)

echo
echo "== admin-meumall workflow =="
(cd "${ROOT_DIR}/admin-meumall" && pnpm run ai:check-workflow)

echo
echo "== app-meumall workflow =="
(
  cd "${ROOT_DIR}/app-meumall"
  bash scripts/ai/check-workflow.sh
  plutil -lint meumall/Info.plist
)

echo
echo "All MeuMall workflow checks passed."
