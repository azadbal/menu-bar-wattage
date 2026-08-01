import XCTest
@testable import PowerCore

@MainActor
final class StatusBarViewModelTests: XCTestCase {
    func testStatusTextStates() {
        let viewModel = StatusBarViewModel()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertEqual(viewModel.statusText, "-")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: 42.4, adapterWatts: 70, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "70W")
        XCTAssertEqual(viewModel.statusDetailText, "70W from charging adapter.")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: -18.3, adapterWatts: nil, chargeState: .discharging, powerSourceState: .battery),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "\\")
        XCTAssertEqual(viewModel.statusDetailText, "Using battery power. No charging detected.")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: 70, chargeState: .charged, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "70W")
        XCTAssertEqual(viewModel.statusDetailText, "70W from charging adapter.")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: 96, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "96W")
        XCTAssertEqual(viewModel.statusDetailText, "96W from charging adapter.")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: nil, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))
        XCTAssertEqual(viewModel.statusText, "-")
        XCTAssertEqual(viewModel.statusDetailText, "Charging adapter wattage unavailable.")

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: nil,
            lastSampleTimestamp: now,
            errorMessage: "oops"
        ))
        XCTAssertEqual(viewModel.statusText, "-")
        XCTAssertEqual(viewModel.statusDetailText, "Power status unavailable.")
    }

    func testDropdownTextUsesSingleCurrentStatusLine() {
        let viewModel = StatusBarViewModel()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: 24.0, adapterWatts: 67, chargeState: .charging, powerSourceState: .ac),
            lastSampleTimestamp: now,
            errorMessage: nil
        ))

        XCTAssertEqual(viewModel.statusDetailText, "67W from charging adapter.")
        viewModel.apply(update: SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(batteryPowerW: nil, adapterWatts: nil, chargeState: .unknown),
            lastSampleTimestamp: nil,
            errorMessage: nil
        ))

        XCTAssertEqual(viewModel.statusDetailText, "Power status unavailable.")
    }
}
