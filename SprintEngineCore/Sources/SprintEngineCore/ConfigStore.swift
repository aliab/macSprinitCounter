import Foundation

public enum ConfigStore {
    public static let appGroupID = "group.com.aliabdolahi.sprintcounter"
    public static let key = "sprintConfig"

    public static func load() -> SprintConfig? {
        load(from: UserDefaults(suiteName: appGroupID))
    }

    public static func save(_ config: SprintConfig) {
        save(config, to: UserDefaults(suiteName: appGroupID))
    }

    public static func load(from defaults: UserDefaults?) -> SprintConfig? {
        guard let defaults, let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SprintConfig.self, from: data)
    }

    public static func save(_ config: SprintConfig, to defaults: UserDefaults?) {
        guard let defaults, let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: key)
    }
}