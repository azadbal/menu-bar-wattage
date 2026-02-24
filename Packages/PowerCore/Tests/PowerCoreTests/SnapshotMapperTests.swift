import XCTest
import IOKit.ps
@testable import PowerCore

final class SnapshotMapperTests: XCTestCase {
    func testMissingKeysMapToNilAndUnknown() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = SnapshotMapper.map(sourceDescription: [:], adapterDetails: nil, now: now)

        XCTAssertNil(snapshot.batteryCurrentmA)
        XCTAssertNil(snapshot.batteryVoltagemV)
        XCTAssertNil(snapshot.isCharging)
        XCTAssertNil(snapshot.isCharged)
        XCTAssertEqual(snapshot.powerSourceState, .unknown)
        XCTAssertNil(snapshot.adapterWatts)
        XCTAssertEqual(snapshot.timestamp, now)
    }

    func testNilAdapterDictionaryProducesNilAdapterWatts() {
        let source: [String: Any] = [
            kIOPSCurrentKey as String: 1200,
            kIOPSVoltageKey as String: 12000,
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]

        let snapshot = SnapshotMapper.map(sourceDescription: source, adapterDetails: nil, now: Date())
        XCTAssertNil(snapshot.adapterWatts)
    }

    func testPowerSourceStatesMapCorrectly() {
        let acSource: [String: Any] = [
            kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String
        ]
        let batterySource: [String: Any] = [
            kIOPSPowerSourceStateKey as String: kIOPSBatteryPowerValue as String
        ]
        let offlineSource: [String: Any] = [
            kIOPSPowerSourceStateKey as String: kIOPSOffLineValue as String
        ]

        XCTAssertEqual(SnapshotMapper.map(sourceDescription: acSource, adapterDetails: nil, now: Date()).powerSourceState, .ac)
        XCTAssertEqual(SnapshotMapper.map(sourceDescription: batterySource, adapterDetails: nil, now: Date()).powerSourceState, .battery)
        XCTAssertEqual(SnapshotMapper.map(sourceDescription: offlineSource, adapterDetails: nil, now: Date()).powerSourceState, .offline)
    }

    func testSignedCurrentAndVoltageArePreserved() {
        let source: [String: Any] = [
            kIOPSCurrentKey as String: -1500,
            kIOPSVoltageKey as String: 12000,
            kIOPSIsChargingKey as String: false,
            kIOPSPowerSourceStateKey as String: kIOPSBatteryPowerValue as String
        ]

        let snapshot = SnapshotMapper.map(sourceDescription: source, adapterDetails: nil, now: Date())
        XCTAssertEqual(snapshot.batteryCurrentmA, -1500)
        XCTAssertEqual(snapshot.batteryVoltagemV, 12000)
        XCTAssertEqual(snapshot.isCharging, false)
        XCTAssertEqual(snapshot.powerSourceState, .battery)
    }
}
