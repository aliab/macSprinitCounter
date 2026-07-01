import WidgetKit
import SwiftUI
import SprintEngineCore
import os

private let log = Logger(subsystem: "com.aliabdolahi.sprintcounter", category: "SprintWidget")

struct SprintEntry: TimelineEntry {
    let date: Date
    let state: SprintState?
}

struct SprintProvider: TimelineProvider {
    func placeholder(in context: Context) -> SprintEntry {
        ConfigStore.recordDebug("SprintProvider.placeholder family=\(context.family)")
        log.info("[SprintWidget] placeholder() called")
        let config = ConfigStore.load()
        ConfigStore.recordDebug("SprintProvider.placeholder ConfigStore.load => \(config == nil ? "nil" : "config")")
        let state = config.map { SprintEngine.currentSprint(today: Date(), config: $0) }
        if let state {
            ConfigStore.recordDebug("SprintProvider.placeholder state=\(describe(state))")
        }
        return SprintEntry(date: Date(), state: state)
    }

    func getSnapshot(in context: Context, completion: @escaping (SprintEntry) -> Void) {
        ConfigStore.recordDebug("SprintProvider.getSnapshot start family=\(context.family) isPreview=\(context.isPreview)")
        log.info("[SprintWidget] getSnapshot() called")
        let config = ConfigStore.load()
        ConfigStore.recordDebug("SprintProvider.getSnapshot ConfigStore.load => \(config == nil ? "nil" : "config")")
        let state = config.map { SprintEngine.currentSprint(today: Date(), config: $0) }
        if let state {
            ConfigStore.recordDebug("SprintProvider.getSnapshot state=\(describe(state))")
        }
        completion(SprintEntry(date: Date(), state: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SprintEntry>) -> Void) {
        let now = Date()
        ConfigStore.recordDebug("SprintProvider.getTimeline start family=\(context.family) isPreview=\(context.isPreview)")
        let loaded = ConfigStore.load()
        log.info("[SprintWidget] getTimeline() called; ConfigStore.load() => \(loaded == nil ? "nil" : "config", privacy: .public)")
        ConfigStore.recordDebug("SprintProvider.getTimeline ConfigStore.load => \(loaded == nil ? "nil" : "config")")
        guard let config = loaded else {
            log.info("[SprintWidget] no config — returning placeholder timeline")
            ConfigStore.recordDebug("SprintProvider.getTimeline returning configure timeline because config=nil")
            completion(Timeline(entries: [SprintEntry(date: now, state: nil)], policy: .after(now.addingTimeInterval(3600))))
            return
        }
        ConfigStore.recordDebug("SprintProvider.getTimeline loaded \(ConfigStore.describe(config))")
        let cal = Calendar.current
        let state = SprintEngine.currentSprint(today: now, config: config)
        ConfigStore.recordDebug("SprintProvider.getTimeline current state=\(describe(state))")
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

        ConfigStore.recordDebug("SprintProvider.getTimeline returning entries=\(entries.count) policy=atEnd")
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func describe(_ state: SprintState) -> String {
        "status=\(state.status) sprint=\(state.sprintInQuarter)/\(state.sprintsPerQuarter) elapsed=\(state.workingDaysElapsed)/\(state.workingDaysInSprint) start=\(state.sprintStart) end=\(state.sprintEnd)"
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
                .widgetURL(URL(string: "sprintcounter://open"))
                .containerBackground(for: .widget) {
                    SprintTheme.containerGradient
                }
        }
        .configurationDisplayName("Sprint Counter")
        .description("Shows the current sprint and days passed.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
