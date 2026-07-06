#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "== hybird-meumall workflow =="
(cd "${ROOT_DIR}/hybird-meumall" && pnpm run ai:check-workflow)

echo
echo "MeuMall H5 workflow checks passed."
