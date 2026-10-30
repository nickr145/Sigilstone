//
//  GameViewModelTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

final class GameViewModelTests: XCTestCase {

    // MARK: - Move validation (Phase 1 regression fix)

    func testPlaceSelectedPiece_rejectsWrongOwner() {
        let viewModel = GameViewModel()
        XCTAssertEqual(viewModel.currentPlayer, 2, "startingPlayer should default to 2")

        viewModel.selectedPiece = viewModel.player1Pieces[0]
        let placed = viewModel.placeSelectedPiece(at: 0)

        XCTAssertFalse(placed)
        XCTAssertNil(viewModel.board[0])
        XCTAssertEqual(viewModel.player1Pieces.count, 5, "wrong-owner piece must not be removed from the hand")
    }

    func testPlaceSelectedPiece_succeedsForCorrectOwner() {
        let viewModel = GameViewModel()
        let piece = viewModel.player2Pieces[0]
        viewModel.selectedPiece = piece

        let placed = viewModel.placeSelectedPiece(at: 0)

        XCTAssertTrue(placed)
        XCTAssertEqual(viewModel.board[0]?.owner, 2)
        XCTAssertEqual(viewModel.player2Pieces.count, 4)
        XCTAssertEqual(viewModel.currentPlayer, 1, "turn should advance after a legal move")
    }

    func testPlaceSelectedPiece_rejectsOccupiedCell() {
        let viewModel = GameViewModel()
        viewModel.selectedPiece = viewModel.player2Pieces[0]
        XCTAssertTrue(viewModel.placeSelectedPiece(at: 0))

        // It's player 1's turn now; try to place into the same occupied cell.
        viewModel.selectedPiece = viewModel.player1Pieces[0]
        let placed = viewModel.placeSelectedPiece(at: 0)

        XCTAssertFalse(placed)
        XCTAssertEqual(viewModel.board[0]?.owner, 2, "original piece must remain untouched")
        XCTAssertEqual(viewModel.player1Pieces.count, 5)
    }

    func testResetGame_currentPlayerMatchesStartingPlayer() {
        let viewModel = GameViewModel()
        viewModel.selectedPiece = viewModel.player2Pieces[0]
        _ = viewModel.placeSelectedPiece(at: 0) // advances currentPlayer to 1

        viewModel.resetGame()

        XCTAssertEqual(viewModel.currentPlayer, 2, "resetGame() must agree with the same startingPlayer used at init")
    }

    // MARK: - Winner / tie handling

    func testCalculateWinner_tieReturnsNil() {
        let viewModel = GameViewModel()
        // Default board is entirely empty -> 0-0 is a tie.
        XCTAssertNil(viewModel.calculateWinner())
    }

    func testCalculateWinner_returnsPlayerWithMoreStones() {
        let viewModel = GameViewModel()
        viewModel.board[0] = Stone(top: 1, right: 1, bottom: 1, left: 1, owner: 1)
        viewModel.board[1] = Stone(top: 1, right: 1, bottom: 1, left: 1, owner: 1)
        viewModel.board[2] = Stone(top: 1, right: 1, bottom: 1, left: 1, owner: 2)

        XCTAssertEqual(viewModel.calculateWinner(), 1)
    }

    // MARK: - Capture logic works regardless of which side owns the neighbor
    // (regression test for canCaptureAt's previously-hardcoded owner == 1 check)

    func testCanCaptureAt_capturesPlayer1NeighborWithPlayer2Piece() {
        let viewModel = GameViewModel()
        viewModel.board[1] = Stone(top: 1, right: 1, bottom: 1, left: 1, owner: 1)
        let attacker = Stone(top: 5, right: 1, bottom: 1, left: 1, owner: 2)

        XCTAssertTrue(viewModel.canCaptureAt(cell: 4, with: attacker))
    }

    func testCanCaptureAt_capturesPlayer2NeighborWithPlayer1Piece() {
        let viewModel = GameViewModel()
        viewModel.board[1] = Stone(top: 1, right: 1, bottom: 1, left: 1, owner: 2)
        let attacker = Stone(top: 5, right: 1, bottom: 1, left: 1, owner: 1)

        XCTAssertTrue(viewModel.canCaptureAt(cell: 4, with: attacker))
    }

    func testCanCaptureAt_doesNotCaptureOwnPiece() {
        let viewModel = GameViewModel()
        viewModel.board[1] = Stone(top: 1, right: 1, bottom: 1, left: 1, owner: 2)
        let sameOwner = Stone(top: 5, right: 1, bottom: 1, left: 1, owner: 2)

        XCTAssertFalse(viewModel.canCaptureAt(cell: 4, with: sameOwner))
    }

    // MARK: - AI move selection (Phase 2 bug fixes)

    func testLvl2ComputerMove_prefersCorners_whenAvailable() {
        let viewModel = GameViewModel()
        viewModel.Lvl2ComputerMove()

        let placedIndex = viewModel.board.firstIndex { $0 != nil }
        XCTAssertNotNil(placedIndex)
        XCTAssertTrue([0, 2, 6, 8].contains(placedIndex!), "Lvl2 should prefer a corner cell when corners are available")
    }

    func testSimulateOpponentMove_accountsForOwnPlacementWhenEvaluatingThreat() {
        let viewModel = GameViewModel()
        // A weak candidate stone the AI is considering placing at cell 4 (center).
        let weakCandidate = Stone(top: 1, right: 1, bottom: 1, left: 1, owner: 2)
        // An opponent piece that can capture it from cell 5 (left = 5 beats right = 1).
        let strongOpponentPiece = Stone(top: 1, right: 1, bottom: 1, left: 5, owner: 1)
        viewModel.player1Pieces = [strongOpponentPiece]

        // Pre-fix, this evaluated the opponent's reply against a board that never
        // had `weakCandidate` placed at cell 4, so the capture at cell 5 was invisible.
        XCTAssertEqual(viewModel.simulateOpponentMove(for: weakCandidate, at: 4), 1)
    }

    // MARK: - PVC game end -> next game

    private func makePVCViewModel() -> GameViewModel {
        let viewModel = GameViewModel(persistence: InMemoryPersistenceStore(), analytics: SpyAnalyticsService())
        viewModel.setupComputerDifficulty(1)
        return viewModel
    }

    /// Plays a computer-first PVC game to completion the way PVCView drives it:
    /// the computer moves on player 2's turn, the human picks a piece then a cell.
    private func playFullPVCGame(_ viewModel: GameViewModel) {
        var moves = 0
        while !viewModel.isGameOver && moves < 20 {
            if viewModel.currentPlayer == 2 {
                viewModel.performComputerMove()
            } else {
                viewModel.selectedPiece = viewModel.player1Pieces[0]
                _ = viewModel.placeSelectedPiece(at: viewModel.board.firstIndex { $0 == nil }!)
            }
            moves += 1
        }
    }

    /// Contract PVCView relies on at game end. The "OK" on GameBoardView's alert calls
    /// resetGame(); PVCView then restarts the computer from `.onChange(of: isGameOver)`
    /// (currentPlayer is still 2 after a computer-first game, so `.onChange(of:
    /// currentPlayer)` can't fire for it). The view-level trigger isn't unit-testable;
    /// this pins the state it depends on.
    func testPVCGameEnd_resetStartsCleanNextGame() {
        let viewModel = makePVCViewModel()
        let startingHand = viewModel.player1Pieces
        playFullPVCGame(viewModel)
        XCTAssertTrue(viewModel.isGameOver)
        XCTAssertEqual(viewModel.currentPlayer, 2, "computer made the last move")

        viewModel.resetGame()

        XCTAssertFalse(viewModel.isGameOver)
        XCTAssertNil(viewModel.winner)
        XCTAssertTrue(viewModel.board.allSatisfy { $0 == nil })
        XCTAssertEqual(viewModel.player1Pieces, startingHand, "player's hand must be refilled")
        XCTAssertEqual(viewModel.player2Pieces.count, 5)
        XCTAssertEqual(viewModel.currentPlayer, 2, "computer starts the next game")
    }
}
