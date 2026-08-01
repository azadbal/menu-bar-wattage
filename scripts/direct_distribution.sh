#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/StatusbarPowerApp"
PROJECT_PATH="$APP_DIR/StatusbarPowerApp.xcodeproj"
SCHEME="StatusbarPowerApp"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.build/direct_distribution_derived_data}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/.build/archives/StatusbarPowerApp-direct.xcarchive}"
ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT_DIR/.build/direct_distribution}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
RELEASE_TAG="${RELEASE_TAG:-}"

usage() {
  cat <<'EOF'
Usage: scripts/direct_distribution.sh [--publish]

Builds, signs, notarizes, staples, and verifies the direct-distribution ZIP.

Required environment:
  NOTARY_PROFILE   notarytool keychain profile name

Optional environment:
  SIGNING_IDENTITY Developer ID signing identity (default: Developer ID Application)
  MARKETING_VERSION version passed to xcodebuild (default: project value)
  CURRENT_PROJECT_VERSION build number passed to xcodebuild (default: project value)
  RELEASE_TAG      GitHub Release tag, required with --publish
  DERIVED_DATA_PATH, ARCHIVE_PATH, ARTIFACT_DIR override build output paths

Pass --publish to upload the ZIP and its SHA-256 checksum with gh to RELEASE_TAG.
EOF
}

publish=false
case "${1:-}" in
  "") ;;
  --publish) publish=true ;;
  --help|-h) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

for command_name in xcodebuild xcodegen codesign ditto xcrun spctl shasum rg; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  fi
done

if [[ ! -x /usr/libexec/PlistBuddy ]]; then
  printf 'Missing required command: /usr/libexec/PlistBuddy\n' >&2
  exit 1
fi

if [[ -z "$NOTARY_PROFILE" ]]; then
  printf 'NOTARY_PROFILE must name a configured xcrun notarytool keychain profile.\n' >&2
  exit 1
fi

if [[ "$publish" == true ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    printf 'Missing required command: gh (needed for --publish)\n' >&2
    exit 1
  fi
  if [[ -z "$RELEASE_TAG" ]]; then
    printf 'RELEASE_TAG is required with --publish.\n' >&2
    exit 1
  fi
fi

(
  cd "$APP_DIR"
  xcodegen generate
)

rm -rf "$DERIVED_DATA_PATH" "$ARCHIVE_PATH" "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

build_settings=(
  CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY"
  DEVELOPMENT_TEAM=2F328AJX43
  ENABLE_HARDENED_RUNTIME=YES
  ARCHS=arm64
  OTHER_CODE_SIGN_FLAGS="--timestamp"
)
if [[ -n "${MARKETING_VERSION:-}" ]]; then
  build_settings+=("MARKETING_VERSION=$MARKETING_VERSION")
fi
if [[ -n "${CURRENT_PROJECT_VERSION:-}" ]]; then
  build_settings+=("CURRENT_PROJECT_VERSION=$CURRENT_PROJECT_VERSION")
fi

printf '[1/5] Archiving signed Developer ID app...\n'
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -archivePath "$ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  "${build_settings[@]}" \
  archive

APP_PATH="$ARCHIVE_PATH/Products/Applications/StatusbarPower.app"
if [[ ! -d "$APP_PATH" ]]; then
  printf 'Archived app missing at %s\n' "$APP_PATH" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
ZIP_PATH="$ARTIFACT_DIR/StatusbarPower-$VERSION-$BUILD-macOS-arm64.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

printf '[2/5] Verifying Developer ID signature and Hardened Runtime...\n'
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign --display --verbose=4 "$APP_PATH" 2>&1 | rg -q 'flags=0x10000\(runtime\)' || {
  printf 'Hardened Runtime is not enabled on the archived app.\n' >&2
  exit 1
}

printf '[3/5] Creating and notarizing ZIP...\n'
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

printf '[4/5] Stapling and verifying notarization...\n'
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

FINAL_VERIFY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/statusbar-power-verify.XXXXXX")"
trap 'rm -rf "$FINAL_VERIFY_DIR"' EXIT
ditto -x -k "$ZIP_PATH" "$FINAL_VERIFY_DIR"
spctl --assess --type execute --verbose=4 "$FINAL_VERIFY_DIR/StatusbarPower.app"

printf '[5/5] Direct-distribution artifacts ready.\n'
printf 'ZIP: %s\nSHA-256: %s\n' "$ZIP_PATH" "$CHECKSUM_PATH"

if [[ "$publish" == true ]]; then
  if [[ "$RELEASE_TAG" != "v$VERSION" && "$RELEASE_TAG" != "$VERSION" ]]; then
    printf 'RELEASE_TAG %s does not match app version %s.\n' "$RELEASE_TAG" "$VERSION" >&2
    exit 1
  fi
  RELEASE_TAG_FROM_GITHUB="$(gh release view "$RELEASE_TAG" --json tagName --jq '.tagName')"
  if [[ "$RELEASE_TAG_FROM_GITHUB" != "$RELEASE_TAG" ]]; then
    printf 'GitHub Release %s was not found.\n' "$RELEASE_TAG" >&2
    exit 1
  fi
  gh release upload "$RELEASE_TAG" "$ZIP_PATH" "$CHECKSUM_PATH" --clobber
  printf 'Published to GitHub Release: %s\n' "$RELEASE_TAG"
fi
