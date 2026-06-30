import WidgetKit
import SwiftUI

@main
struct SprintWidgetBundle: WidgetBundle {
    var body: some Widget {
        SprintWidget()
    }
}

struct SprintWidget: Widget {
    let kind: String = "SprintWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { _ in
            Text("Sprint")
        }
        .configurationDisplayName("Sprint Counter")
        .description("Shows the current sprint and days passed.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PlaceholderProvider: TimelineProvider {
    typealias Entry = SimpleEntry
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) { completion(SimpleEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: Date())], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}
