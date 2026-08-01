# Manual Hardware Verification Checklist

## Preconditions
- Build and launch the app from `/Users/azadbalabanian/Desktop/DEV/statusbar_power/StatusbarPowerApp`.
- Confirm a status item appears in the menu bar.
- Run `/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/diagnose_live_power.sh` to capture current telemetry baselines.
- Keep `pmset -g batt` running in a separate terminal for reference.

## Scenario 1: No External Power
- Disconnect external power.
- Expected status label: `-`.
- Confirm the menu explains that no external power is connected.

## Scenario 2: Plug-In and Charging Ramp
- Connect power.
- Expected status transition within a few seconds: `NNW` (rounded watts).
- Expected diagnostics panel:
- `Adapter Power` should show a watt value if available.

## Scenario 3: AC Connected While Full or Near Full
- Leave device on AC near 100%.
- Expected status label: `NNW` using the adapter-reported wattage.
- Confirm app remains responsive and no crashes occur.

## Scenario 4: Rapid Plug/Unplug
- Toggle adapter connection 3-5 times.
- Expected result:
- No app crashes.
- Status transitions between `-` and `NNW` as the external power source changes.

## Scenario 5: High Load on Charger
- Run a CPU load (`yes > /dev/null` in multiple terminals, then stop).
- Expected result:
- Adapter wattage/status updates without UI lockups.

## Completion Criteria
- All scenarios pass without crash or stuck menu bar text.
- Any mismatch is documented with timestamp and reproduced with fixture updates in `/Users/azadbalabanian/Desktop/DEV/statusbar_power/Fixtures/power`.
