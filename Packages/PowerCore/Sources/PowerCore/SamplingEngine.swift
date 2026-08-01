import Foundation

public final class SamplingEngine: @unchecked Sendable {
    public typealias UpdateHandler = (SamplingUpdate) -> Void

    private let source: PowerTelemetrySource
    private let sampleInterval: TimeInterval
    private let now: () -> Date
    private let workQueue: DispatchQueue
    private let callbackQueue: DispatchQueue

    private var timer: DispatchSourceTimer?
    private var isRunning: Bool

    public var onUpdate: UpdateHandler?

    public init(
        source: PowerTelemetrySource,
        sampleInterval: TimeInterval = 1.0,
        now: @escaping () -> Date = Date.init,
        callbackQueue: DispatchQueue = .main,
        workQueue: DispatchQueue = DispatchQueue(label: "PowerCore.SamplingEngine", qos: .utility)
    ) {
        self.source = source
        self.sampleInterval = sampleInterval
        self.now = now
        self.callbackQueue = callbackQueue
        self.workQueue = workQueue
        self.isRunning = false
    }

    deinit {
        stop()
    }

    public func start() {
        workQueue.async { [weak self] in
            guard let self, !self.isRunning else {
                return
            }

            self.isRunning = true

            let timer = DispatchSource.makeTimerSource(queue: self.workQueue)
            timer.schedule(deadline: .now(), repeating: self.sampleInterval)
            timer.setEventHandler { [weak self] in
                _ = self?.performSample()
            }
            self.timer = timer
            timer.resume()

            DispatchQueue.main.async { [weak self] in
                self?.source.startNotifications { [weak self] in
                    self?.sampleOnce()
                }
            }
        }
    }

    public func stop() {
        workQueue.async { [weak self] in
            guard let self else {
                return
            }

            self.isRunning = false
            self.timer?.cancel()
            self.timer = nil

            DispatchQueue.main.async { [weak self] in
                self?.source.stopNotifications()
            }
        }
    }

    public func sampleOnce() {
        workQueue.async { [weak self] in
            _ = self?.performSample()
        }
    }

    @discardableResult
    public func sampleNowForTesting() -> SamplingUpdate {
        performSample()
    }

    private func performSample() -> SamplingUpdate {
        let timestamp = now()

        do {
            let rawSnapshot = try source.readSnapshot(now: timestamp)
            let derivedMetrics = PowerDeriver.derive(from: rawSnapshot)

            let update = SamplingUpdate(
                rawSnapshot: rawSnapshot,
                derivedMetrics: derivedMetrics,
                lastSampleTimestamp: rawSnapshot.timestamp,
                errorMessage: nil
            )

            publish(update)
            return update
        } catch {
            let update = SamplingUpdate(
                rawSnapshot: nil,
                derivedMetrics: nil,
                lastSampleTimestamp: timestamp,
                errorMessage: String(describing: error)
            )

            publish(update)
            return update
        }
    }

    private func publish(_ update: SamplingUpdate) {
        callbackQueue.async { [weak self] in
            self?.onUpdate?(update)
        }
    }
}
