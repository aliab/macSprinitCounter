import SwiftUI
import SprintEngineCore
import WidgetKit

@main
struct SprintCounterApp: App {
    init() {
        ConfigStore.recordDebug("SprintCounterApp.init start")
        ConfigStore.migrateFromUserDefaultsIfNeeded()
        if ConfigStore.load() == nil {
            ConfigStore.recordDebug("SprintCounterApp.init no config found; saving default")
            ConfigStore.save(.default)
        } else {
            ConfigStore.recordDebug("SprintCounterApp.init config found")
        }
        WidgetCenter.shared.reloadAllTimelines()
        ConfigStore.recordDebug("SprintCounterApp.init requested WidgetCenter.reloadAllTimelines")
    }

    var body: some Scene {
        WindowGroup {
            ConfigWindow()
                .onOpenURL { _ in
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 720, height: 480)
    }
}
