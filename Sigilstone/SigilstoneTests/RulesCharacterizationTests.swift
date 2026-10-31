//
//  RulesCharacterizationTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-10-30.
//
//  Pins down how capture, placement and game-end rules behave TODAY, so the
//  Phase 2 engine extraction can be checked against them.
//

import Foundation
import XCTest
@testable import Sigilstone

final class RulesCharacterizationTests : XCTestCase {
    // MARK: - Helpers
    private func makeViewModel() -> GameViewModel {
        GameViewModel(persistence: InMemoryPersistenceStore(), analytics: SpyAnalyticsService())
    }
    
    private func stone(_ top: Int, _ right: Int, _ bottom: Int, _ left: Int, owner: Int) -> Stone {
        Stone(top: top, right: right, bottom: bottom, left: left, owner: owner)
    }
    
    /// Places `piece` at `cell` as that piece's owner, the way a real turn does.
    @discardableResult
    private func play(_ piece: Stone, at cell: Int, on viewModel: GameViewModel) -> Bool {
        viewModel.currentPlayer = piece.owner
        viewModel.selectedPiece = piece
        return viewModel.placeSelectedPiece(at: cell)
    }
    
    // MARK: - Captures
    
    func testCapture_eachDirection_flipsTheNeighborItBeats() {
        // The attacker lands in the center (cell 4). Only the edge facing the
        // neighbor is strong; every other edge is 0.
        let cases: [(direction: String, neighborCell: Int, attacker: Stone)] = [
            ("top", 1, stone(5, 0, 0, 0, owner: 2)),
            ("right", 5, stone(0, 5, 0, 0, owner: 2)),
            ("bottom", 7, stone(0, 0, 5, 0, owner: 2)),
            ("left", 3, stone(0, 0, 0, 5, owner: 2))
        ]
        for testCase in cases {
            let viewModel = makeViewModel()
            viewModel.board[testCase.neighborCell] = stone(1, 1, 1, 1, owner: 1)
            
            XCTAssertTrue(play(testCase.attacker, at: 4, on: viewModel))
            
            XCTAssertEqual(viewModel.board[testCase.neighborCell]?.owner, 2, "\(testCase.direction): a higher facing edge should capture")
        }
    }
    
    func testCapture_equalOrLowerEdge_changesNothing() {
        let viewModel = makeViewModel()
        for cell in [1, 3, 5, 7] {
            viewModel.board[cell] = stone(2, 2, 2, 2, owner: 1)
        }
        // Edges of 2 tie the neighbors' 2s; edges of 1 are lower.
        XCTAssertTrue(play(stone(2, 2, 1, 1, owner: 2), at: 4, on: viewModel))

        for cell in [1, 3, 5, 7] {
            XCTAssertEqual(viewModel.board[cell]?.owner, 1, "cell \(cell) should not change hands")
        }
    }

    func testCapture_onlyTheFacingEdgeMatters() {
        let viewModel = makeViewModel()
        viewModel.board[5] = stone(1, 1, 1, 1, owner: 1) // right of the center
        // Strong on the top edge only; the right edge, which faces cell 5, is 0.
        XCTAssertTrue(play(stone(5, 0, 0, 0, owner: 2), at: 4, on: viewModel))

        XCTAssertEqual(viewModel.board[5]?.owner, 1)
    }

    func testCapture_multipleNeighbors_onlyTheBeatenOnesFlip() {
        let viewModel = makeViewModel()
        for cell in [1, 3, 5, 7] {
            viewModel.board[cell] = stone(1, 1, 1, 1, owner: 1)
        }
        // Beats the top (cell 1) and right (cell 5) neighbors; its 0 edges lose
        // against the left (cell 3) and bottom (cell 7) ones.
        XCTAssertTrue(play(stone(5, 5, 0, 0, owner: 2), at: 4, on: viewModel))

        XCTAssertEqual([1, 3, 5, 7].map { viewModel.board[$0]?.owner }, [2, 1, 2, 1])
    }

    func testCapture_allFourNeighborsAtOnce() {
        let viewModel = makeViewModel()
        for cell in [1, 3, 5, 7] {
            viewModel.board[cell] = stone(1, 1, 1, 1, owner: 1)
        }
        XCTAssertTrue(play(stone(5, 5, 5, 5, owner: 2), at: 4, on: viewModel))

        XCTAssertEqual([1, 3, 5, 7].map { viewModel.board[$0]?.owner }, [2, 2, 2, 2])
    }

    func testStonesChangeHandsBackAndForth() {
        let viewModel = makeViewModel()
        viewModel.board[0] = stone(1, 2, 2, 1, owner: 2)

        // Player 1 beats its right edge from cell 1 (left 3 > right 2)...
        XCTAssertTrue(play(stone(1, 1, 1, 3, owner: 1), at: 1, on: viewModel))
        XCTAssertEqual(viewModel.board[0]?.owner, 1)

        // ...then player 2 takes it back from cell 3 (top 3 > bottom 2).
        XCTAssertTrue(play(stone(3, 1, 1, 1, owner: 2), at: 3, on: viewModel))
        XCTAssertEqual(viewModel.board[0]?.owner, 2)
        XCTAssertEqual(viewModel.board[1]?.owner, 1, "the stone that made the first capture is untouched")
    }

    // MARK: - Board edges

    func testEdgeCells_doNotWrapAroundTheBoard() {
        // Cells 2 and 3 are neighbors in the array but not on the board (end of
        // one row, start of the next). The same goes for 5 and 6.
        let cases: [(attackerCell: Int, victimCell: Int, attacker: Stone)] = [
            (2, 3, stone(0, 9, 0, 0, owner: 2)),
            (3, 2, stone(0, 0, 0, 9, owner: 2)),
            (5, 6, stone(0, 9, 0, 0, owner: 2)),
            (6, 5, stone(0, 0, 0, 9, owner: 2))
        ]
        for testCase in cases {
            let viewModel = makeViewModel()
            viewModel.board[testCase.victimCell] = stone(0, 0, 0, 0, owner: 1)

            XCTAssertTrue(play(testCase.attacker, at: testCase.attackerCell, on: viewModel))

            XCTAssertEqual(viewModel.board[testCase.victimCell]?.owner, 1, "cell \(testCase.attackerCell) must not capture across the row break at \(testCase.victimCell)")
        }
    }

    func testPlacingOnEveryCell_neverGoesOutOfBounds() {
        for cell in 0..<9 {
            let viewModel = makeViewModel()
            XCTAssertTrue(play(stone(9, 9, 9, 9, owner: 2), at: cell, on: viewModel), "cell \(cell)")
        }
    }

    // MARK: - Placement rules

    func testPlaceSelectedPiece_rejectsMissingSelectionAndOutOfRangeCells() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.placeSelectedPiece(at: 0), "nothing is selected")

        viewModel.selectedPiece = viewModel.player2Pieces[0]
        XCTAssertFalse(viewModel.placeSelectedPiece(at: -1))
        XCTAssertFalse(viewModel.placeSelectedPiece(at: 9))
        XCTAssertTrue(viewModel.board.allSatisfy { $0 == nil })
        XCTAssertEqual(viewModel.player2Pieces.count, 5)
    }

    func testPlacing_removesExactlyThatPieceFromTheHand() {
        let viewModel = makeViewModel()
        let hand = viewModel.player2Pieces
        let chosen = hand[2]
        viewModel.selectedPiece = chosen

        XCTAssertTrue(viewModel.placeSelectedPiece(at: 4))

        XCTAssertEqual(viewModel.player2Pieces.map(\.id), hand.filter { $0.id != chosen.id }.map(\.id))
        XCTAssertNil(viewModel.selectedPiece, "selection is cleared after a placement")
    }

    // MARK: - Scores, game end, winner

    func testScores_countCapturedStones() {
        let viewModel = makeViewModel()
        viewModel.board[0] = stone(1, 2, 2, 1, owner: 2)

        XCTAssertTrue(play(stone(1, 1, 1, 3, owner: 1), at: 1, on: viewModel)) // captures cell 0

        XCTAssertEqual(viewModel.player1Score, 2)
        XCTAssertEqual(viewModel.player2Score, 0)
    }

    func testFullGame_endsOnTheNinthMove() {
        let viewModel = makeViewModel()
        // Stones with all-0 edges never capture, so ownership comes purely from
        // who placed what. Player 2 moves first, so player 2 makes moves 1, 3, 5, 7, 9.
        for cell in 0..<9 {
            XCTAssertFalse(viewModel.isGameOver, "game should not be over before move \(cell + 1)")
            let owner = viewModel.currentPlayer
            XCTAssertTrue(play(stone(0, 0, 0, 0, owner: owner), at: cell, on: viewModel))
        }

        XCTAssertTrue(viewModel.isGameOver)
        XCTAssertEqual(viewModel.winner, 2)
        XCTAssertEqual(viewModel.player1Score, 4)
        XCTAssertEqual(viewModel.player2Score, 5)
        XCTAssertEqual(viewModel.currentPlayer, 2, "the turn does not advance after the final move")
        XCTAssertFalse(play(stone(0, 0, 0, 0, owner: 1), at: 0, on: viewModel), "no moves after game over")
    }

    func testCheckGameOver_isTrueOnlyWhenEveryCellIsFilled() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.checkGameOver())

        for cell in 0..<8 {
            viewModel.board[cell] = stone(0, 0, 0, 0, owner: 1)
        }
        XCTAssertFalse(viewModel.checkGameOver())

        viewModel.board[8] = stone(0, 0, 0, 0, owner: 2)
        XCTAssertTrue(viewModel.checkGameOver())
    }

    func testCalculateWinner_fourAllWithOneEmptyCell_isATie() {
        let viewModel = makeViewModel()
        for cell in 0..<4 { viewModel.board[cell] = stone(0, 0, 0, 0, owner: 1) }
        for cell in 4..<8 { viewModel.board[cell] = stone(0, 0, 0, 0, owner: 2) }

        XCTAssertNil(viewModel.calculateWinner())
    }

    // MARK: - Helpers the AI relies on

    func testSimulateMove_countsCapturesWithoutChangingTheBoard() {
        let viewModel = makeViewModel()
        viewModel.board[1] = stone(1, 1, 1, 1, owner: 1)
        viewModel.board[3] = stone(1, 1, 1, 1, owner: 1)
        let attacker = stone(5, 5, 5, 5, owner: 2)

        XCTAssertEqual(viewModel.simulateMove(for: attacker, at: 4), 2)

        XCTAssertNil(viewModel.board[4])
        XCTAssertEqual(viewModel.board[1]?.owner, 1)
        XCTAssertEqual(viewModel.board[3]?.owner, 1)

        // With an explicit board it ignores the live one.
        var hypothetical: [Stone?] = Array(repeating: nil, count: 9)
        hypothetical[5] = stone(1, 1, 1, 1, owner: 1)
        XCTAssertEqual(viewModel.simulateMove(for: attacker, at: 4, on: hypothetical), 1)
    }

    func testCanCaptureAdjacent_andCanCaptureAt_agreeOnEveryCell() {
        // These two functions are duplicates today; the engine will keep one.
        let viewModel = makeViewModel()
        viewModel.board[4] = stone(1, 1, 1, 1, owner: 1)
        let piece = stone(5, 5, 5, 5, owner: 2)

        for cell in 0..<9 where viewModel.board[cell] == nil {
            XCTAssertEqual(viewModel.canCaptureAdjacent(at: cell, with: piece), viewModel.canCaptureAt(cell: cell, with: piece), "cell \(cell)")
        }
        let capturing = (0..<9).filter { viewModel.board[$0] == nil && viewModel.canCaptureAt(cell: $0, with: piece) }
        XCTAssertEqual(capturing, [1, 3, 5, 7])
    }
}

