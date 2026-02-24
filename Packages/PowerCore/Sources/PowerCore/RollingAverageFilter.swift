import Foundation

public final class RollingAverageFilter {
    private let windowSize: Int
    private var values: [Double]
    private var runningSum: Double

    public init(windowSize: Int) {
        precondition(windowSize > 0, "windowSize must be greater than zero")
        self.windowSize = windowSize
        self.values = []
        self.runningSum = 0
    }

    @discardableResult
    public func add(_ value: Double) -> Double {
        guard value.isFinite else {
            logInvariantFailure("Filter received non-finite value")
            return average ?? 0
        }

        values.append(value)
        runningSum += value

        if values.count > windowSize {
            runningSum -= values.removeFirst()
        }

        return runningSum / Double(values.count)
    }

    public func reset() {
        values.removeAll(keepingCapacity: true)
        runningSum = 0
    }

    public var average: Double? {
        guard !values.isEmpty else {
            return nil
        }

        return runningSum / Double(values.count)
    }

    private func logInvariantFailure(_ message: String) {
#if DEBUG
        fputs("RollingAverageFilter invariant: \(message)\n", stderr)
#endif
    }
}
