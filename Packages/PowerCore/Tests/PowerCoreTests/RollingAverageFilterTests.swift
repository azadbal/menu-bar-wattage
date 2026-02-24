import XCTest
@testable import PowerCore

final class RollingAverageFilterTests: XCTestCase {
    func testRollingAverageSmoothsSpikyValuesDeterministically() {
        let filter = RollingAverageFilter(windowSize: 5)
        let sequence = [20.0, 60.0, 22.0, 58.0, 21.0]
        let expected = [20.0, 40.0, 34.0, 40.0, 36.2]

        for (index, value) in sequence.enumerated() {
            let averaged = filter.add(value)
            XCTAssertEqual(averaged, expected[index], accuracy: 0.0001)
        }

        XCTAssertEqual(filter.average ?? .nan, 36.2, accuracy: 0.0001)
    }

    func testWindowDropsOldValues() {
        let filter = RollingAverageFilter(windowSize: 3)
        _ = filter.add(10)
        _ = filter.add(20)
        _ = filter.add(30)
        let result = filter.add(40)

        XCTAssertEqual(result, 30, accuracy: 0.0001)
    }
}
