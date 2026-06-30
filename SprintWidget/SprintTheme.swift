import SwiftUI

enum SprintTheme {
    static let containerGradient = LinearGradient(
        colors: [Color(red: 0.18, green: 0.16, blue: 0.38), Color(red: 0.42, green: 0.24, blue: 0.52)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.35, blue: 0.95), Color(red: 0.95, green: 0.40, blue: 0.70)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let label = Color.white.opacity(0.6)
    static let primary = Color.white
    static let track = Color.white.opacity(0.15)
}

struct SprintProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(SprintTheme.track)
                Capsule().fill(SprintTheme.accentGradient)
                    .frame(width: geo.size.width * min(1, max(0, progress)))
            }
        }
        .frame(height: 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

func sprintDateString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f.string(from: date)
}
