//
//  AIEquivalenceTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-10-31.
//
//  TEMPORARY: compares the old view-model AI with the new strategies.
//  Deleted in step 6b, once the old AI code is gone.
//

import XCTest
@testable import Sigilstone

final class AIEquivalenceTests: XCTestCase {

    /// Runs the OLD view-model AI for `level` on `state` and reports what it placed.
    private func oldChoice(level: Int, on state: GameState) -> (cell: Int, stoneID: UUID)? {
        let viewModel = GameViewModel(persistence: InMemoryPersistenceStore(), analytics: SpyAnalyticsService())
        viewModel.selectedDifficulty = level
        viewModel.board = state.board
        viewModel.player1Pieces = state.player1Hand
        viewModel.player2Pieces = state.player2Hand
        viewModel.currentPlayer = state.currentPlayer
        viewModel.performComputerMove()

        guard let cell = state.emptyCells.first(where: { viewModel.board[$0] != nil }),
              let placed = viewModel.board[cell] else { return nil }
        return (cell, placed.id)
    }

    func testLevel6_choosesExactlyWhatTheOldCodeChose() {
        var rng = SeededGenerator(seed: 6)
        for position in 0..<300 {
            let state = TestPositions.randomPosition(using: &rng)
            guard let old = oldChoice(level: 6, on: state),
                  let ported = AIStrategies.strategy(forlevel: 6).chooseMove(in: state, using: &rng) else {
                return XCTFail("position \(position): no move")
            }
            XCTAssertEqual(ported.cell, old.cell, "position \(position)")
            XCTAssertEqual(ported.stone.id, old.stoneID, "position \(position)")
        }
    }

    func testLevel5_choosesTheSameCellAsTheOldCode() {
        var rng = SeededGenerator(seed: 5)
        for position in 0..<300 {
            // Uniform hand: which stone is drawn can't change a cell's score.
            let state = TestPositions.randomPosition(using: &rng, uniformComputerHand: true)
            guard let old = oldChoice(level: 5, on: state),
                  let ported = AIStrategies.strategy(forlevel: 5).chooseMove(in: state, using: &rng) else {
                return XCTFail("position \(position): no move")
            }
            XCTAssertEqual(ported.cell, old.cell, "position \(position)")
        }
    }

    func testLevels3And4_takeTheSameCellAsTheOldCodeWheneverACaptureExists() {
        var rng = SeededGenerator(seed: 34)
        for level in [3, 4] {
            for position in 0..<300 {
                let state = TestPositions.randomPosition(using: &rng, uniformComputerHand: true)
                let sample = state.player2Hand[0]
                let captureExists = state.emptyCells.contains {
                    !CaptureRules.capturedCells(by: sample, at: $0, on: state.board).isEmpty
                }
                guard let old = oldChoice(level: level, on: state),
                      let ported = AIStrategies.strategy(forlevel: level).chooseMove(in: state, using: &rng) else {
                    return XCTFail("level \(level), position \(position): no move")
                }
                if captureExists {
                    XCTAssertEqual(ported.cell, old.cell, "level \(level), position \(position)")
                } else {
                    XCTAssertTrue(state.emptyCells.contains(ported.cell), "level \(level), position \(position)")
                }
            }
        }
    }
}
