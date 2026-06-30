import SwiftUI
import SprintEngineCore
import WidgetKit

@main
struct SprintCounterApp: App {
    init() {
        if ConfigStore.load() == nil {
            ConfigStore.save(.default)
        }
    }

    var body: some Scene {
        WindowGroup {
            ConfigWindow()
        }
        .defaultSize(width: 720, height: 480)
    }
}
