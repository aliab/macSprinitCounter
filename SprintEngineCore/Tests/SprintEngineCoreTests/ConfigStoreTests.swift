import XCTest
@testable import SprintEngineCore

final class ConfigStoreTests: XCTestCase {
    func testLoadReturnsNilWhenEmpty() {
        let suite = "com.aliabdolahi.sprintcounter.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertNil(ConfigStore.load(from: defaults))
    }

    func testSaveAndLoadRoundTrip() {
        let suite = "com.aliabdolahi.sprintcounter.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let config = SprintConfig(
            firstSprintStart: Date(timeIntervalSince1970: 1_700_000_000),
            workingDays: [.monday, .friday],
            sprintLengthWeeks: 3,
            sprintsPerQuarter: 4
        )
        ConfigStore.save(config, to: defaults)

        let loaded = ConfigStore.load(from: defaults)
        XCTAssertEqual(loaded, config)
    }
}