#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_mutation_fails() {
  local mode="$1"
  local filter="$2"

  if MENU_BAR_WATTAGE_MUTATION_MODE="$mode" swift test --package-path "$ROOT_DIR/Packages/PowerCore" --filter "$filter" >/tmp/mutation_guard.log 2>&1; then
    printf 'Mutation mode %s unexpectedly survived tests.\n' "$mode"
    cat /tmp/mutation_guard.log
    exit 1
  fi

  printf 'Mutation mode %s correctly failed guarded tests.\n' "$mode"
}

assert_mutation_fails "bad_divisor" "PowerDeriverTests/testPowerCalculationUsesMilliampsAndMillivolts"
assert_mutation_fails "flip_sign" "PowerDeriverTests/testPowerCalculationUsesMilliampsAndMillivolts"
