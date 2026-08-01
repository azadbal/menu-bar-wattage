#!/usr/bin/env bash
set -euo pipefail

printf '=== pmset -g batt ===\n'
pmset -g batt

printf '\n=== IOPS + Adapter Details ===\n'
swift - <<'SWIFT'
import Foundation
import IOKit.ps

let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array

if list.isEmpty {
    print("No power sources found")
} else {
    for (index, source) in list.enumerated() {
        guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else {
            continue
        }

        let current = (description[kIOPSCurrentKey as String] as? NSNumber)?.intValue
        let voltage = (description[kIOPSVoltageKey as String] as? NSNumber)?.intValue
        let isCharging = (description[kIOPSIsChargingKey as String] as? NSNumber)?.boolValue
        let state = description[kIOPSPowerSourceStateKey as String] as? String
        let stateLabel = state ?? "nil"

        print("source[\(index)] current(mA)=\(String(describing: current)) voltage(mV)=\(String(describing: voltage)) isCharging=\(String(describing: isCharging)) state=\(stateLabel)")

        if let current, let voltage {
            let batteryWatts = (Double(current) * Double(voltage)) / 1_000_000.0
            print("source[\(index)] derived battery watts=\(batteryWatts)")
        } else {
            print("source[\(index)] derived battery watts unavailable (missing current or voltage)")
        }
    }
}

if let adapterDetails = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any] {
    let adapterWatts = (adapterDetails[kIOPSPowerAdapterWattsKey as String] as? NSNumber)?.intValue
    let adapterCurrent = (adapterDetails[kIOPSPowerAdapterCurrentKey as String] as? NSNumber)?.intValue
    print("adapter watts=\(String(describing: adapterWatts)) current(mA)=\(String(describing: adapterCurrent))")
} else {
    print("adapter details unavailable")
}
SWIFT
