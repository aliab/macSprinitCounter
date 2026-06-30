import Foundation

public struct SprintConfig: Codable, Equatable, Sendable {
    public var firstSprintStart: Date
    public var workingDays: Set<Weekday>
    public var sprintLengthWeeks: Int
    public var sprintsPerQuarter: Int

    public init(
        firstSprintStart: Date,
        workingDays: Set<Weekday>,
        sprintLengthWeeks: Int,
        sprintsPerQuarter: Int
    ) {
        self.firstSprintStart = firstSprintStart
        self.workingDays = workingDays
        self.sprintLengthWeeks = sprintLengthWeeks
        self.sprintsPerQuarter = sprintsPerQuarter
    }

    public static let `default` = SprintConfig(
        firstSprintStart: Calendar.current.startOfDay(for: Date()),
        workingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
        sprintLengthWeeks: 2,
        sprintsPerQuarter: 6
    )
}