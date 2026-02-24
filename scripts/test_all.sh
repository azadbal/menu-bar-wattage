#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '\n[1/4] Running PowerCore tests...\n'
swift test --package-path "$ROOT_DIR/Packages/PowerCore"

printf '\n[2/4] Running StatusbarPowerApp tests...\n'
swift test --package-path "$ROOT_DIR/StatusbarPowerApp"

printf '\n[3/4] Running mutation guards...\n'
"$ROOT_DIR/scripts/mutation_guard.sh"

printf '\n[4/4] Running formatting/lint checks...\n'
if command -v swift-format >/dev/null 2>&1; then
  swift-format lint -r "$ROOT_DIR/Packages/PowerCore/Sources" "$ROOT_DIR/StatusbarPowerApp/Sources"
else
  printf 'swift-format not found; skipping lint step.\n'
fi

printf '\nAll local quality gates passed.\n'
