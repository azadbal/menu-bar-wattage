import XCTest
import IOKit.ps
@testable import PowerCore

final class FixtureReplayTests: XCTestCase {
    func testFixturesReplayDeterministically() throws {
        let fixtureDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/power")

        let fixtureFiles = try FileManager.default.contentsOfDirectory(at: fixtureDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        XCTAssertFalse(fixtureFiles.isEmpty, "Expected at least one power fixture file")

        let decoder = JSONDecoder()

        for file in fixtureFiles {
            let data = try Data(contentsOf: file)
            let fixture = try decoder.decode(PowerFixture.self, from: data)

            let source = fixture.source.asPowerSourceDictionary()
            let adapter = fixture.adapter?.asAdapterDictionary()
            let now = Date(timeIntervalSince1970: fixture.timestamp)

            let snapshot = IOKitPowerTelemetrySource.mergedSnapshot(
                sourceDescription: source,
                adapterDetails: adapter,
                now: now
            )
            let derived = PowerDeriver.derive(from: snapshot)

            XCTAssertEqual(snapshot.batteryCurrentmA, fixture.expected.batteryCurrentmA, "Fixture \(file.lastPathComponent) current mismatch")
            XCTAssertEqual(snapshot.batteryVoltagemV, fixture.expected.batteryVoltagemV, "Fixture \(file.lastPathComponent) voltage mismatch")
            XCTAssertEqual(snapshot.isCharging, fixture.expected.isCharging, "Fixture \(file.lastPathComponent) isCharging mismatch")
            XCTAssertEqual(snapshot.isCharged, fixture.expected.isCharged, "Fixture \(file.lastPathComponent) isCharged mismatch")
            XCTAssertEqual(snapshot.powerSourceState, fixture.expected.powerSourceState, "Fixture \(file.lastPathComponent) state mismatch")
            XCTAssertEqual(snapshot.adapterWatts, fixture.expected.adapterWatts, "Fixture \(file.lastPathComponent) adapter mismatch")
            XCTAssertEqual(derived.chargeState, fixture.expected.chargeState, "Fixture \(file.lastPathComponent) charge state mismatch")

            if let expectedBatteryPowerW = fixture.expected.batteryPowerW {
                XCTAssertEqual(derived.batteryPowerW ?? .nan, expectedBatteryPowerW, accuracy: 0.0001, "Fixture \(file.lastPathComponent) battery power mismatch")
            } else {
                XCTAssertNil(derived.batteryPowerW, "Fixture \(file.lastPathComponent) expected nil battery power")
            }
        }
    }
}

private struct PowerFixture: Codable {
    let timestamp: TimeInterval
    let source: FixtureSource
    let adapter: FixtureAdapter?
    let expected: FixtureExpected
}

private struct FixtureSource: Codable {
    let currentmA: Int?
    let voltagemV: Int?
    let isCharging: Bool?
    let isCharged: Bool?
    let powerSourceState: String?
    let internalBatteryType: Bool

    func asPowerSourceDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]

        if let currentmA {
            dictionary[kIOPSCurrentKey as String] = currentmA
        }

        if let voltagemV {
            dictionary[kIOPSVoltageKey as String] = voltagemV
        }

        if let isCharging {
            dictionary[kIOPSIsChargingKey as String] = isCharging
        }

        if let isCharged {
            dictionary[kIOPSIsChargedKey as String] = isCharged
        }

        if let powerSourceState {
            dictionary[kIOPSPowerSourceStateKey as String] = powerSourceState
        }

        if internalBatteryType {
            dictionary[kIOPSTypeKey as String] = kIOPSInternalBatteryType as String
            dictionary[kIOPSTransportTypeKey as String] = kIOPSInternalType as String
        }

        return dictionary
    }
}

private struct FixtureAdapter: Codable {
    let watts: Int?

    func asAdapterDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]

        if let watts {
            dictionary[kIOPSPowerAdapterWattsKey as String] = watts
        }

        return dictionary
    }
}

private struct FixtureExpected: Codable {
    let batteryCurrentmA: Int?
    let batteryVoltagemV: Int?
    let isCharging: Bool?
    let isCharged: Bool?
    let powerSourceState: PowerSourceState
    let adapterWatts: Int?
    let batteryPowerW: Double?
    let chargeState: ChargeState
}
