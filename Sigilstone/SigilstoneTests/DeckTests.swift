//
//  DeckTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

final class DeckTests: XCTestCase {

    // MARK: - Starter collection and deck

    private func sortedEdges(_ tile: Tile) -> [Int] { [tile.top, tile.right, tile.bottom, tile.left].sorted() }

    func testStarterCollection_isFourPlainBasicTilesWithTheStarterSource() {
        let tiles = Starter.collection.compactMap { TileSet.byID[$0] }

        XCTAssertEqual(Starter.collection.count, 4)
        XCTAssertEqual(Set(Starter.collection).count, 4, "no duplicates")
        XCTAssertEqual(tiles.count, 4, "every id resolves")
        XCTAssertTrue(tiles.allSatisfy { $0.rarity == .basic && $0.element == nil && $0.source == .starter })
    }

    func testTutorialTile_isAFifthPlainBasicTileThatTheTutorialDrops() throws {
        let tile = try XCTUnwrap(TileSet.byID[Starter.tutorialTileID])

        XCTAssertFalse(Starter.collection.contains(tile.id))
        XCTAssertTrue(tile.rarity == .basic && tile.element == nil)
        XCTAssertEqual(tile.source, .campaign, "dropped by the tutorial node's reward order, not owned at the start")
    }

    /// The five starting profiles must feel different: no two share a sorted edge set (a
    /// rotation of a tile is the same profile), and they come in at least three shapes,
    /// counted as how many edges are 4 or more (0 is an even anchor, 1 a vanguard, 2 a flanker).
    func testStarterProfiles_allFiveDiffer() {
        let tiles = (Starter.collection + [Starter.tutorialTileID]).compactMap { TileSet.byID[$0] }

        XCTAssertEqual(tiles.count, 5)
        XCTAssertEqual(Set(tiles.map(sortedEdges)).count, 5, "two starter profiles are rotations of each other")
        XCTAssertGreaterThanOrEqual(Set(tiles.map { sortedEdges($0).filter { $0 >= 4 }.count }).count, 3, "at least three shapes")
    }

    /// Until the deck builder exists, the PvC hand is the deck a player has after the tutorial.
    func testStarterDeck_isTheFourStartersPlusTheTutorialTile() {
        XCTAssertEqual(Deck.starter.tileIDs, Starter.collection + [Starter.tutorialTileID])
        XCTAssertEqual(Deck.starter.tiles.count, Deck.size, "every id resolves")
    }

    func testStandardDeck_isFiveDistinctPlainCommons() {
        let tiles = Deck.standard.tiles

        XCTAssertEqual(Deck.standard.tileIDs.count, Deck.size)
        XCTAssertEqual(Set(Deck.standard.tileIDs).count, Deck.size)
        XCTAssertEqual(tiles.count, Deck.size, "every id resolves")
        XCTAssertTrue(tiles.allSatisfy { $0.rarity == .common && $0.element == nil }, "no elemental tile: the element does nothing on a clean board")
        XCTAssertEqual(Set(tiles.map(sortedEdges)).count, Deck.size, "five different profiles")
    }

    // MARK: - Opponent decks

    /// The design table: rarity mix and total edge sum per level. The sums come from
    /// the fixed per-tier sums, so they stay put if the tile set is regenerated.
    private let design: [Int: (mix: [Rarity: Int], total: Int)] = [
        1: ([.basic: 5], 48),
        2: ([.common: 4, .basic: 1], 59),
        3: ([.common: 5], 63),
        4: ([.uncommon: 3, .common: 2], 75),
        5: ([.rare: 3, .uncommon: 2], 95),
        6: ([.rare: 4, .epic: 1], 107),
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

    /// While every PvC board has elemental squares, an opponent deck needs elemental tiles
    /// of its own. The stage PR relaxes this for levels on clean and block-only boards.
    func testOpponentDecks_holdAtLeastTwoElementalTiles() {
        for level in 1...6 {
            XCTAssertGreaterThanOrEqual(OpponentDecks.deck(forLevel: level).tiles.filter { $0.element != nil }.count, 2, "level \(level)")
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
