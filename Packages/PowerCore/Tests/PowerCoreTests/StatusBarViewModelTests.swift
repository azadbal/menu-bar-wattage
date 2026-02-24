import XCTest
@testable import PowerCore

@MainActor
final class StatusBarViewModelTests: XCTestCase {
    func testStatusTextStates() {
        let viewModel = StatusBarViewModel(locale: Locale(identifier: "en_US_POSIX"), timeZone: TimeZone(secondsFromGMT: 0)!)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: 42.4, adapterWatts: 70, chargeState: .charging),
            smoothedBatteryPowerW: 42.4,
            history: [],
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "42W")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: -18.3, adapterWatts: nil, chargeState: .discharging),
            smoothedBatteryPowerW: -18.3,
            history: [],
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "On Battery")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: 70, chargeState: .charged),
            smoothedBatteryPowerW: nil,
            history: [],
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "Charged")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: 96, chargeState: .charging),
            smoothedBatteryPowerW: nil,
            history: [],
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "96W")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: nil,
            smoothedBatteryPowerW: nil,
            history: [],
            lastSampleTimestamp: now,
            errorMessage: "oops"
        ))
        XCTAssertEqual(viewModel.statusText, "No Data")
    }

    func testDropdownTextsAndTimestampFormatting() {
        let viewModel = StatusBarViewModel(locale: Locale(identifier: "en_US_POSIX"), timeZone: TimeZone(secondsFromGMT: 0)!)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: 24.0, adapterWatts: 67, chargeState: .charging),
            smoothedBatteryPowerW: 24.0,
            history: [HistoryPoint(timestamp: now, batteryPowerW: 24.0)],
            lastSampleTimestamp: now,
            errorMessage: nil
        ))

        XCTAssertEqual(viewModel.batteryWattsText, "Battery Power: 24.0 W")
        XCTAssertEqual(viewModel.adapterWattsText, "Adapter Power: 67 W")
        XCTAssertEqual(viewModel.lastUpdatedText, "Updated: 22:13:20")
        XCTAssertEqual(viewModel.history.count, 1)

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: nil, chargeState: .unknown),
            smoothedBatteryPowerW: nil,
            history: [],
            lastSampleTimestamp: nil,
            errorMessage: nil
        ))

        XCTAssertEqual(viewModel.batteryWattsText, "Battery Power: Unavailable")
        XCTAssertEqual(viewModel.adapterWattsText, "Adapter Power: Unavailable")
        XCTAssertEqual(viewModel.lastUpdatedText, "Updated: --")
    }
}
