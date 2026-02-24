import XCTest
@testable import PowerCore

final class HistoryRingBufferTests: XCTestCase {
    func testRingBufferEvictsOldestEntriesAtCapacity() {
        let buffer = HistoryRingBuffer(capacity: 1800)
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        for offset in 0..<1810 {
            let point = HistoryPoint(
                timestamp: base.addingTimeInterval(TimeInterval(offset)),
                batteryPowerW: Double(offset)
            )
            _ = buffer.append(point)
        }

        XCTAssertEqual(buffer.count, 1800)
        XCTAssertEqual(buffer.points.count, 1800)
        XCTAssertEqual(buffer.points.first?.batteryPowerW, 10)
        XCTAssertEqual(buffer.points.last?.batteryPowerW, 1809)
    }

    func testDuplicateTimestampIsIgnored() {
        let buffer = HistoryRingBuffer(capacity: 10)
        let timestamp = Date(timeIntervalSince1970: 42)

        XCTAssertTrue(buffer.append(HistoryPoint(timestamp: timestamp, batteryPowerW: 10)))
        XCTAssertFalse(buffer.append(HistoryPoint(timestamp: timestamp, batteryPowerW: 11)))
        XCTAssertEqual(buffer.points.count, 1)
    }
}
