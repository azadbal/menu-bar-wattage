import XCTest
@testable import PowerCore

final class SamplingEngineTests: XCTestCase {
    func testSampleWithErrorRecoversOnNextRead() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = RawPowerSnapshot(
            batteryCurrentmA: 2000,
            batteryVoltagemV: 12000,
            isCharging: true,
            isCharged: false,
            powerSourceState: .ac,
            adapterWatts: 67,
            timestamp: now.addingTimeInterval(1)
        )

        let source = FakePowerTelemetrySource(
            reads: [
                .failure(PowerTelemetryError.missingPowerSource),
                .success(snapshot)
            ]
        )

        let clock = TestClock([now, now.addingTimeInterval(1)])
        let engine = SamplingEngine(
            source: source,
            sampleInterval: 100,
            now: { clock.next() },
            callbackQueue: .main,
            workQueue: DispatchQueue(label: "SamplingEngineTests")
        )

        let first = engine.sampleNowForTesting()
        XCTAssertNotNil(first.errorMessage)
        XCTAssertEqual(first.history.count, 0)

        let second = engine.sampleNowForTesting()
        XCTAssertNil(second.errorMessage)
        XCTAssertEqual(second.derivedMetrics?.chargeState, .charging)
        XCTAssertEqual(second.history.count, 1)
    }

    func testDuplicateTimestampsAreNotAddedToHistory() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = RawPowerSnapshot(
            batteryCurrentmA: -1800,
            batteryVoltagemV: 12000,
            isCharging: false,
            isCharged: false,
            powerSourceState: .battery,
            adapterWatts: nil,
            timestamp: timestamp
        )

        let source = FakePowerTelemetrySource(reads: [.success(snapshot), .success(snapshot)])
        let clock = TestClock([timestamp, timestamp])

        let engine = SamplingEngine(
            source: source,
            sampleInterval: 100,
            now: { clock.next() },
            callbackQueue: .main,
            workQueue: DispatchQueue(label: "SamplingEngineTests.Dedup")
        )

        _ = engine.sampleNowForTesting()
        let second = engine.sampleNowForTesting()

        XCTAssertEqual(second.history.count, 1)
    }

    func testNotificationTriggersImmediateSample() {
        let expectation = expectation(description: "notification update")
        expectation.expectedFulfillmentCount = 2

        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let source = FakePowerTelemetrySource(
            reads: [
                .success(RawPowerSnapshot(
                    batteryCurrentmA: 1000,
                    batteryVoltagemV: 12000,
                    isCharging: true,
                    isCharged: false,
                    powerSourceState: .ac,
                    adapterWatts: 70,
                    timestamp: base
                )),
                .success(RawPowerSnapshot(
                    batteryCurrentmA: 1100,
                    batteryVoltagemV: 12000,
                    isCharging: true,
                    isCharged: false,
                    powerSourceState: .ac,
                    adapterWatts: 70,
                    timestamp: base.addingTimeInterval(1)
                ))
            ]
        )

        let clock = TestClock([base, base.addingTimeInterval(1), base.addingTimeInterval(2)])
        let engine = SamplingEngine(
            source: source,
            sampleInterval: 100,
            now: { clock.next() },
            callbackQueue: .main,
            workQueue: DispatchQueue(label: "SamplingEngineTests.Notify")
        )

        engine.onUpdate = { _ in
            expectation.fulfill()
        }

        engine.start()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        source.triggerNotification()

        wait(for: [expectation], timeout: 2)
        engine.stop()

        XCTAssertGreaterThanOrEqual(source.readCount, 2)
        XCTAssertEqual(source.startNotificationCount, 1)
    }
}

private final class FakePowerTelemetrySource: @unchecked Sendable, PowerTelemetrySource {
    private var reads: [Result<RawPowerSnapshot, Error>]
    private let lock = NSLock()
    private var _readCount: Int = 0
    private var onChange: (() -> Void)?

    private var _startNotificationCount: Int = 0

    init(reads: [Result<RawPowerSnapshot, Error>]) {
        self.reads = reads
    }

    func readSnapshot(now: Date) throws -> RawPowerSnapshot {
        let result: Result<RawPowerSnapshot, Error>
        lock.lock()
        defer { lock.unlock() }

        _readCount += 1
        guard !reads.isEmpty else {
            throw PowerTelemetryError.missingPowerSource
        }

        result = reads.removeFirst()
        return try result.get()
    }

    func startNotifications(_ onChange: @escaping () -> Void) {
        lock.lock()
        self.onChange = onChange
        _startNotificationCount += 1
        lock.unlock()
    }

    func stopNotifications() {
        lock.lock()
        onChange = nil
        lock.unlock()
    }

    func triggerNotification() {
        lock.lock()
        let callback = onChange
        lock.unlock()

        callback?()
    }

    var readCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _readCount
    }

    var startNotificationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _startNotificationCount
    }
}

private final class TestClock: @unchecked Sendable {
    private var values: [Date]
    private var fallback: Date
    private let lock = NSLock()

    init(_ values: [Date]) {
        self.values = values
        self.fallback = values.last ?? Date(timeIntervalSince1970: 0)
    }

    func next() -> Date {
        lock.lock()
        defer { lock.unlock() }

        if values.isEmpty {
            return fallback
        }

        return values.removeFirst()
    }
}
