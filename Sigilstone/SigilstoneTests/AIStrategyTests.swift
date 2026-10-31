//
//  AIStrategyTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-10-31.
//

import XCTest
@testable import Sigilstone

/// Shared by the AI tests: random stones and random mid-game positions.
enum TestPositions {
    static func randomStone(owner: Int, using rng: inout SeededGenerator) -> Stone {
        let top = Int.random(in: 0...5, using: &rng)
        let right = Int.random(in: 0...5, using: &rng)
        let bottom = Int.random(in: 0...5, using: &rng)
        let left = Int.random(in: 0...5, using: &rng)
        return Stone(top: top, right: right, bottom: bottom, left: left, owner: owner)
    }

    /// The computer (player 2) to move, after 0, 2, 4 or 6 random moves have been played.
    /// With `uniformComputerHand`, all of the computer's stones have the same edges
    /// (but different ids), so which stone gets picked can't change a move's score.
    static func randomPosition(using rng: inout SeededGenerator, uniformComputerHand: Bool = false) -> GameState {
        let template = randomStone(owner: 2, using: &rng)
        var hand2: [Stone] = []
        for _ in 0..<5 {
            if uniformComputerHand {
                hand2.append(Stone(top: template.top, right: template.right,
                                   bottom: template.bottom, left: template.left, owner: 2))
            } else {
                hand2.append(randomStone(owner: 2, using: &rng))
            }
        }
        var hand1: [Stone] = []
        for _ in 0..<5 {
            hand1.append(randomStone(owner: 1, using: &rng))
        }

        var state = GameState(player1Hand: hand1, player2Hand: hand2, startingPlayer: 2)
        let movesAlreadyPlayed = [0, 2, 4, 6].randomElement(using: &rng)!
        for _ in 0..<movesAlreadyPlayed {
            let move = GameRules.legalMoves(in: state).randomElement(using: &rng)!
            state = GameRules.apply(move, to: state)
        }
        return state
    }
}

final class AIStrategyTests: XCTestCase {

    private func stone(_ top: Int, _ right: Int, _ bottom: Int, _ left: Int, owner: Int) -> Stone {
        Stone(top: top, right: right, bottom: bottom, left: left, owner: owner)
    }

    private func freshState(hand1: [Stone] = [], hand2: [Stone] = []) -> GameState {
        GameState(player1Hand: hand1, player2Hand: hand2, startingPlayer: 2)
    }

    // MARK: - Level 6

    func testLookAhead_prefersTheCapture() {
        var rng = SeededGenerator(seed: 1)
        var state = freshState(hand2: [stone(0, 0, 0, 0, owner: 2), stone(5, 5, 5, 5, owner: 2)])
        state.board[1] = stone(1, 1, 1, 1, owner: 1)
        let strong = state.player2Hand[1]

        let move = LookAheadStrategy().chooseMove(in: state, using: &rng)

        // Cells 0, 2 and 4 all let the strong stone capture cell 1; ties go to the lowest.
        XCTAssertEqual(move?.cell, 0)
        XCTAssertEqual(move?.stone.id, strong.id)
    }

    func testLookAhead_avoidsPlacingWhereItWouldBeRetaken() {
        var rng = SeededGenerator(seed: 1)
        let fragile = stone(0, 0, 0, 0, owner: 2)
        let sturdy = stone(9, 9, 9, 9, owner: 2)
        let state = freshState(hand1: [stone(5, 5, 5, 5, owner: 1)], hand2: [fragile, sturdy])

        let move = LookAheadStrategy().chooseMove(in: state, using: &rng)

        XCTAssertEqual(move?.stone.id, sturdy.id, "the opponent's 5s can't beat 9s, but they beat 0s")
        XCTAssertEqual(move?.cell, 0)
    }

    func testWorstReply_countsTheStoneBeingPlaced() {
        // Carried over from the view model's simulateOpponentMove test.
        let candidate = stone(1, 1, 1, 1, owner: 2)
        let opponent = stone(1, 1, 1, 5, owner: 1)
        let board: [Stone?] = Array(repeating: nil, count: 9)

        let reply = LookAheadStrategy.worstReply(after: Move(stone: candidate, cell: 4),
                                                 on: board, opponentHand: [opponent])

        XCTAssertEqual(reply, 1, "the opponent can capture the candidate from cell 5 (left 5 beats right 1)")
    }

    // MARK: - Levels 5, 3 and 4

    private func centerTargetState() -> GameState {
        var state = freshState(hand2: [stone(5, 5, 5, 5, owner: 2), stone(5, 5, 5, 5, owner: 2)])
        state.board[4] = stone(1, 1, 1, 1, owner: 1)
        return state
    }

    func testGreedyCapture_takesTheFirstCellWithTheMostCaptures() {
        var rng = SeededGenerator(seed: 1)
        let move = GreedyCaptureStrategy().chooseMove(in: centerTargetState(), using: &rng)
        XCTAssertEqual(move?.cell, 1, "cells 1, 3, 5 and 7 each capture the center; the lowest wins")
    }

    func testCaptureFirst_takesTheFirstCapturingCell() {
        var rng = SeededGenerator(seed: 1)
        let move = CaptureFirstStrategy().chooseMove(in: centerTargetState(), using: &rng)
        XCTAssertEqual(move?.cell, 1)
    }

    // MARK: - Level 2

    func testCornerStrategy_prefersCorners_thenFallsBackToTheRest() {
        var rng = SeededGenerator(seed: 3)
        let hand = [stone(0, 0, 0, 0, owner: 2), stone(1, 1, 1, 1, owner: 2)]

        for _ in 0..<50 {
            guard let move = CornerStrategy().chooseMove(in: freshState(hand2: hand), using: &rng) else {
                return XCTFail("expected a move")
            }
            XCTAssertTrue([0, 2, 6, 8].contains(move.cell))
        }

        var cornersTaken = freshState(hand2: hand)
        for cell in [0, 2, 6, 8] { cornersTaken.board[cell] = stone(0, 0, 0, 0, owner: 1) }
        for _ in 0..<50 {
            guard let move = CornerStrategy().chooseMove(in: cornersTaken, using: &rng) else {
                return XCTFail("expected a move")
            }
            XCTAssertTrue([1, 3, 4, 5, 7].contains(move.cell))
        }
    }

    // MARK: - All levels

    func testEveryStrategy_alwaysReturnsALegalMoveFromTheHand() {
        var rng = SeededGenerator(seed: 7)
        for level in 1...6 {
            let strategy = AIStrategies.strategy(forlevel: level)
            for position in 0..<100 {
                let state = TestPositions.randomPosition(using: &rng)
                guard let move = strategy.chooseMove(in: state, using: &rng) else {
                    return XCTFail("level \(level), position \(position): no move")
                }
                XCTAssertTrue(GameRules.isLegal(move, in: state), "level \(level), position \(position)")
                XCTAssertTrue(state.hand(for: state.currentPlayer).contains(move.stone), "level \(level)")
            }
        }
    }

    func testEveryStrategy_returnsNilWhenThereIsNoMove() {
        var rng = SeededGenerator(seed: 1)
        let hand = [stone(1, 1, 1, 1, owner: 2)]
        let noStones = freshState()
        var fullBoard = freshState(hand2: hand)
        for cell in 0..<9 { fullBoard.board[cell] = stone(0, 0, 0, 0, owner: 1) }

        for level in 1...6 {
            let strategy = AIStrategies.strategy(forlevel: level)
            let withoutStones = strategy.chooseMove(in: noStones, using: &rng)
            let onFullBoard = strategy.chooseMove(in: fullBoard, using: &rng)
            XCTAssertNil(withoutStones, "level \(level), empty hand")
            XCTAssertNil(onFullBoard, "level \(level), full board")
        }
    }
}
