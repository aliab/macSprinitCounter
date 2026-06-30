import SwiftUI
import WidgetKit
import SprintEngineCore

struct ConfigWindow: View {
    @State private var config: SprintConfig

    init() {
        _config = State(initialValue: ConfigStore.load() ?? .default)
    }

    var body: some View {
        HStack(spacing: 0) {
            configForm
                .frame(width: 360)
                .padding()
            Divider()
            livePreview
                .padding()
        }
    }

    private var configForm: some View {
        Form {
            Section("Sprint") {
                DatePicker(
                    "First sprint start",
                    selection: $config.firstSprintStart,
                    displayedComponents: [.date]
                )
            }
            Section("Working days") {
                HStack {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Toggle(day.shortLabel, isOn: binding(for: day))
                            .toggleStyle(.checkbox)
                    }
                }
            }
            Section("Sprint length") {
                Picker("Weeks per sprint", selection: $config.sprintLengthWeeks) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                }
                .pickerStyle(.segmented)
            }
            Section("Quarter") {
                Stepper(
                    "Sprints per quarter: \(config.sprintsPerQuarter)",
                    value: $config.sprintsPerQuarter,
                    in: 1...12
                )
            }
        }
        .formStyle(.grouped)
        .onChange(of: config) { _, newConfig in
            ConfigStore.save(newConfig)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func binding(for day: Weekday) -> Binding<Bool> {
        Binding(
            get: { config.workingDays.contains(day) },
            set: { isOn in
                if isOn { config.workingDays.insert(day) } else { config.workingDays.remove(day) }
            }
        )
    }

    private var livePreview: some View {
        let state = SprintEngine.currentSprint(today: Date(), config: config)
        return VStack(spacing: 16) {
            Text("Live preview")
                .font(.headline)
            SprintPreviewCard(state: state)
                .shadow(radius: 12, y: 6)
            if state.status == .notStarted {
                Text("Sprint 1 hasn't started yet.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
