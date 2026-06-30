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

    // today = first day of sprint 2 (Jan 17, Saturday). workingDaysElapsed should be 1.
    func testSprintBoundaryFirstWorkingDay() {
        let start = makeDate(2026, 1, 3)
        let config = makeConfig(start: start, workingDays: [.saturday, .sunday, .monday, .tuesday, .wednesday])
        let today = makeDate(2026, 1, 17) // Saturday — first day of sprint 2
        let state = SprintEngine.currentSprint(today: today, config: config, calendar: cal)

        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.sprintIndex, 1)
        XCTAssertEqual(state.sprintInQuarter, 2)
        XCTAssertEqual(state.quarterNumber, 1)
        XCTAssertEqual(state.workingDaysElapsed, 1)
        XCTAssertEqual(state.workingDaysInSprint, 10)
        XCTAssertEqual(state.sprintStart, makeDate(2026, 1, 17))
        XCTAssertEqual(state.sprintEnd, makeDate(2026, 1, 31))
    }

    // today = Thursday Jan 8 — weekend in Sat..Wed config. Elapsed should match Jan 7 (=5).
    func testNonWorkingDayDoesNotIncrement() {
        let start = makeDate(2026, 1, 3)
        let config = makeConfig(start: start, workingDays: [.saturday, .sunday, .monday, .tuesday, .wednesday])
        let today = makeDate(2026, 1, 8) // Thursday — not a working day
        let state = SprintEngine.currentSprint(today: today, config: config, calendar: cal)

        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.sprintIndex, 0)
        XCTAssertEqual(state.workingDaysElapsed, 5) // unchanged from Jan 7
    }

    // 6 sprints per quarter × 14 days = 84 days. Jan 3 + 84 days = Mar 28 (Saturday), sprint 7, Q2.
    func testQuarterRollover() {
        let start = makeDate(2026, 1, 3)
        let config = makeConfig(start: start, workingDays: [.saturday, .sunday, .monday, .tuesday, .wednesday])
        let today = makeDate(2026, 3, 28) // Saturday — first sprint of Q2
        let state = SprintEngine.currentSprint(today: today, config: config, calendar: cal)

        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.sprintIndex, 6)
        XCTAssertEqual(state.sprintInQuarter, 1)
        XCTAssertEqual(state.quarterNumber, 2)
        XCTAssertEqual(state.nextSprintInQuarter, 2)
        XCTAssertEqual(state.nextSprintQuarterNumber, 2)
    }

    func testPreStart() {
        let start = makeDate(2026, 1, 3)
        let config = makeConfig(start: start, workingDays: [.saturday, .sunday, .monday, .tuesday, .wednesday])
        let today = makeDate(2025, 12, 30) // before first sprint start
        let state = SprintEngine.currentSprint(today: today, config: config, calendar: cal)

        XCTAssertEqual(state.status, .notStarted)
        XCTAssertEqual(state.sprintStart, start)
        XCTAssertEqual(state.workingDaysElapsed, 0)
        XCTAssertEqual(state.progress, 0)
    }

    func testEmptyWorkingDaysNoCrash() {
        let start = makeDate(2026, 1, 3)
        let config = makeConfig(start: start, workingDays: [])
        let today = makeDate(2026, 1, 7)
        let state = SprintEngine.currentSprint(today: today, config: config, calendar: cal)

        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.workingDaysInSprint, 0)
        XCTAssertEqual(state.workingDaysElapsed, 0)
        XCTAssertEqual(state.progress, 0) // no divide-by-zero
        XCTAssertEqual(state.workingDaysRemaining, 0)
    }
}