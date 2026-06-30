import SwiftUI
import SprintEngineCore

struct SprintPreviewCard: View {
    let state: SprintState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SPRINT \(state.sprintInQuarter) OF \(state.sprintsPerQuarter)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .tracking(1)
                Spacer()
                Text("Q\(state.quarterNumber)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.55, green: 0.35, blue: 0.95), Color(red: 0.95, green: 0.40, blue: 0.70)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Day \(state.workingDaysElapsed)")
                    .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                Text("/ \(state.workingDaysInSprint)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.35, blue: 0.95), Color(red: 0.95, green: 0.40, blue: 0.70)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(1, max(0, state.progress)))
                }
            }
            .frame(height: 6)
            Text("\(Int((state.progress * 100).rounded()))% · \(state.workingDaysRemaining) working days left")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(16)
        .frame(width: 300)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color(red: 0.18, green: 0.16, blue: 0.38), Color(red: 0.42, green: 0.24, blue: 0.52)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}
