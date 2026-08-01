# Manual Hardware Verification Checklist

## Preconditions
- For the Launch at Login test, use the signed Release copy installed at `/Applications/MenuBarWattage.app`.
- Confirm a status item appears in the menu bar.
- Click the status item and confirm the menu is compact, names Menu Bar Wattage, shows one current-state line, and contains Launch at Login and Quit.
- Run `/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/diagnose_live_power.sh` to capture current telemetry baselines.
- Keep `pmset -g batt` running in a separate terminal for reference.

## Scenario 1: No External Power
- Disconnect external power.
- Expected status label: `\`.
- Confirm the menu says `Using battery power. No charging detected.`.

## Scenario 2: Plug-In and Charging Ramp
- Connect power.
- Expected status transition within a few seconds: `NNW` (rounded watts).
- Confirm the menu says `NNW from charging adapter.` and does not repeat the wattage in separate Status and Adapter rows.
- Toggle `Launch at Login` on, quit and relaunch the app, then confirm the menu item remains enabled. Toggle it back off after testing if desired.

The final restart verification is intentionally manual: after enabling Launch at Login, quit the app and restart macOS, then confirm the menu-bar item appears automatically. This is the remaining user-owned test.

## Scenario 3: AC Connected While Full or Near Full
- Leave device on AC near 100%.
- Expected status label: `NNW` using the adapter-reported wattage.
- Confirm app remains responsive and no crashes occur.

## Scenario 4: Rapid Plug/Unplug
- Toggle adapter connection 3-5 times.
- Expected result:
- No app crashes.
- Status transitions between `\` and `NNW` as the external power source changes, including while the detail menu remains open.

## Scenario 5: High Load on Charger
- Run a CPU load (`yes > /dev/null` in multiple terminals, then stop).
- Expected result:
- The app remains responsive without UI lockups. The adapter-reported wattage may remain unchanged because it is not a real-time Mac power draw measurement.

## Completion Criteria
- All scenarios pass without crash or stuck menu bar text.
- Any mismatch is documented with timestamp and reproduced with fixture updates in `/Users/azadbalabanian/Desktop/DEV/statusbar_power/Fixtures/power`.
