//
//  BoardGeneratorTests.swift
//  SigilstoneTests
//
//  Created by Nicholas Rebello on 2026-11-02.
//

import XCTest
@testable import Sigilstone

final class BoardGeneratorTests: XCTestCase {

    func testElementalSquares_haveTheRequestedCountOnDistinctCells() {
        var rng = SeededGenerator(seed: 1)
        for count in 0...9 {
            let squares = BoardGenerator.elementalSquares(count: count, using: &rng)
            XCTAssertEqual(squares.count, 9)
            XCTAssertEqual(squares.compactMap { $0 }.count, count, "count \(count)")
        }
    }

    func testElementalSquares_clampTheCount() {
        var rng = SeededGenerator(seed: 2)
        XCTAssertEqual(BoardGenerator.elementalSquares(count: -3, using: &rng).compactMap { $0 }.count, 0)
        XCTAssertEqual(BoardGenerator.elementalSquares(count: 50, using: &rng).compactMap { $0 }.count, 9)
    }

    func testElementalSquares_sameSeedGivesTheSameLayout() {
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)

        XCTAssertEqual(BoardGenerator.elementalSquares(count: 2, using: &first), BoardGenerator.elementalSquares(count: 2, using: &second))
    }

    func testPlaceholderElements_giveTheFirstFourStonesAnElementEach() {
        let hand = (0..<5).map { Stone(top: $0, right: 1, bottom: 2, left: 3, owner: 1) }

        let assigned = PlaceholderElements.assign(to: hand)

        XCTAssertEqual(assigned.map(\.element), [.fire, .water, .earth, .air, nil])
        XCTAssertEqual(assigned.map(\.id), hand.map(\.id), "same stones, same ids")
        XCTAssertEqual(assigned.map(\.top), hand.map(\.top), "edges are untouched")
    }
}

