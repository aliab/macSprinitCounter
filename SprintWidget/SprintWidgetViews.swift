import SwiftUI
import WidgetKit
import SprintEngineCore

struct SprintWidgetView: View {
    let entry: SprintEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: MediumSprintView(state: entry.state)
        case .systemLarge: LargeSprintView(state: entry.state)
        default: SmallSprintView(state: entry.state)
        }
    }
}

// MARK: - Placeholder

struct SprintPlaceholder: View {
    let text: String
    var body: some View {
        VStack(spacing: 8) {
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SprintTheme.label)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Small

struct SmallSprintView: View {
    let state: SprintState?

    var body: some View {
        if let state {
            if state.status == .notStarted {
                SprintPlaceholder(text: "Sprint 1 starts \(sprintDateString(state.sprintStart))")
            } else {
                activeView(state)
            }
        } else {
            SprintPlaceholder(text: "Open SprintCounter to configure")
        }
    }

    private func activeView(_ state: SprintState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SPRINT \(state.sprintInQuarter)/\(state.sprintsPerQuarter)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SprintTheme.label)
                .tracking(1)
            Spacer()
            Text("Day \(state.workingDaysElapsed)")
                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(SprintTheme.primary)
                .contentTransition(.numericText())
            Text("of \(state.workingDaysInSprint)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SprintTheme.label)
            SprintProgressBar(progress: state.progress)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Medium

struct MediumSprintView: View {
    let state: SprintState?

    var body: some View {
        if let state {
            if state.status == .notStarted {
                SprintPlaceholder(text: "Sprint 1 starts \(sprintDateString(state.sprintStart))")
            } else {
                activeView(state)
            }
        } else {
            SprintPlaceholder(text: "Open SprintCounter to configure")
        }
    }

    private func activeView(_ state: SprintState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SPRINT \(state.sprintInQuarter) OF \(state.sprintsPerQuarter)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
                    .tracking(1)
                Spacer()
                Text("Q\(state.quarterNumber)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SprintTheme.accentGradient)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Day \(state.workingDaysElapsed)")
                    .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(SprintTheme.primary)
                    .contentTransition(.numericText())
                Text("/ \(state.workingDaysInSprint)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
            }
            SprintProgressBar(progress: state.progress)
            HStack(spacing: 6) {
                Text("\(Int((state.progress * 100).rounded()))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SprintTheme.primary)
                Text("·").font(.system(size: 11)).foregroundStyle(SprintTheme.label)
                Text("\(state.workingDaysRemaining) working days left")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Large

struct LargeSprintView: View {
    let state: SprintState?

    var body: some View {
        if let state {
            if state.status == .notStarted {
                SprintPlaceholder(text: "Sprint 1 starts \(sprintDateString(state.sprintStart))")
            } else {
                activeView(state)
            }
        } else {
            SprintPlaceholder(text: "Open SprintCounter to configure")
        }
    }

    private func activeView(_ state: SprintState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SPRINT \(state.sprintInQuarter) OF \(state.sprintsPerQuarter)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
                    .tracking(1)
                Spacer()
                Text("Q\(state.quarterNumber)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(SprintTheme.accentGradient)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(state.workingDaysElapsed)")
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(SprintTheme.primary)
                    .contentTransition(.numericText())
                Text("of \(state.workingDaysInSprint)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
            }
            SprintProgressBar(progress: state.progress)
            HStack(spacing: 6) {
                Text("\(Int((state.progress * 100).rounded()))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SprintTheme.primary)
                Text("·").font(.system(size: 12)).foregroundStyle(SprintTheme.label)
                Text("\(state.workingDaysRemaining) working days left")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
            }
            HStack(spacing: 6) {
                Text("Next: Sprint \(state.nextSprintInQuarter)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
                Text("·").font(.system(size: 12)).foregroundStyle(SprintTheme.label)
                Text("starts \(sprintDateString(state.nextSprintStart))")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(SprintTheme.label)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
