//
//  PersistenceManagerTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

final class InMemoryPersistenceStore: PersistenceStore {
    private var preferences = GamePreferences()
    private var stats = GameStats()
    func loadPreferences() -> GamePreferences { preferences }
    func save(_ preferences: GamePreferences) { self.preferences = preferences }
    func loadStats() -> GameStats { stats }
    func save(_ stats: GameStats) { self.stats = stats }
}

final class PersistenceManagerTests: XCTestCase {
    private let suiteName = "com.sigilstone.tests.PersistenceManagerTests"

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testPreferencesRoundTrip() {
        let store = UserDefaultsPersistenceStore(defaults: UserDefaults(suiteName: suiteName)!)
        let prefs = GamePreferences(preferredDifficulty: 4, isAudioMuted: true)
        store.save(prefs)
        XCTAssertEqual(store.loadPreferences(), prefs)
    }

    func testStatsRoundTrip() {
        let store = UserDefaultsPersistenceStore(defaults: UserDefaults(suiteName: suiteName)!)
        let stats = GameStats(gamesPlayed: 3, gamesWonByPlayer1: 2, gamesWonByPlayer2: 1)
        store.save(stats)
        XCTAssertEqual(store.loadStats(), stats)
    }

    func testGameViewModel_incrementsStatsOnWin() {
        let inMemoryStore = InMemoryPersistenceStore()
        let viewModel = GameViewModel(persistence: inMemoryStore)
        viewModel.setupComputerDifficulty(1) // stats are recorded for PvC games only

        // Fill the board so checkGameOver() becomes true after the next placement.
        // currentPlayer starts at 2; alternate turns, always placing whichever
        // piece belongs to the current player into the first empty cell, until
        // the game reports over.
        while !viewModel.isGameOver {
            guard let emptyIndex = viewModel.board.firstIndex(where: { $0 == nil }) else { break }
            let piecesForCurrentPlayer = viewModel.currentPlayer == 1 ? viewModel.player1Pieces : viewModel.player2Pieces
            guard let piece = piecesForCurrentPlayer.first else { break }
            viewModel.selectedPiece = piece
            let placed = viewModel.placeSelectedPiece(at: emptyIndex)
            XCTAssertTrue(placed, "expected a legal placement to succeed while filling the board")
        }

        XCTAssertTrue(viewModel.isGameOver)
        XCTAssertEqual(inMemoryStore.loadStats().gamesPlayed, 1)
    }
}
