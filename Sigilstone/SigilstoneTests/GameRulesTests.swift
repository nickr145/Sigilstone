//
//  GameRulesTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import XCTest
@testable import Sigilstone

/// A tiny deterministic random source, so a failing "random game" can be replayed.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

final class GameRulesTests: XCTestCase {

    private func stone(_ top: Int, _ right: Int, _ bottom: Int, _ left: Int, owner: Int) -> Stone {
        Stone(top: top, right: right, bottom: bottom, left: left, owner: owner)
    }

    private func hand(owner: Int) -> [Stone] {
        (0..<5).map { stone($0, 0, 0, 0, owner: owner) }
    }

    private func freshState(startingPlayer: Int = 2) -> GameState {
        GameState(player1Hand: hand(owner: 1), player2Hand: hand(owner: 2), startingPlayer: startingPlayer)
    }

    // MARK: - legalMoves

    func testLegalMoves_freshState_isEveryHandStoneOnEveryCell_cellFirst() {
        let state = freshState()
        let moves = GameRules.legalMoves(in: state)

        XCTAssertEqual(moves.count, 45)
        XCTAssertTrue(moves.allSatisfy { $0.stone.owner == 2 })
        // Order: cell 0 with each stone in hand order, then cell 1, and so on.
        XCTAssertEqual(moves.prefix(5).map(\.cell), [0, 0, 0, 0, 0])
        XCTAssertEqual(moves.prefix(5).map(\.stone.id), state.player2Hand.map(\.id))
        XCTAssertEqual(moves[5].cell, 1)
    }

    func testLegalMoves_skipOccupiedCells() {
        var state = freshState()
        state.board[4] = stone(0, 0, 0, 0, owner: 1)

        let moves = GameRules.legalMoves(in: state)

        XCTAssertEqual(moves.count, 40)
        XCTAssertFalse(moves.contains { $0.cell == 4 })
    }

    func testLegalMoves_noneWhenTheGameIsOverOrTheHandIsEmpty() {
        var full = freshState()
        for cell in 0..<9 { full.board[cell] = stone(0, 0, 0, 0, owner: 1) }
        XCTAssertTrue(GameRules.legalMoves(in: full).isEmpty)

        var noHand = freshState()
        noHand.player2Hand = []
        XCTAssertTrue(GameRules.legalMoves(in: noHand).isEmpty)
    }

    // MARK: - isLegal

    func testIsLegal_matchesTodaysPlacementRules() {
        var state = freshState()
        state.board[0] = stone(0, 0, 0, 0, owner: 1)
        let mine = stone(1, 1, 1, 1, owner: 2)
        let theirs = stone(1, 1, 1, 1, owner: 1)

        XCTAssertTrue(GameRules.isLegal(Move(stone: mine, cell: 1), in: state))
        XCTAssertFalse(GameRules.isLegal(Move(stone: theirs, cell: 1), in: state), "not that player's stone")
        XCTAssertFalse(GameRules.isLegal(Move(stone: mine, cell: 0), in: state), "cell is occupied")
        XCTAssertFalse(GameRules.isLegal(Move(stone: mine, cell: -1), in: state))
        XCTAssertFalse(GameRules.isLegal(Move(stone: mine, cell: 9), in: state))

        // Today's gate doesn't check the stone is in the hand (`mine` isn't).
        XCTAssertFalse(state.player2Hand.contains(mine))
        XCTAssertTrue(GameRules.isLegal(Move(stone: mine, cell: 2), in: state))
    }

    // MARK: - apply

    func testApply_placesCapturesRemovesFromHandAndPassesTheTurn() {
        var state = freshState()
        state.board[1] = stone(1, 1, 1, 1, owner: 1)
        let strong = stone(5, 5, 5, 5, owner: 2)
        state.player2Hand[0] = strong

        let next = GameRules.apply(Move(stone: strong, cell: 4), to: state)

        XCTAssertEqual(next.board[4]?.id, strong.id)
        XCTAssertEqual(next.board[1]?.owner, 2, "the neighbor it beats is captured")
        XCTAssertEqual(next.player2Hand.count, 4)
        XCTAssertFalse(next.player2Hand.contains(strong))
        XCTAssertEqual(next.player1Hand, state.player1Hand)
        XCTAssertEqual(next.currentPlayer, 1)
    }

    func testApply_leavesTheOriginalStateUntouched() {
        let state = freshState()
        let before = state

        _ = GameRules.apply(Move(stone: state.player2Hand[0], cell: 4), to: state)

        XCTAssertEqual(state, before)
    }

    func testApply_finalMove_endsTheGameAndKeepsTheTurn() {
        var state = freshState()
        for cell in 0..<8 {
            state.board[cell] = stone(0, 0, 0, 0, owner: cell % 2 == 0 ? 1 : 2)
        }
        let last = state.player2Hand[0]

        let next = GameRules.apply(Move(stone: last, cell: 8), to: state)

        XCTAssertTrue(next.isOver)
        XCTAssertEqual(next.currentPlayer, 2, "the turn does not advance after the final move")
        XCTAssertTrue(GameRules.legalMoves(in: next).isEmpty)
    }

    // MARK: - Engine vs the view model

    /// Plays 200 random games two ways at once: through the engine, and through
    /// GameViewModel.placeSelectedPiece. After every move they must agree on the board,
    /// both hands and whose turn it is.
    func testApply_matchesTheViewModelOverManyRandomGames() {
        var rng = SeededGenerator(seed: 2026)
        for game in 0..<200 {
            let viewModel = GameViewModel(persistence: InMemoryPersistenceStore(), analytics: SpyAnalyticsService())
            viewModel.setupComputerDifficulty(Int.random(in: 1...6, using: &rng))
            var state = GameState(board: viewModel.board, player1Hand: viewModel.player1Pieces, player2Hand: viewModel.player2Pieces, currentPlayer: viewModel.currentPlayer)

            var moveNumber = 0
            while !state.isOver {
                moveNumber += 1
                let label = "game \(game), move \(moveNumber)"
                guard let move = GameRules.legalMoves(in: state).randomElement(using: &rng) else {
                    return XCTFail("\(label): no legal move before the game ended")
                }

                state = GameRules.apply(move, to: state)
                viewModel.selectedPiece = move.stone
                XCTAssertTrue(viewModel.placeSelectedPiece(at: move.cell), label)

                XCTAssertEqual(viewModel.board.map { $0?.owner }, state.board.map { $0?.owner }, label)
                XCTAssertEqual(viewModel.board.map { $0?.id }, state.board.map { $0?.id }, label)
                XCTAssertEqual(viewModel.player1Pieces.map(\.id), state.player1Hand.map(\.id), label)
                XCTAssertEqual(viewModel.player2Pieces.map(\.id), state.player2Hand.map(\.id), label)
                XCTAssertEqual(viewModel.currentPlayer, state.currentPlayer, label)
            }

            XCTAssertTrue(viewModel.isGameOver, "game \(game)")
            XCTAssertEqual(viewModel.winner, state.winner, "game \(game)")
            XCTAssertEqual(viewModel.player1Score, state.score(for: 1), "game \(game)")
            XCTAssertEqual(viewModel.player2Score, state.score(for: 2), "game \(game)")
        }
    }
}
