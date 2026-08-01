import Foundation
import PowerCore

public protocol SamplingControlling: AnyObject {
    var onUpdate: ((SamplingUpdate) -> Void)? { get set }

    func start()
    func stop()
}

extension SamplingEngine: SamplingControlling {}

@MainActor
public final class AppLifecycle {
    public let engine: any SamplingControlling
    public let viewModel: StatusBarViewModel

    public private(set) var isRunning: Bool = false

    public init(engine: any SamplingControlling, viewModel: StatusBarViewModel) {
        self.engine = engine
        self.viewModel = viewModel
    }

    public func start() {
        guard !isRunning else {
            return
        }

        engine.onUpdate = { [weak viewModel] update in
            Task { @MainActor in
                viewModel?.apply(update: update)
            }
        }

        engine.start()
        isRunning = true
    }

    public func stop() {
        guard isRunning else {
            return
        }

        engine.stop()
        isRunning = false
    }
}
