# Manual Hardware Verification Checklist

## Preconditions
- Build and launch the app from `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp`.
- Confirm a status item appears in the menu bar.
- Run `/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/diagnose_live_power.sh` to capture current telemetry baselines.
- Keep `pmset -g batt` running in a separate terminal for reference.

## Scenario 1: Battery Discharging
- Disconnect external power.
- Expected status label: `On Battery`.
- Expected diagnostics panel:
- `Battery Power` is available and typically negative.
- History line updates once per second.

## Scenario 2: Plug-In and Charging Ramp
- Connect power.
- Expected status transition within a few seconds: `NNW` (rounded watts).
- Expected diagnostics panel:
- `Adapter Power` should show a watt value if available.
- `Battery Power` should trend positive.

## Scenario 3: AC Connected While Full or Near Full
- Leave device on AC near 100%.
- Expected status label: `Charged` or `No Data` if charging metrics are unavailable.
- Confirm app remains responsive and no crashes occur.

## Scenario 4: Rapid Plug/Unplug
- Toggle adapter connection 3-5 times.
- Expected result:
- No app crashes.
- Status transitions between `On Battery`, `NNW`, and `Charged`/`No Data` as source changes.

## Scenario 5: High Load on Charger
- Run a CPU load (`yes > /dev/null` in multiple terminals, then stop).
- Expected result:
- Charging watts/history update without UI lockups.
- Chart remains bounded to the latest 30-minute window.

## Completion Criteria
- All scenarios pass without crash or stuck menu bar text.
- Any mismatch is documented with timestamp and reproduced with fixture updates in `/Users/azadbalabanian/Desktop/DEV/statusbar_power/Fixtures/power`.
