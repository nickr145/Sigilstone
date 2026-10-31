//
//  EngineStateTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import XCTest
@testable import Sigilstone

final class EngineStateTests: XCTestCase {

    private func blank(owner: Int) -> Stone {
        Stone(top: 0, right: 0, bottom: 0, left: 0, owner: owner)
    }

    // MARK: - BoardGeometry

    func testNeighbors_matchTheBoardLayout() {
        let expected: [[String]] = [
            ["bottom3", "right1"],
            ["bottom4", "left0", "right2"],
            ["bottom5", "left1"],
            ["top0", "bottom6", "right4"],
            ["top1", "bottom7", "left3", "right5"],
            ["top2", "bottom8", "left4"],
            ["top3", "right7"],
            ["top4", "left6", "right8"],
            ["top5", "left7"]
        ]
        for cell in 0..<9 {
            let actual = BoardGeometry.neighbors(of: cell).map { "\($0.direction)\($0.index)" }
            XCTAssertEqual(actual, expected[cell], "cell \(cell)")
        }
    }

    func testNeighbors_areMutual() {
        func opposite(_ direction: Direction) -> Direction {
            switch direction {
            case .top: return .bottom
            case .bottom: return .top
            case .left: return .right
            case .right: return .left
            }
        }
        for cell in 0..<9 {
            for (direction, neighbor) in BoardGeometry.neighbors(of: cell) {
                let back = BoardGeometry.neighbors(of: neighbor).first { $0.index == cell }
                XCTAssertEqual(back?.direction, opposite(direction),
                               "cell \(neighbor) should see cell \(cell) in the opposite direction")
            }
        }
    }

    // MARK: - GameState

    func testNewState_isAnEmptyBoardWithTheGivenHandsAndStarter() {
        let hand1 = [blank(owner: 1)]
        let hand2 = [blank(owner: 2), blank(owner: 2)]
        let state = GameState(player1Hand: hand1, player2Hand: hand2, startingPlayer: 2)

        XCTAssertEqual(state.board.count, 9)
        XCTAssertTrue(state.board.allSatisfy { $0 == nil })
        XCTAssertEqual(state.hand(for: 1), hand1)
        XCTAssertEqual(state.hand(for: 2), hand2)
        XCTAssertEqual(state.currentPlayer, 2)
        XCTAssertEqual(state.emptyCells, Array(0..<9))
        XCTAssertFalse(state.isOver)
        XCTAssertNil(state.winner, "an empty board counts as a tie, like calculateWinner today")
    }

    func testIsOver_onlyWhenEveryCellIsFilled() {
        var state = GameState(player1Hand: [], player2Hand: [], startingPlayer: 2)
        for cell in 0..<8 { state.board[cell] = blank(owner: 1) }
        XCTAssertFalse(state.isOver)
        XCTAssertEqual(state.emptyCells, [8])

        state.board[8] = blank(owner: 2)
        XCTAssertTrue(state.isOver)
        XCTAssertTrue(state.emptyCells.isEmpty)
    }

    func testScoreAndWinner() {
        var state = GameState(player1Hand: [], player2Hand: [], startingPlayer: 2)
        for cell in 0..<5 { state.board[cell] = blank(owner: 2) }
        for cell in 5..<9 { state.board[cell] = blank(owner: 1) }
        XCTAssertEqual(state.score(for: 1), 4)
        XCTAssertEqual(state.score(for: 2), 5)
        XCTAssertEqual(state.winner, 2)

        state.board[0] = nil // 4-4 with one cell empty
        XCTAssertNil(state.winner)
    }

    func testState_isAValue_copiesDoNotShareChanges() {
        let original = GameState(player1Hand: [], player2Hand: [], startingPlayer: 2)
        var copy = original
        copy.board[4] = blank(owner: 1)
        copy.currentPlayer = 1

        XCTAssertNil(original.board[4])
        XCTAssertEqual(original.currentPlayer, 2)
        XCTAssertNotEqual(original, copy)
    }
}
