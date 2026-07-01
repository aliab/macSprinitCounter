import Foundation
import os
#if os(macOS)
import Darwin
#endif

private let log = Logger(subsystem: "com.aliabdolahi.sprintcounter", category: "ConfigStore")

public enum ConfigStore {
    public static let appGroupID = "group.com.aliabdolahi.sprintcounter"
    public static let key = "sprintConfig"
    public static let fileName = "sprintConfig.json"
    public static let debugLogFileName = "sprintConfig-debug.log"
    public static let homeConfigDirectoryName = "spirintCounter"

    public static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    public static var homeConfigDirectoryURL: URL {
        configDirectoryURL(homeDirectory: userAccountHomeDirectoryURL())
    }

    public static var homeConfigURL: URL {
        homeConfigDirectoryURL.appendingPathComponent(fileName)
    }

    public static func configDirectoryURL(homeDirectory: URL) -> URL {
        homeDirectory
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent(homeConfigDirectoryName, isDirectory: true)
    }

    public static var debugLogURL: URL? {
        homeConfigDirectoryURL.appendingPathComponent(debugLogFileName)
    }

    private static var legacyAppGroupURL: URL? {
        sharedContainerURL?.appendingPathComponent(fileName)
    }

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    public static func load() -> SprintConfig? {
        recordDebug("load() requested")
        return load(
            primaryFileURL: homeConfigURL,
            fallbackFileURL: legacyAppGroupURL,
            defaults: sharedDefaults
        )
    }

    public static func save(_ config: SprintConfig) {
        recordDebug("save() requested \(describe(config))")
        save(config, fileURL: homeConfigURL, defaults: sharedDefaults)
    }

    /// One-time migration from older stores to the home config file. Safe to call on every launch.
    public static func migrateFromUserDefaultsIfNeeded() {
        guard FileManager.default.fileExists(atPath: homeConfigURL.path) == false else {
            return
        }
        if let legacyAppGroupURL, let config = load(from: legacyAppGroupURL) {
            save(config, to: homeConfigURL)
            log.info("[ConfigStore] migrated config from app group file to home config file")
            return
        }
        if let config = load(from: sharedDefaults) {
            save(config, to: homeConfigURL)
            log.info("[ConfigStore] migrated config from UserDefaults to home config file")
        }
    }

    public static func load(fileURL: URL?, defaults: UserDefaults?) -> SprintConfig? {
        load(primaryFileURL: fileURL, fallbackFileURL: nil, defaults: defaults)
    }

    public static func load(
        primaryFileURL: URL?,
        fallbackFileURL: URL?,
        defaults: UserDefaults?
    ) -> SprintConfig? {
        if let primaryFileURL {
            recordDebug("load(primary:fallback:defaults:) primary=\(describe(primaryFileURL)) fallback=\(describe(fallbackFileURL)) defaultsAvailable=\(defaults != nil)")
            log.info("[ConfigStore] load: primary url=\(primaryFileURL.path, privacy: .public)")
            if let config = load(from: primaryFileURL) {
                save(config, to: defaults)
                recordDebug("load(primary:fallback:defaults:) success source=primary \(describe(config))")
                return config
            }
        }

        if let fallbackFileURL {
            log.info("[ConfigStore] load: fallback url=\(fallbackFileURL.path, privacy: .public)")
            if let config = load(from: fallbackFileURL) {
                if let primaryFileURL {
                    save(config, to: primaryFileURL)
                }
                save(config, to: defaults)
                recordDebug("load(primary:fallback:defaults:) success source=fallback \(describe(config))")
                return config
            }
        }

        recordDebug("load(primary:fallback:defaults:) checking defaults defaultsAvailable=\(defaults != nil)")
        guard let config = load(from: defaults) else {
            recordDebug("load(primary:fallback:defaults:) failed: no file config and no defaults config")
            return nil
        }
        if let primaryFileURL {
            save(config, to: primaryFileURL)
        }
        recordDebug("load(primary:fallback:defaults:) success source=defaults \(describe(config))")
        return config
    }

    public static func load(from url: URL) -> SprintConfig? {
        let exists = FileManager.default.fileExists(atPath: url.path)
        let byteCount = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue
        recordDebug("load(from file) path=\(url.path) exists=\(exists) bytes=\(byteCount.map(String.init) ?? "unknown")")
        do {
            let data = try Data(contentsOf: url)
            let cfg = try JSONDecoder().decode(SprintConfig.self, from: data)
            log.info("[ConfigStore] load: OK (\(data.count, privacy: .public) bytes)")
            recordDebug("load(from file) decoded OK bytes=\(data.count) \(describe(cfg))")
            if isWidgetProcess == false {
                sanitizeSharedFile(at: url)
            }
            return cfg
        } catch {
            log.info("[ConfigStore] load: FAILED \(error.localizedDescription, privacy: .public)")
            recordDebug("load(from file) FAILED \(error.localizedDescription)")
            return nil
        }
    }

    public static func load(from defaults: UserDefaults?) -> SprintConfig? {
        guard let defaults else {
            recordDebug("load(from defaults) unavailable")
            return nil
        }
        guard let data = defaults.data(forKey: key) else {
            recordDebug("load(from defaults) missing key=\(key)")
            return nil
        }
        do {
            let config = try JSONDecoder().decode(SprintConfig.self, from: data)
            recordDebug("load(from defaults) decoded OK bytes=\(data.count) \(describe(config))")
            return config
        } catch {
            recordDebug("load(from defaults) FAILED \(error.localizedDescription)")
            return nil
        }
    }

    public static func save(_ config: SprintConfig, fileURL: URL?, defaults: UserDefaults?) {
        recordDebug("save(fileURL:defaults:) start file=\(describe(fileURL)) defaultsAvailable=\(defaults != nil) \(describe(config))")
        if let fileURL {
            save(config, to: fileURL)
        } else {
            log.info("[ConfigStore] save: config file URL unavailable")
            recordDebug("save(fileURL:defaults:) no config file URL")
        }
        save(config, to: defaults)
    }

    public static func save(_ config: SprintConfig, to url: URL) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
            sanitizeSharedFile(at: url)
            log.info("[ConfigStore] save: wrote \(data.count, privacy: .public) bytes")
            recordDebug("save(to file) wrote path=\(url.path) bytes=\(data.count)")
        } catch {
            log.info("[ConfigStore] save: FAILED \(error.localizedDescription, privacy: .public)")
            recordDebug("save(to file) FAILED path=\(url.path) \(error.localizedDescription)")
        }
    }

    public static func save(_ config: SprintConfig, to defaults: UserDefaults?) {
        guard let defaults else {
            recordDebug("save(to defaults) unavailable")
            return
        }
        guard let data = try? JSONEncoder().encode(config) else {
            recordDebug("save(to defaults) encode failed")
            return
        }
        defaults.set(data, forKey: key)
        recordDebug("save(to defaults) wrote key=\(key) bytes=\(data.count)")
    }

    public static func recordDebug(_ message: String) {
        let line = "\(debugTimestamp()) [\(processLabel())] \(message)\n"
        log.error("\(line, privacy: .public)")
        guard isWidgetProcess == false else { return }
        guard let url = debugLogURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: url.path) {
                sanitizeSharedFile(at: url)
                let handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
                try handle.write(contentsOf: Data(line.utf8))
                try handle.close()
            } else {
                try Data(line.utf8).write(to: url, options: .atomic)
            }
            sanitizeSharedFile(at: url)
        } catch {
            log.error("[ConfigStore] debug file write failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    public static func describe(_ config: SprintConfig) -> String {
        let days = config.workingDays
            .map(\.shortLabel)
            .sorted()
            .joined(separator: ",")
        return "firstSprintStart=\(config.firstSprintStart) workingDays=[\(days)] sprintLengthWeeks=\(config.sprintLengthWeeks) sprintsPerQuarter=\(config.sprintsPerQuarter)"
    }

    private static func describe(_ url: URL?) -> String {
        guard let url else { return "nil" }
        return url.path
    }

    private static func debugTimestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func processLabel() -> String {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown-bundle"
        let process = ProcessInfo.processInfo.processName
        return "\(process) \(bundleID) pid=\(ProcessInfo.processInfo.processIdentifier)"
    }

    private static func userAccountHomeDirectoryURL() -> URL {
        #if os(macOS)
        if let passwd = getpwuid(getuid()), let directory = passwd.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: directory), isDirectory: true)
        }
        #endif
        return FileManager.default.homeDirectoryForCurrentUser
    }

    private static var isWidgetProcess: Bool {
        (Bundle.main.bundleIdentifier ?? "").hasSuffix(".widget")
    }

    private static func sanitizeSharedFile(at url: URL) {
        #if os(macOS)
        for attribute in ["com.apple.quarantine", "com.apple.provenance"] {
            url.withUnsafeFileSystemRepresentation { path in
                guard let path else { return }
                attribute.withCString { attributeName in
                    errno = 0
                    let result = removexattr(path, attributeName, 0)
                    if result == 0 {
                        log.info("[ConfigStore] removed xattr \(attribute, privacy: .public) from \(url.path, privacy: .public)")
                    } else if errno != ENOATTR {
                        let message = String(cString: strerror(errno))
                        log.error("[ConfigStore] remove xattr \(attribute, privacy: .public) failed for \(url.path, privacy: .public): errno=\(errno, privacy: .public) \(message, privacy: .public)")
                    }
                }
            }
        }
        #endif
    }
}
