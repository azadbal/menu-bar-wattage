# App Store Readiness Checklist

## Current Policy
- Distribution policy is `Store-Only Strict`.
- Planned distribution channels are both the Mac App Store and a notarized direct-download artifact attached to a GitHub Release.
- Production telemetry path is `IOKit.ps` only.
- Private fallback paths (for example `AppleSmartBattery` IORegistry reads) are not allowed in production source or binary.

## Required Local Artifacts
- Xcode project spec: `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp/project.yml`
- Generated project: `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp/StatusbarPowerApp.xcodeproj`
- App sandbox entitlements: `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp/Resources/StatusbarPowerApp.entitlements`
- App metadata plist: `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp/Resources/Info.plist`
- App icons: `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp/Resources/Assets.xcassets/AppIcon.appiconset`

## Technical Release Gate
1. Run quality gates:
```bash
/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/test_all.sh
```
2. Run App Store preflight:
```bash
/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/app_store_preflight.sh
```
3. Confirm preflight guarantees:
- tests and mutation guards pass
- release build and archive succeed
- sandbox entitlement is present and minimal
- production sources and archived binary do not contain forbidden private telemetry symbols

## Xcode Signing Setup
1. Open `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp/StatusbarPowerApp.xcodeproj`.
2. Select `StatusbarPowerApp` target and set:
- Team
- Bundle identifier for your developer account
- Automatic signing enabled
3. Keep App Sandbox enabled with minimal entitlements.
4. Configure a separate direct-distribution path using a `Developer ID Application` certificate and Hardened Runtime. The App Store and GitHub artifacts must be signed for their respective distribution channels.

## App Store Connect Setup
1. Create app record:
- Platform: macOS
- Bundle ID matching `StatusbarPowerApp` target
- SKU, primary language, app name
2. Fill required metadata:
- Description and keywords
- Support URL
- Marketing URL (optional but recommended)
- Privacy Policy URL (required)
3. Upload screenshots in valid macOS sizes (at least one set):
- `1280x800`, `1440x900`, `2560x1600`, or `2880x1800`
4. Fill review information:
- contact details
- review notes explaining:
  - menu bar behavior
  - telemetry source uses public `IOKit.ps` APIs only
  - adapter-reported wattage semantics
  - fallback behavior when external power or adapter wattage is unavailable
5. Complete compliance forms:
- App Privacy questionnaire
- Export compliance questionnaire

## Upload and Submit
1. Archive in Xcode (`Product > Archive`) from `Release`.
2. Validate archive.
3. Distribute to App Store Connect.
4. In App Store Connect, select uploaded build and submit for review.

## GitHub Release Distribution
1. Build a separately signed Developer ID artifact; do not commit the binary into the Git repository.
2. Package `StatusbarPower.app` as a versioned ZIP or DMG.
3. Submit the package to Apple with `xcrun notarytool` and staple the ticket with `xcrun stapler`.
4. Verify the notarized artifact with `spctl` before publishing.
5. Attach the notarized package and a SHA-256 checksum to the matching GitHub Release.
6. Keep the GitHub artifact and Mac App Store build identifiable as separate distribution artifacts, even when they share the same app version.

## Product Messaging Requirements
- Explain metric semantics clearly:
  - `Adapter Power` is adapter-reported wattage, not guaranteed charge rate or total Mac power consumption.
  - the compact status shows `NNW` when external power and adapter wattage are available.
  - the compact status shows `\` on battery and `-` when power state or adapter wattage is unavailable.
  - the click menu is compact, names the app, shows one current-state line (`NNW from charging adapter.`, `Using battery power. No charging detected.`, or an unavailable-state message), and includes Launch at Login and Quit.
  - the click menu does not present a historical battery-power chart or a Last Updated timestamp.

## If Rejected
1. Capture exact rejection reason and category.
2. Add/adjust automated test coverage reproducing the issue.
3. Update this checklist and `/Users/azadbalabanian/Desktop/DEV/statusbar_power/docs/backpressure.md`.
4. Re-run:
```bash
/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/app_store_preflight.sh
```
