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

printf '\n=== AppleSmartBattery Registry ===\n'
swift - <<'SWIFT'
import Foundation
import IOKit

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
guard service != 0 else {
    print("AppleSmartBattery service unavailable")
    exit(0)
}

defer { IOObjectRelease(service) }

func intProperty(_ key: String) -> Int? {
    guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
        return nil
    }
    return (value as? NSNumber)?.intValue
}

func boolProperty(_ key: String) -> Bool? {
    guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
        return nil
    }
    if let boolValue = value as? Bool {
        return boolValue
    }
    return (value as? NSNumber)?.boolValue
}

let amperage = intProperty("Amperage")
let voltage = intProperty("Voltage")
let isCharging = boolProperty("IsCharging")
let externalConnected = boolProperty("ExternalConnected")
let externalChargeCapable = boolProperty("ExternalChargeCapable")

print("amperage(mA)=\(String(describing: amperage))")
print("voltage(mV)=\(String(describing: voltage))")
print("isCharging=\(String(describing: isCharging))")
print("externalConnected=\(String(describing: externalConnected))")
print("externalChargeCapable=\(String(describing: externalChargeCapable))")

if let amperage, let voltage {
    let watts = (Double(amperage) * Double(voltage)) / 1_000_000.0
    print("derived battery watts=\(watts)")
}
SWIFT
