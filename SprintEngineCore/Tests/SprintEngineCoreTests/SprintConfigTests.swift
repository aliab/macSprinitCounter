import XCTest
@testable import SprintEngineCore

final class SprintConfigTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let config = SprintConfig(
            firstSprintStart: Date(timeIntervalSince1970: 1_700_000_000),
            workingDays: [.saturday, .sunday, .monday, .tuesday, .wednesday],
            sprintLengthWeeks: 2,
            sprintsPerQuarter: 6
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SprintConfig.self, from: data)
        XCTAssertEqual(decoded, config)
    }

    func testDefaultConfigHasWeekdays() {
        let config = SprintConfig.default
        XCTAssertEqual(config.sprintLengthWeeks, 2)
        XCTAssertEqual(config.sprintsPerQuarter, 6)
        XCTAssertEqual(config.workingDays, [.monday, .tuesday, .wednesday, .thursday, .friday])
    }
}