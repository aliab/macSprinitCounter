import Foundation

public enum SprintEngine {
    public static func currentSprint(
        today: Date,
        config: SprintConfig,
        calendar: Calendar = .current
    ) -> SprintState {
        let cal = calendar
        let firstStart = cal.startOfDay(for: config.firstSprintStart)
        let todayStart = cal.startOfDay(for: today)

        let sprintLengthDays = config.sprintLengthWeeks * 7
        let workingDaysInSprint = config.workingDays.count * config.sprintLengthWeeks

        // Pre-start
        if todayStart < firstStart {
            let sprintEnd = cal.date(byAdding: .day, value: sprintLengthDays, to: firstStart)!
            return SprintState(
                status: .notStarted,
                sprintIndex: 0,
                sprintInQuarter: 1,
                quarterIndex: 0,
                quarterNumber: 1,
                sprintStart: firstStart,
                sprintEnd: sprintEnd,
                workingDaysElapsed: 0,
                workingDaysInSprint: workingDaysInSprint,
                workingDaysRemaining: workingDaysInSprint,
                progress: 0,
                nextSprintStart: sprintEnd,
                nextSprintInQuarter: min(2, max(1, config.sprintsPerQuarter)),
                nextSprintQuarterNumber: 1,
                sprintsPerQuarter: config.sprintsPerQuarter
            )
        }

        // Active path
        let dayComponents = cal.dateComponents([.day], from: firstStart, to: todayStart)
        let daysSinceStart = max(0, dayComponents.day ?? 0)
        let sprintIndex = sprintLengthDays > 0 ? daysSinceStart / sprintLengthDays : 0

        let sprintStart = cal.date(byAdding: .day, value: sprintIndex * sprintLengthDays, to: firstStart)!
        let sprintEnd = cal.date(byAdding: .day, value: sprintLengthDays, to: sprintStart)!

        var workingDaysElapsed = 0
        var cursor = sprintStart
        while cursor <= todayStart {
            let wd = cal.component(.weekday, from: cursor)
            if config.workingDays.contains(Weekday(calendarWeekday: wd)) {
                workingDaysElapsed += 1
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }

        let progress: Double = workingDaysInSprint > 0
            ? Double(workingDaysElapsed) / Double(workingDaysInSprint)
            : 0

        let quarterIndex = config.sprintsPerQuarter > 0 ? sprintIndex / config.sprintsPerQuarter : 0
        let sprintInQuarter = (config.sprintsPerQuarter > 0 ? sprintIndex % config.sprintsPerQuarter : 0) + 1
        let quarterNumber = quarterIndex + 1

        let nextSprintInQuarter: Int
        let nextSprintQuarterNumber: Int
        if sprintInQuarter >= config.sprintsPerQuarter {
            nextSprintInQuarter = 1
            nextSprintQuarterNumber = quarterNumber + 1
        } else {
            nextSprintInQuarter = sprintInQuarter + 1
            nextSprintQuarterNumber = quarterNumber
        }

        return SprintState(
            status: .active,
            sprintIndex: sprintIndex,
            sprintInQuarter: sprintInQuarter,
            quarterIndex: quarterIndex,
            quarterNumber: quarterNumber,
            sprintStart: sprintStart,
            sprintEnd: sprintEnd,
            workingDaysElapsed: workingDaysElapsed,
            workingDaysInSprint: workingDaysInSprint,
            workingDaysRemaining: max(0, workingDaysInSprint - workingDaysElapsed),
            progress: progress,
            nextSprintStart: sprintEnd,
            nextSprintInQuarter: nextSprintInQuarter,
            nextSprintQuarterNumber: nextSprintQuarterNumber,
            sprintsPerQuarter: config.sprintsPerQuarter
        )
    }
}