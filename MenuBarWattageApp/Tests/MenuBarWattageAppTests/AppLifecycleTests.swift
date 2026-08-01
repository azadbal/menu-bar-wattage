import XCTest
import PowerCore
import MenuBarWattageUI

@MainActor
final class AppLifecycleTests: XCTestCase {
    func testLifecycleStartStopAndUpdateFlow() {
        let fakeController = FakeSamplingController()
        let viewModel = StatusBarViewModel()

        let lifecycle = AppLifecycle(engine: fakeController, viewModel: viewModel)

        lifecycle.start()

        XCTAssertTrue(lifecycle.isRunning)
        XCTAssertEqual(fakeController.startCallCount, 1)

        let update = SamplingUpdate(
            rawSnapshot: nil,
            derivedMetrics: DerivedPowerMetrics(
                batteryPowerW: 24.0,
                adapterWatts: 67,
                chargeState: .charging,
                powerSourceState: .ac
            ),
            lastSampleTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            errorMessage: nil
        )

        fakeController.emit(update)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))

        XCTAssertEqual(viewModel.statusText, "67W")
        XCTAssertEqual(viewModel.statusDetailText, "67W from charging adapter.")

        lifecycle.stop()

        XCTAssertFalse(lifecycle.isRunning)
        XCTAssertEqual(fakeController.stopCallCount, 1)
    }
}

private final class FakeSamplingController: SamplingControlling {
    var onUpdate: ((SamplingUpdate) -> Void)?

    private(set) var startCallCount: Int = 0
    private(set) var stopCallCount: Int = 0

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }

    func emit(_ update: SamplingUpdate) {
        onUpdate?(update)
    }
}
