//
//  ScoringTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import XCTest
@testable import Sigilstone

final class ScoringTests: XCTestCase {

    private func blank(owner: Int) -> Stone {
        Stone(top: 0, right: 0, bottom: 0, left: 0, owner: owner)
    }

    private func board(owners: [Int?]) -> [Stone?] {
        owners.map { owner in owner.map { blank(owner: $0) } }
    }

    func testScore_countsEachPlayersStones() {
        let b = board(owners: [1, 1, 2, nil, 2, 2, nil, nil, nil])
        XCTAssertEqual(Scoring.score(for: 1, on: b), 2)
        XCTAssertEqual(Scoring.score(for: 2, on: b), 3)
    }

    func testScore_emptyBoardIsZeroForBoth() {
        let b = board(owners: Array(repeating: nil, count: 9))
        XCTAssertEqual(Scoring.score(for: 1, on: b), 0)
        XCTAssertEqual(Scoring.score(for: 2, on: b), 0)
    }

    func testIsFull_onlyWhenNoCellIsEmpty() {
        XCTAssertFalse(Scoring.isFull(board(owners: Array(repeating: nil, count: 9))))
        XCTAssertFalse(Scoring.isFull(board(owners: [1, 2, 1, 2, 1, 2, 1, 2, nil])))
        XCTAssertTrue(Scoring.isFull(board(owners: [1, 2, 1, 2, 1, 2, 1, 2, 1])))
    }

    func testWinner_moreStonesWins_equalIsATie() {
        XCTAssertEqual(Scoring.winner(on: board(owners: [1, 1, 2, nil, nil, nil, nil, nil, nil])), 1)
        XCTAssertEqual(Scoring.winner(on: board(owners: [2, 2, 2, 1, nil, nil, nil, nil, nil])), 2)
        XCTAssertNil(Scoring.winner(on: board(owners: [1, 2, nil, nil, nil, nil, nil, nil, nil])))
    }
}
