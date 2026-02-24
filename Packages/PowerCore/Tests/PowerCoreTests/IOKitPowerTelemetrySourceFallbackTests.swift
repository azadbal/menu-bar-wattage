import XCTest
import IOKit.ps
@testable import PowerCore

final class IOKitPowerTelemetrySourceFallbackTests: XCTestCase {
    func testUsesSmartBatteryVoltageWhenIOPSVoltageMissing() {
        let sourceDescription: [String: Any] = [
            kIOPSCurrentKey as String: 2500,
            kIOPSIsChargingKey as String: true,
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]
        let adapterDetails: [String: Any] = [
            kIOPSPowerAdapterWattsKey as String: 96
        ]
        let smartBattery = AppleSmartBatterySnapshot(
            amperagemA: 2600,
            voltagemV: 12500,
            isCharging: true,
            externalConnected: true,
            externalChargeCapable: true
        )

        let snapshot = IOKitPowerTelemetrySource.mergedSnapshot(
            sourceDescription: sourceDescription,
            adapterDetails: adapterDetails,
            smartBatterySnapshot: smartBattery,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let derived = PowerDeriver.derive(from: snapshot)

        XCTAssertEqual(snapshot.batteryCurrentmA, 2500)
        XCTAssertEqual(snapshot.batteryVoltagemV, 12500)
        XCTAssertEqual(snapshot.isCharging, true)
        XCTAssertEqual(snapshot.adapterWatts, 96)
        XCTAssertEqual(derived.batteryPowerW ?? .nan, 31.25, accuracy: 0.0001)
    }

    func testUsesSmartBatteryCurrentWhenIOPSCurrentMissing() {
        let sourceDescription: [String: Any] = [
            kIOPSVoltageKey as String: 12200,
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]
        let smartBattery = AppleSmartBatterySnapshot(
            amperagemA: 2300,
            voltagemV: 12600,
            isCharging: true,
            externalConnected: true,
            externalChargeCapable: true
        )

        let snapshot = IOKitPowerTelemetrySource.mergedSnapshot(
            sourceDescription: sourceDescription,
            adapterDetails: nil,
            smartBatterySnapshot: smartBattery,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let derived = PowerDeriver.derive(from: snapshot)

        XCTAssertEqual(snapshot.batteryCurrentmA, 2300)
        XCTAssertEqual(snapshot.batteryVoltagemV, 12200)
        XCTAssertEqual(snapshot.isCharging, true)
        XCTAssertEqual(derived.batteryPowerW ?? .nan, 28.06, accuracy: 0.0001)
    }

    func testKeepsNilPowerWhenBothSourcesMissingCurrentOrVoltage() {
        let sourceDescription: [String: Any] = [
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String,
            kIOPSIsChargingKey as String: true
        ]
        let smartBattery = AppleSmartBatterySnapshot(
            amperagemA: nil,
            voltagemV: nil,
            isCharging: true,
            externalConnected: true,
            externalChargeCapable: true
        )

        let snapshot = IOKitPowerTelemetrySource.mergedSnapshot(
            sourceDescription: sourceDescription,
            adapterDetails: nil,
            smartBatterySnapshot: smartBattery,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let derived = PowerDeriver.derive(from: snapshot)

        XCTAssertNil(snapshot.batteryCurrentmA)
        XCTAssertNil(snapshot.batteryVoltagemV)
        XCTAssertNil(derived.batteryPowerW)
    }
}
