//
//  CaptureRulesTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import XCTest
@testable import Sigilstone

final class CaptureRulesTests: XCTestCase {

    private func stone(_ top: Int, _ right: Int, _ bottom: Int, _ left: Int, owner: Int) -> Stone {
        Stone(top: top, right: right, bottom: bottom, left: left, owner: owner)
    }

    private func emptyBoard() -> [Stone?] {
        Array(repeating: nil, count: 9)
    }

    func testCapturedCells_eachDirection() {
        let cases: [(direction: String, neighborCell: Int, attacker: Stone)] = [
            ("top", 1, stone(5, 0, 0, 0, owner: 2)),
            ("right", 5, stone(0, 5, 0, 0, owner: 2)),
            ("bottom", 7, stone(0, 0, 5, 0, owner: 2)),
            ("left", 3, stone(0, 0, 0, 5, owner: 2))
        ]
        for testCase in cases {
            var board = emptyBoard()
            board[testCase.neighborCell] = stone(1, 1, 1, 1, owner: 1)

            let captured = CaptureRules.capturedCells(by: testCase.attacker, at: 4, on: board)

            XCTAssertEqual(captured, [testCase.neighborCell], testCase.direction)
        }
    }

    func testCapturedCells_listsEveryBeatenNeighbor() {
        var board = emptyBoard()
        for cell in [1, 3, 5, 7] { board[cell] = stone(1, 1, 1, 1, owner: 1) }

        // Beats the top (1) and right (5) neighbors; loses to the bottom and left.
        let captured = CaptureRules.capturedCells(by: stone(5, 5, 0, 0, owner: 2), at: 4, on: board)

        XCTAssertEqual(captured, [1, 5])
    }

    func testCapturedCells_ignoresOwnStonesAndEmptyCells() {
        var board = emptyBoard()
        board[1] = stone(1, 1, 1, 1, owner: 2) // the attacker's own stone

        let captured = CaptureRules.capturedCells(by: stone(9, 9, 9, 9, owner: 2), at: 4, on: board)

        XCTAssertEqual(captured, [])
    }

    func testCapturedCells_equalOrLowerEdgesCaptureNothing() {
        var board = emptyBoard()
        for cell in [1, 3, 5, 7] { board[cell] = stone(2, 2, 2, 2, owner: 1) }

        let captured = CaptureRules.capturedCells(by: stone(2, 2, 1, 1, owner: 2), at: 4, on: board)

        XCTAssertEqual(captured, [])
    }

    func testCapturedCells_doNotWrapAcrossRows() {
        var board = emptyBoard()
        board[3] = stone(0, 0, 0, 0, owner: 1)
        XCTAssertEqual(CaptureRules.capturedCells(by: stone(0, 9, 0, 0, owner: 2), at: 2, on: board), [])

        board = emptyBoard()
        board[2] = stone(0, 0, 0, 0, owner: 1)
        XCTAssertEqual(CaptureRules.capturedCells(by: stone(0, 0, 0, 9, owner: 2), at: 3, on: board), [])
    }
}
