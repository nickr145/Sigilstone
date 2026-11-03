//
//  DeckTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

final class DeckTests: XCTestCase {

    private func elements(_ tiles: [Tile]) -> Set<Element> { Set(tiles.compactMap(\.element)) }

    // MARK: - Starter collection and deck

    func testStarterCollection_isTheEightElementalCommons() {
        let tiles = Starter.collection.compactMap { TileSet.byID[$0] }

        XCTAssertEqual(Starter.collection.count, 8)
        XCTAssertEqual(Set(Starter.collection).count, 8, "no duplicates")
        XCTAssertEqual(tiles.count, 8, "every id resolves")
        XCTAssertTrue(tiles.allSatisfy { $0.rarity == .common && $0.element != nil })
        for element in Element.allCases {
            XCTAssertEqual(tiles.filter { $0.element == element }.count, 2, "\(element)")
        }
    }

    func testStarterDeck_isFiveOwnedCommonsCoveringAllFourElements() {
        let tiles = Deck.starter.tiles

        XCTAssertEqual(Deck.starter.tileIDs.count, Deck.size)
        XCTAssertEqual(Set(Deck.starter.tileIDs).count, Deck.size)
        XCTAssertEqual(tiles.count, Deck.size, "every id resolves")
        XCTAssertTrue(Deck.starter.tileIDs.allSatisfy(Starter.collection.contains), "the deck is made of owned tiles")
        XCTAssertTrue(tiles.allSatisfy { $0.rarity == .common && $0.element != nil }, "commons only, no plain tile")
        XCTAssertEqual(elements(tiles), Set(Element.allCases))
    }

    func testStandardDeck_isTheStarterDeck() {
        XCTAssertEqual(Deck.standard, Deck.starter)
    }

    // MARK: - Opponent decks

    /// The design table: rarity mix and total edge sum per level. The sums come from
    /// the fixed per-tier sums, so they stay put if the tile set is regenerated.
    private let design: [Int: (mix: [Rarity: Int], total: Int)] = [
        1: ([.common: 5], 60),
        2: ([.common: 5], 60),
        3: ([.common: 3, .uncommon: 2], 68),
        4: ([.common: 1, .uncommon: 4], 76),
        5: ([.uncommon: 3, .rare: 2], 88),
        6: ([.rare: 4, .epic: 1], 104),
    ]

    func testOpponentDecks_followTheDesignTable() {
        for level in 1...6 {
            let deck = OpponentDecks.deck(forLevel: level)
            let tiles = deck.tiles
            let expected = design[level]!

            XCTAssertEqual(deck.tileIDs.count, Deck.size, "level \(level)")
            XCTAssertEqual(Set(deck.tileIDs).count, Deck.size, "level \(level): distinct tiles")
            XCTAssertEqual(tiles.count, Deck.size, "level \(level): every id resolves")
            XCTAssertEqual(Dictionary(grouping: tiles, by: \.rarity).mapValues(\.count), expected.mix, "level \(level) rarity mix")
            XCTAssertEqual(tiles.map { $0.top + $0.right + $0.bottom + $0.left }.reduce(0, +), expected.total, "level \(level) edge total")
        }
    }

    func testOpponentDecks_coverAtLeastThreeElements() {
        for level in 1...6 {
            XCTAssertGreaterThanOrEqual(elements(OpponentDecks.deck(forLevel: level).tiles).count, 3, "level \(level)")
        }
    }

    func testOpponentDecks_unknownLevelsUseLevelOne() {
        XCTAssertEqual(OpponentDecks.deck(forLevel: 0), OpponentDecks.deck(forLevel: 1))
        XCTAssertEqual(OpponentDecks.deck(forLevel: 7), OpponentDecks.deck(forLevel: 1))
    }

    // MARK: - Stones from a deck

    func testStones_areOwnedByTheRequestedPlayerAndKeepTheirTiles() {
        let stones = Deck.starter.stones(owner: 2)

        XCTAssertEqual(stones.map(\.tileID), Deck.starter.tileIDs)
        XCTAssertTrue(stones.allSatisfy { $0.owner == 2 })
        XCTAssertEqual(stones.map(\.element), Deck.starter.tiles.map(\.element))
        XCTAssertEqual(Set(stones.map(\.id)).count, Deck.size, "each stone is its own piece")
    }
}
