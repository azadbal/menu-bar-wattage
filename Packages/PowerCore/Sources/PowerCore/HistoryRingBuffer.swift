import Foundation

public final class HistoryRingBuffer {
    public let capacity: Int

    private var storage: [HistoryPoint?]
    private(set) public var count: Int
    private var nextWriteIndex: Int
    private(set) public var lastTimestamp: Date?

    public init(capacity: Int) {
        precondition(capacity > 0, "capacity must be greater than zero")
        self.capacity = capacity
        self.storage = Array(repeating: nil, count: capacity)
        self.count = 0
        self.nextWriteIndex = 0
        self.lastTimestamp = nil
    }

    @discardableResult
    public func append(_ point: HistoryPoint) -> Bool {
        if let lastTimestamp {
            if point.timestamp < lastTimestamp {
                logInvariantFailure("History timestamps must be monotonic")
                return false
            }

            if point.timestamp == lastTimestamp {
                return false
            }
        }

        storage[nextWriteIndex] = point
        nextWriteIndex = (nextWriteIndex + 1) % capacity

        if count < capacity {
            count += 1
        }

        lastTimestamp = point.timestamp

        assert(count <= capacity, "History capacity exceeded")
        return true
    }

    public func removeAll() {
        storage = Array(repeating: nil, count: capacity)
        count = 0
        nextWriteIndex = 0
        lastTimestamp = nil
    }

    public var points: [HistoryPoint] {
        guard count > 0 else {
            return []
        }

        let startIndex = count == capacity ? nextWriteIndex : 0
        var result: [HistoryPoint] = []
        result.reserveCapacity(count)

        for offset in 0..<count {
            let index = (startIndex + offset) % capacity
            if let point = storage[index] {
                result.append(point)
            }
        }

        return result
    }

    private func logInvariantFailure(_ message: String) {
#if DEBUG
        fputs("HistoryRingBuffer invariant: \(message)\n", stderr)
#endif
    }
}
