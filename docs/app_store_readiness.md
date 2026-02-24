# App Store Readiness Checklist

## Scope
Phase 6 hardening tasks to complete after MVP behavior is verified.

## Sandbox and Entitlements
- Enable App Sandbox in release signing profile.
- Keep entitlements minimal; avoid unnecessary capabilities.
- Verify power telemetry APIs used are public and available under sandbox.

## API Compliance
- Confirm only public frameworks are used:
- `IOKit.ps`
- `AppKit`
- `SwiftUI`
- `Charts`
- Verify no private symbols or private entitlement usage.

## Build and Archive
- Produce release archive using Xcode organizer or `xcodebuild archive` in a dedicated project/workspace flow.
- Validate app launches and displays safe fallback states if telemetry is unavailable.

## Validation
- Re-run full local gate suite before archive:
```bash
/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/test_all.sh
```
- Re-run manual checklist on sandboxed build.

## Release Notes Expectations
- Document that adapter watts represents adapter-reported capability/readout.
- Document that battery watts reflects computed charge/discharge power from battery current/voltage when available.
- Document fallback behavior for unsupported devices.
