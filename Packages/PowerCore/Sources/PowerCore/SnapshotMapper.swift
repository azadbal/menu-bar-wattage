import Foundation
import IOKit.ps

enum SnapshotMapper {
    static func map(sourceDescription: [String: Any], adapterDetails: [String: Any]?, now: Date) -> RawPowerSnapshot {
        RawPowerSnapshot(
            batteryCurrentmA: intValue(for: kIOPSCurrentKey as String, in: sourceDescription),
            batteryVoltagemV: intValue(for: kIOPSVoltageKey as String, in: sourceDescription),
            isCharging: boolValue(for: kIOPSIsChargingKey as String, in: sourceDescription),
            isCharged: boolValue(for: kIOPSIsChargedKey as String, in: sourceDescription),
            powerSourceState: powerSourceState(from: sourceDescription[kIOPSPowerSourceStateKey as String]),
            adapterWatts: intValue(for: kIOPSPowerAdapterWattsKey as String, in: adapterDetails),
            timestamp: now
        )
    }

    static func isInternalBattery(_ sourceDescription: [String: Any]) -> Bool {
        let type = sourceDescription[kIOPSTypeKey as String] as? String
        if type == (kIOPSInternalBatteryType as String) {
            return true
        }

        let transport = sourceDescription[kIOPSTransportTypeKey as String] as? String
        return transport == (kIOPSInternalType as String)
    }

    private static func intValue(for key: String, in dictionary: [String: Any]?) -> Int? {
        guard let dictionary else {
            return nil
        }

        if let value = dictionary[key] as? Int {
            return value
        }

        if let value = dictionary[key] as? NSNumber {
            return value.intValue
        }

        return nil
    }

    private static func boolValue(for key: String, in dictionary: [String: Any]) -> Bool? {
        if let value = dictionary[key] as? Bool {
            return value
        }

        if let value = dictionary[key] as? NSNumber {
            return value.boolValue
        }

        return nil
    }

    private static func powerSourceState(from value: Any?) -> PowerSourceState {
        guard let value = value as? String else {
            return .unknown
        }

        if value == (kIOPSACPowerValue as String) {
            return .ac
        }

        if value == (kIOPSBatteryPowerValue as String) {
            return .battery
        }

        if value == (kIOPSOffLineValue as String) {
            return .offline
        }

        return .unknown
    }
}
