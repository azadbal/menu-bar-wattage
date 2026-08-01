import XCTest
@testable import PowerCore

@MainActor
final class StatusBarViewModelTests: XCTestCase {
    func testStatusTextStates() {
        let viewModel = StatusBarViewModel(locale: Locale(identifier: "en_US_POSIX"), timeZone: TimeZone(secondsFromGMT: 0)!)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertEqual(viewModel.statusText, "-")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: 42.4, adapterWatts: 70, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "70W")
        XCTAssertNil(viewModel.statusExplanationText)

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: -18.3, adapterWatts: nil, chargeState: .discharging, powerSourceState: .battery),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "-")
        XCTAssertEqual(viewModel.statusExplanationText, "No external power is connected, so there is no adapter wattage to show.")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: 70, chargeState: .charged, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "70W")
        XCTAssertNil(viewModel.statusExplanationText)

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: 96, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "96W")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: nil, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "-")
        XCTAssertEqual(viewModel.statusExplanationText, "Adapter wattage is unavailable.")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: nil,
            lastSampleTimestamp: now,
            errorMessage: "oops"
        ))
        XCTAssertEqual(viewModel.statusText, "-")
        XCTAssertEqual(viewModel.statusExplanationText, "No external power is connected, so there is no adapter wattage to show.")
    }

    func testDropdownTextsAndTimestampFormatting() {
        let viewModel = StatusBarViewModel(locale: Locale(identifier: "en_US_POSIX"), timeZone: TimeZone(secondsFromGMT: 0)!)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: 24.0, adapterWatts: 67, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))

        XCTAssertEqual(viewModel.adapterWattsText, "Adapter Power: 67 W")
        XCTAssertEqual(viewModel.lastUpdatedText, "Updated: 22:13:20")
        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: nil, chargeState: .unknown),
            lastSampleTimestamp: nil,
            errorMessage: nil
        ))

        XCTAssertEqual(viewModel.adapterWattsText, "Adapter Power: Unavailable")
        XCTAssertEqual(viewModel.lastUpdatedText, "Updated: --")
    }
}
