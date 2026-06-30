import WidgetKit
import SwiftUI
import SprintEngineCore

struct SprintEntry: TimelineEntry {
    let date: Date
    let state: SprintState?
}

struct SprintProvider: TimelineProvider {
    func placeholder(in context: Context) -> SprintEntry {
        SprintEntry(date: Date(), state: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SprintEntry) -> Void) {
        let state = ConfigStore.load().map { SprintEngine.currentSprint(today: Date(), config: $0) }
        completion(SprintEntry(date: Date(), state: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SprintEntry>) -> Void) {
        let now = Date()
        guard let config = ConfigStore.load() else {
            completion(Timeline(entries: [SprintEntry(date: now, state: nil)], policy: .after(now.addingTimeInterval(3600))))
            return
        }
        let cal = Calendar.current
        let state = SprintEngine.currentSprint(today: now, config: config)
        var entries: [SprintEntry] = [SprintEntry(date: now, state: state)]

        var cursor = cal.startOfDay(for: now)
        let sprintEnd = state.sprintEnd
        while cursor < sprintEnd {
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
            let wd = cal.component(.weekday, from: cursor)
            if config.workingDays.contains(Weekday(calendarWeekday: wd)) {
                entries.append(SprintEntry(date: cursor, state: SprintEngine.currentSprint(today: cursor, config: config)))
            }
        }
        entries.append(SprintEntry(date: sprintEnd, state: SprintEngine.currentSprint(today: sprintEnd, config: config)))

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

@main
struct SprintWidgetBundle: WidgetBundle {
    var body: some Widget {
        SprintWidget()
    }
}

struct SprintWidget: Widget {
    let kind: String = "SprintWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SprintProvider()) { entry in
            SprintWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    SprintTheme.containerGradient
                }
        }
        .configurationDisplayName("Sprint Counter")
        .description("Shows the current sprint and days passed.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
