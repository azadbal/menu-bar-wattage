import XCTest
@testable import PowerCore

final class PowerDeriverTests: XCTestCase {
    func testPowerCalculationUsesMilliampsAndMillivolts() {
        let snapshot = RawPowerSnapshot(
            batteryCurrentmA: 2000,
            batteryVoltagemV: 12000,
            isCharging: true,
            isCharged: false,
            powerSourceState: .ac,
            adapterWatts: 70,
            timestamp: Date()
        )

        let derived = PowerDeriver.derive(from: snapshot)
        XCTAssertEqual(derived.batteryPowerW ?? .nan, 24.0, accuracy: 0.0001)
        XCTAssertEqual(derived.adapterWatts, 70)
        XCTAssertEqual(derived.chargeState, .charging)
    }

    func testMissingCurrentOrVoltageProducesNilPower() {
        let missingCurrent = RawPowerSnapshot(
            batteryCurrentmA: nil,
            batteryVoltagemV: 12000,
            isCharging: true,
            isCharged: false,
            powerSourceState: .ac,
            adapterWatts: nil,
            timestamp: Date()
        )

        let missingVoltage = RawPowerSnapshot(
            batteryCurrentmA: 2000,
            batteryVoltagemV: nil,
            isCharging: true,
            isCharged: false,
            powerSourceState: .ac,
            adapterWatts: nil,
            timestamp: Date()
        )

        XCTAssertNil(PowerDeriver.derive(from: missingCurrent).batteryPowerW)
        XCTAssertNil(PowerDeriver.derive(from: missingVoltage).batteryPowerW)
    }

    func testChargeStateTransitions() {
        let charging = RawPowerSnapshot(
            batteryCurrentmA: 1000,
            batteryVoltagemV: 12000,
            isCharging: true,
            isCharged: false,
            powerSourceState: .ac,
            adapterWatts: 70,
            timestamp: Date()
        )
        let discharging = RawPowerSnapshot(
            batteryCurrentmA: -1000,
            batteryVoltagemV: 12000,
            isCharging: false,
            isCharged: false,
            powerSourceState: .battery,
            adapterWatts: nil,
            timestamp: Date()
        )
        let charged = RawPowerSnapshot(
            batteryCurrentmA: 0,
            batteryVoltagemV: 12000,
            isCharging: false,
            isCharged: true,
            powerSourceState: .ac,
            adapterWatts: 70,
            timestamp: Date()
        )

        XCTAssertEqual(PowerDeriver.derive(from: charging).chargeState, .charging)
        XCTAssertEqual(PowerDeriver.derive(from: discharging).chargeState, .discharging)
        XCTAssertEqual(PowerDeriver.derive(from: charged).chargeState, .charged)
    }

    func testUnreasonablePowerIsRejected() {
        let absurd = RawPowerSnapshot(
            batteryCurrentmA: 30_000,
            batteryVoltagemV: 20_000,
            isCharging: true,
            isCharged: false,
            powerSourceState: .ac,
            adapterWatts: 140,
            timestamp: Date()
        )

        XCTAssertNil(PowerDeriver.derive(from: absurd).batteryPowerW)
    }
}
