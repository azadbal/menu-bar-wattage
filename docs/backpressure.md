# AI Dev Backpressure Contract

This document defines the blocking quality gates for this project.

## Goal Lock
- Primary goal: a macOS menu bar app that reports adapter-reported watts when external power is connected.
- Accepted compact status values: `NNW` when adapter watts are available, `-` otherwise.
- Adapter watts are not a claim about real-time battery charging rate or total Mac power consumption.

## Mandatory Gates
1. No production behavior change without a failing test or fixture first.
2. Any telemetry parsing change must update fixture replay coverage.
3. Formula and charge-state transitions must be deterministic under unit tests before UI wiring changes.
4. Status label and dropdown string changes must include view-model assertion updates.
5. A phase is not done until `scripts/test_all.sh` passes and manual checklist is completed.

## Automated Gates
- Run all local checks:
```bash
/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/test_all.sh
```

- Run App Store preflight gate:
```bash
/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/app_store_preflight.sh
```

- Run mutation guard only:
```bash
/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/mutation_guard.sh
```

## Mutation Strategy
`PowerDeriver` accepts debug-only mutation mode via `STATUSBAR_POWER_MUTATION_MODE`.
- `bad_divisor`: uses the wrong conversion divisor.
- `flip_sign`: inverts computed battery watt sign.

The mutation guard script expects both modes to fail protected tests. A mutation surviving means tests are insufficient and must be strengthened before continuing.

## Runtime Invariants
- Non-finite battery power is rejected.
- Absurd battery power (`> 300W` absolute) is rejected.

## Manual Validation Trigger
After automated gates pass, complete:
- `/Users/azadbalabanian/Desktop/DEV/statusbar_power/scripts/manual_checklist.md`

Any manual discrepancy requires:
1. fixture capture/update under `/Users/azadbalabanian/Desktop/DEV/statusbar_power/Fixtures/power`
2. a new or strengthened automated test reproducing the mismatch
3. a re-run of `scripts/test_all.sh`
