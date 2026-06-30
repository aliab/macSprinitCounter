import Foundation

public enum SprintStatus: Codable, Equatable, Sendable {
    case noConfig
    case notStarted
    case active
}

public struct SprintState: Equatable, Sendable {
    public var status: SprintStatus
    public var sprintIndex: Int
    public var sprintInQuarter: Int
    public var quarterIndex: Int
    public var quarterNumber: Int
    public var sprintStart: Date
    public var sprintEnd: Date
    public var workingDaysElapsed: Int
    public var workingDaysInSprint: Int
    public var workingDaysRemaining: Int
    public var progress: Double
    public var nextSprintStart: Date
    public var nextSprintInQuarter: Int
    public var nextSprintQuarterNumber: Int
    public var sprintsPerQuarter: Int

    public init(
        status: SprintStatus,
        sprintIndex: Int,
        sprintInQuarter: Int,
        quarterIndex: Int,
        quarterNumber: Int,
        sprintStart: Date,
        sprintEnd: Date,
        workingDaysElapsed: Int,
        workingDaysInSprint: Int,
        workingDaysRemaining: Int,
        progress: Double,
        nextSprintStart: Date,
        nextSprintInQuarter: Int,
        nextSprintQuarterNumber: Int,
        sprintsPerQuarter: Int
    ) {
        self.status = status
        self.sprintIndex = sprintIndex
        self.sprintInQuarter = sprintInQuarter
        self.quarterIndex = quarterIndex
        self.quarterNumber = quarterNumber
        self.sprintStart = sprintStart
        self.sprintEnd = sprintEnd
        self.workingDaysElapsed = workingDaysElapsed
        self.workingDaysInSprint = workingDaysInSprint
        self.workingDaysRemaining = workingDaysRemaining
        self.progress = progress
        self.nextSprintStart = nextSprintStart
        self.nextSprintInQuarter = nextSprintInQuarter
        self.nextSprintQuarterNumber = nextSprintQuarterNumber
        self.sprintsPerQuarter = sprintsPerQuarter
    }
}