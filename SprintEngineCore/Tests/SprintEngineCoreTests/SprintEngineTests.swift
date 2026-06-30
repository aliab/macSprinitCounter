import XCTest
@testable import SprintEngineCore

final class SprintEngineTests: XCTestCase {
    var cal: Calendar!

    override func setUp() {
        super.setUp()
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        cal = c
    }

    func makeDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = 0
        return cal.date(from: c)!
    }

    func makeConfig(
        start: Date,
        workingDays: Set<Weekday>,
        lengthWeeks: Int = 2,
        perQuarter: Int = 6
    ) -> SprintConfig {
        SprintConfig(
            firstSprintStart: start,
            workingDays: workingDays,
            sprintLengthWeeks: lengthWeeks,
            sprintsPerQuarter: perQuarter
        )
    }

    // 2026-01-03 is a Saturday (2026-01-01 is Thursday).
    // Working days Sat..Wed. 2-week sprints. Sprint 1 = Jan 3..Jan 16 (end exclusive Jan 17).
    // Working days in sprint: Jan 3,4,5,6,7 + Jan 10,11,12,13,14 = 10.
    func testMidSprintWorkingDay() {
        let start = makeDate(2026, 1, 3)
        let config = makeConfig(start: start, workingDays: [.saturday, .sunday, .monday, .tuesday, .wednesday])
        let today = makeDate(2026, 1, 7) // Wednesday, 5th working day
        let state = SprintEngine.currentSprint(today: today, config: config, calendar: cal)

        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.sprintIndex, 0)
        XCTAssertEqual(state.sprintInQuarter, 1)
        XCTAssertEqual(state.quarterNumber, 1)
        XCTAssertEqual(state.workingDaysElapsed, 5)
        XCTAssertEqual(state.workingDaysInSprint, 10)
        XCTAssertEqual(state.workingDaysRemaining, 5)
        XCTAssertEqual(state.progress, 0.5, accuracy: 0.001)
        XCTAssertEqual(state.sprintStart, makeDate(2026, 1, 3))
        XCTAssertEqual(state.sprintEnd, makeDate(2026, 1, 17))
    }
}