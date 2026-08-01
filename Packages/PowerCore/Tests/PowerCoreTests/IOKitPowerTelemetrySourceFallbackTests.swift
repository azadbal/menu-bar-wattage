import XCTest
import IOKit.ps
@testable import PowerCore

final class IOKitPowerTelemetrySourceFallbackTests: XCTestCase {
    func testUsesIOPSBatteryValuesWhenPresent() {
        let sourceDescription: [String: Any] = [
            kIOPSCurrentKey as String: 2500,
            kIOPSVoltageKey as String: 12500,
            kIOPSIsChargingKey as String: true,
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]
        let adapterDetails: [String: Any] = [
            kIOPSPowerAdapterWattsKey as String: 96
        ]

        let snapshot = IOKitPowerTelemetrySource.mergedSnapshot(
            sourceDescription: sourceDescription,
            adapterDetails: adapterDetails,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let derived = PowerDeriver.derive(from: snapshot)

        XCTAssertEqual(snapshot.batteryCurrentmA, 2500)
        XCTAssertEqual(snapshot.batteryVoltagemV, 12500)
        XCTAssertEqual(snapshot.isCharging, true)
        XCTAssertEqual(snapshot.adapterWatts, 96)
        XCTAssertEqual(derived.batteryPowerW ?? .nan, 31.25, accuracy: 0.0001)
    }

    func testKeepsNilVoltageWhenIOPSVoltageMissing() {
        let sourceDescription: [String: Any] = [
            kIOPSCurrentKey as String: 2300,
            kIOPSIsChargingKey as String: true,
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]
        let adapterDetails: [String: Any] = [
            kIOPSPowerAdapterWattsKey as String: 65
        ]

        let snapshot = IOKitPowerTelemetrySource.mergedSnapshot(
            sourceDescription: sourceDescription,
            adapterDetails: adapterDetails,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let derived = PowerDeriver.derive(from: snapshot)

        XCTAssertEqual(snapshot.batteryCurrentmA, 2300)
        XCTAssertNil(snapshot.batteryVoltagemV)
        XCTAssertEqual(snapshot.isCharging, true)
        XCTAssertEqual(snapshot.adapterWatts, 65)
        XCTAssertNil(derived.batteryPowerW)
        XCTAssertEqual(derived.chargeState, .charging)
    }

    func testKeepsNilPowerWhenCurrentOrVoltageMissing() {
        let missingCurrentSource: [String: Any] = [
            kIOPSVoltageKey as String: 12200,
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]
        let missingVoltageSource: [String: Any] = [
            kIOPSCurrentKey as String: 2300,
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]

        let missingCurrent = IOKitPowerTelemetrySource.mergedSnapshot(
            sourceDescription: missingCurrentSource,
            adapterDetails: nil,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let missingVoltage = IOKitPowerTelemetrySource.mergedSnapshot(
            sourceDescription: missingVoltageSource,
            adapterDetails: nil,
            now: Date(timeIntervalSince1970: 1_700_000_001)
        )

        XCTAssertNil(PowerDeriver.derive(from: missingCurrent).batteryPowerW)
        XCTAssertNil(PowerDeriver.derive(from: missingVoltage).batteryPowerW)
    }
}
