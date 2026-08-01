#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/MenuBarWattageApp"
PROJECT_PATH="$APP_DIR/MenuBarWattageApp.xcodeproj"
SCHEME="MenuBarWattageApp"
DERIVED_DATA_PATH="$ROOT_DIR/.build/app_store_derived_data"
ARCHIVE_PATH="$ROOT_DIR/.build/archives/MenuBarWattageApp.xcarchive"
ENTITLEMENTS_PATH="$APP_DIR/Resources/MenuBarWattageApp.entitlements"

for command_name in xcodegen xcodebuild rg python3 strings; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command_name"
    if [[ "$command_name" == "xcodegen" ]]; then
      printf 'Install with: brew install xcodegen\n'
    fi
    exit 1
  fi
done

printf '\n[1/7] Running test suite and mutation guards...\n'
"$ROOT_DIR/scripts/test_all.sh"

printf '\n[2/7] Regenerating Xcode project from spec...\n'
(
  cd "$APP_DIR"
  xcodegen generate
)

printf '\n[3/7] Building release configuration...\n'
rm -rf "$DERIVED_DATA_PATH"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build >/tmp/menu_bar_wattage_release_build.log

printf '\n[4/7] Archiving app bundle...\n'
rm -rf "$ARCHIVE_PATH"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -archivePath "$ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  CODE_SIGNING_ALLOWED=NO \
  archive >/tmp/menu_bar_wattage_archive.log

if [[ ! -d "$ARCHIVE_PATH" ]]; then
  printf 'Archive missing at %s\n' "$ARCHIVE_PATH"
  exit 1
fi

APP_BINARY="$ARCHIVE_PATH/Products/Applications/MenuBarWattage.app/Contents/MacOS/MenuBarWattage"
if [[ ! -f "$APP_BINARY" ]]; then
  printf 'Archived app binary missing at %s\n' "$APP_BINARY"
  exit 1
fi

printf '\n[5/7] Validating sandbox entitlements...\n'
python3 - <<'PY' "$ENTITLEMENTS_PATH"
import plistlib
import sys

path = sys.argv[1]
with open(path, 'rb') as f:
    ent = plistlib.load(f)

if ent.get('com.apple.security.app-sandbox') is not True:
    raise SystemExit('Missing required com.apple.security.app-sandbox=true entitlement')

allowed_keys = {'com.apple.security.app-sandbox'}
extra = sorted(set(ent.keys()) - allowed_keys)
if extra:
    raise SystemExit('Unexpected entitlements present: ' + ', '.join(extra))

print('Entitlements are minimal and sandboxed')
PY

printf '\n[6/7] Scanning sources for forbidden private API paths...\n'
if rg -n "AppleSmartBattery|IORegistryEntryCreateCFProperty|IOServiceMatching\\(\"AppleSmartBattery\"\)" \
  "$ROOT_DIR/Packages/PowerCore/Sources" \
  "$ROOT_DIR/MenuBarWattageApp/Sources"; then
  printf 'Forbidden private telemetry symbols found in production sources.\n'
  exit 1
fi

printf '\n[7/7] Scanning archived binary strings for forbidden symbols...\n'
if strings "$APP_BINARY" | rg -n "AppleSmartBattery|IORegistryEntryCreateCFProperty|IOServiceMatching\\(\"AppleSmartBattery\"\)"; then
  printf 'Forbidden private telemetry symbols found in archived binary.\n'
  exit 1
fi

printf '\nApp Store preflight completed successfully.\n'
printf 'Archive: %s\n' "$ARCHIVE_PATH"
