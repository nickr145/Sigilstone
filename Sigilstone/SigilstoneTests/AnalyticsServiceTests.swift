//
//  AnalyticsServiceTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

final class SpyAnalyticsService: AnalyticsService {
    var trackedEvents: [(event: String, properties: [String: Any])] = []
    func track(event: String, properties: [String: Any]) {
        trackedEvents.append((event, properties))
    }
}

final class AnalyticsServiceTests: XCTestCase {
    func testGameStarted_isTracked() {
        let spy = SpyAnalyticsService()
        let viewModel = GameViewModel(analytics: spy)
        viewModel.setupComputerDifficulty(3)
        XCTAssertTrue(spy.trackedEvents.contains { $0.event == "game_started" })
    }

    func testRecordDifficultySelection_savesPreferenceAndTracksEvent() {
        let spy = SpyAnalyticsService()
        let store = InMemoryPersistenceStore()
        let viewModel = GameViewModel(persistence: store, analytics: spy)
        viewModel.recordDifficultySelection(5)
        XCTAssertEqual(store.loadPreferences().preferredDifficulty, 5)
        let event = spy.trackedEvents.first { $0.event == "difficulty_selected" }
        XCTAssertEqual(event?.properties["level"] as? Int, 5)
    }
}
