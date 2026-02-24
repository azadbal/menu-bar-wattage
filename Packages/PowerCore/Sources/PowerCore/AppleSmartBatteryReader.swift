import Foundation
import IOKit

struct AppleSmartBatterySnapshot: Equatable {
    let amperagemA: Int?
    let voltagemV: Int?
    let isCharging: Bool?
    let externalConnected: Bool?
    let externalChargeCapable: Bool?
}

final class AppleSmartBatteryReader {
    func readSnapshot() -> AppleSmartBatterySnapshot? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else {
            return nil
        }

        defer { IOObjectRelease(service) }

        return AppleSmartBatterySnapshot(
            amperagemA: intProperty(named: "Amperage", from: service),
            voltagemV: intProperty(named: "Voltage", from: service),
            isCharging: boolProperty(named: "IsCharging", from: service),
            externalConnected: boolProperty(named: "ExternalConnected", from: service),
            externalChargeCapable: boolProperty(named: "ExternalChargeCapable", from: service)
        )
    }

    private func intProperty(named key: String, from service: io_registry_entry_t) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            return nil
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        return nil
    }

    private func boolProperty(named key: String, from service: io_registry_entry_t) -> Bool? {
        guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            return nil
        }

        if let boolValue = value as? Bool {
            return boolValue
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        return nil
    }
}
