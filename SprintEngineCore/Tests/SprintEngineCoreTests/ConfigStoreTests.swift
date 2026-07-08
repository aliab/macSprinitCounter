import XCTest
import Darwin
@testable import SprintEngineCore

final class ConfigStoreTests: XCTestCase {
    private func tempURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sprintConfig.\(UUID().uuidString).json")
    }

    private func tempDefaults() -> (suite: String, defaults: UserDefaults) {
        let suite = "com.aliabdolahi.sprintcounter.tests.\(UUID().uuidString)"
        return (suite, UserDefaults(suiteName: suite)!)
    }

    private func makeConfig() -> SprintConfig {
        SprintConfig(
            firstSprintStart: Date(timeIntervalSince1970: 1_700_000_000),
            workingDays: [.monday, .friday],
            sprintLengthWeeks: 3,
            sprintsPerQuarter: 4
        )
    }

    func testLoadReturnsNilWhenFileMissing() {
        let url = tempURL()
        XCTAssertNil(ConfigStore.load(from: url))
    }

    func testSaveAndLoadRoundTrip() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let config = makeConfig()
        ConfigStore.save(config, to: url)

        let loaded = ConfigStore.load(from: url)
        XCTAssertEqual(loaded, config)
    }

    func testLoadFallsBackToUserDefaultsWhenFileMissing() throws {
        let url = tempURL()
        let store = tempDefaults()
        defer { store.defaults.removePersistentDomain(forName: store.suite) }

        let config = makeConfig()
        let data = try JSONEncoder().encode(config)
        store.defaults.set(data, forKey: ConfigStore.key)

        let loaded = ConfigStore.load(fileURL: url, defaults: store.defaults)

        XCTAssertEqual(loaded, config)
    }

    func testSaveWritesFileAndUserDefaults() {
        let url = tempURL()
        let store = tempDefaults()
        defer {
            try? FileManager.default.removeItem(at: url)
            store.defaults.removePersistentDomain(forName: store.suite)
        }

        let config = makeConfig()
        ConfigStore.save(config, fileURL: url, defaults: store.defaults)

        XCTAssertEqual(ConfigStore.load(from: url), config)
        XCTAssertEqual(ConfigStore.load(from: store.defaults), config)
    }

    func testLoadFromFileMirrorsConfigToUserDefaults() {
        let url = tempURL()
        let store = tempDefaults()
        defer {
            try? FileManager.default.removeItem(at: url)
            store.defaults.removePersistentDomain(forName: store.suite)
        }

        let config = makeConfig()
        ConfigStore.save(config, to: url)

        let loaded = ConfigStore.load(fileURL: url, defaults: store.defaults)

        XCTAssertEqual(loaded, config)
        XCTAssertEqual(ConfigStore.load(from: store.defaults), config)
    }

    func testSaveCreatesParentDirectoryForConfigFile() {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spirintCounter.\(UUID().uuidString)", isDirectory: true)
        let url = directory.appendingPathComponent(ConfigStore.fileName)
        defer { try? FileManager.default.removeItem(at: directory) }

        let config = makeConfig()
        ConfigStore.save(config, to: url)

        XCTAssertEqual(ConfigStore.load(from: url), config)
    }

    func testLoadMigratesFromFallbackFileToPrimaryFile() {
        let primaryURL = tempURL()
        let fallbackURL = tempURL()
        let store = tempDefaults()
        defer {
            try? FileManager.default.removeItem(at: primaryURL)
            try? FileManager.default.removeItem(at: fallbackURL)
            store.defaults.removePersistentDomain(forName: store.suite)
        }

        let config = makeConfig()
        ConfigStore.save(config, to: fallbackURL)

        let loaded = ConfigStore.load(
            primaryFileURL: primaryURL,
            fallbackFileURL: fallbackURL,
            defaults: store.defaults
        )

        XCTAssertEqual(loaded, config)
        XCTAssertEqual(ConfigStore.load(from: primaryURL), config)
        XCTAssertEqual(ConfigStore.load(from: store.defaults), config)
    }

    func testPrimaryFileWinsOverFallbackFile() {
        let primaryURL = tempURL()
        let fallbackURL = tempURL()
        let store = tempDefaults()
        defer {
            try? FileManager.default.removeItem(at: primaryURL)
            try? FileManager.default.removeItem(at: fallbackURL)
            store.defaults.removePersistentDomain(forName: store.suite)
        }

        let primaryConfig = makeConfig()
        let fallbackConfig = SprintConfig.default
        ConfigStore.save(primaryConfig, to: primaryURL)
        ConfigStore.save(fallbackConfig, to: fallbackURL)

        let loaded = ConfigStore.load(
            primaryFileURL: primaryURL,
            fallbackFileURL: fallbackURL,
            defaults: store.defaults
        )

        XCTAssertEqual(loaded, primaryConfig)
    }

    func testSaveRemovesQuarantineAttributesFromFile() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try Data("stale".utf8).write(to: url)
        try setExtendedAttribute(name: "com.apple.quarantine", value: "0086;test;SprintCounter;", url: url)

        ConfigStore.save(makeConfig(), to: url)

        XCTAssertFalse(hasExtendedAttribute(name: "com.apple.quarantine", url: url))
    }

    func testLoadRemovesQuarantineAttributesFromReadableFile() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        ConfigStore.save(makeConfig(), to: url)
        try setExtendedAttribute(name: "com.apple.quarantine", value: "0086;test;SprintCounter;", url: url)

        XCTAssertNotNil(ConfigStore.load(from: url))

        XCTAssertFalse(hasExtendedAttribute(name: "com.apple.quarantine", url: url))
    }

    private func setExtendedAttribute(name: String, value: String, url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { path in
            guard let path else { throw CocoaError(.fileNoSuchFile) }
            let result = value.withCString { valuePointer in
                setxattr(path, name, valuePointer, strlen(valuePointer), 0, 0)
            }
            if result != 0 { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        }
    }

    private func hasExtendedAttribute(name: String, url: URL) -> Bool {
        url.withUnsafeFileSystemRepresentation { path in
            guard let path else { return false }
            return getxattr(path, name, nil, 0, 0, 0) >= 0
        }
    }
}
