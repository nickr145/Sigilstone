//
//  TileSetTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

final class TileSetTests: XCTestCase {

    private func edges(_ tile: Tile) -> [Int] { [tile.top, tile.right, tile.bottom, tile.left] }

    /// A dominates B when it is at least as good on every edge, better on one, and
    /// is at least as safe on elemental squares: B has no element (so it breaks on
    /// every square A could), or both share an element.
    private func dominates(_ a: Tile, _ b: Tile) -> Bool {
        let pairs = Array(zip(edges(a), edges(b)))
        let atLeastAsGood = pairs.allSatisfy { $0 >= $1 }
        let better = pairs.contains { $0 > $1 }
        return atLeastAsGood && better && (b.element == nil || a.element == b.element)
    }

    private func tile(_ e: [Int], _ element: Element?, rarity: Rarity = .common) -> Tile {
        Tile(id: "t", top: e[0], right: e[1], bottom: e[2], left: e[3], element: element, rarity: rarity)
    }

    // MARK: - The dominance check itself (so the set test below can't pass vacuously)

    func testDominates_needsEveryEdgeAtLeastAsGoodAndOneBetter() {
        XCTAssertTrue(dominates(tile([3, 3, 3, 3], nil), tile([3, 3, 3, 2], nil)))
        XCTAssertFalse(dominates(tile([3, 3, 3, 3], nil), tile([3, 3, 3, 3], nil)), "equal tiles don't dominate")
        XCTAssertFalse(dominates(tile([4, 3, 3, 2], nil), tile([3, 3, 3, 3], nil)), "worse on one edge")
    }

    func testDominates_isElementAware() {
        let plainStrong = tile([4, 4, 4, 4], nil)
        let fireWeak = tile([3, 3, 3, 3], .fire)
        XCTAssertFalse(dominates(plainStrong, fireWeak), "a plain tile breaks on squares the fire tile survives")
        XCTAssertTrue(dominates(tile([4, 4, 4, 4], .fire), fireWeak), "same element")
        XCTAssertFalse(dominates(tile([4, 4, 4, 4], .water), fireWeak), "different elements")
        XCTAssertTrue(dominates(tile([4, 4, 4, 4], .water), tile([3, 3, 3, 3], nil)), "the other tile is plain")
    }

    // MARK: - The shipped set

    func testTileSet_hasFourTiersOfNineTiles() {
        XCTAssertEqual(TileSet.all.count, 36)
        XCTAssertEqual(Set(TileSet.all.map(\.id)).count, 36, "ids are unique")
        for rarity in Rarity.allCases {
            let tier = TileSet.all.filter { $0.rarity == rarity }
            XCTAssertEqual(tier.count, 9, "\(rarity)")
            for element in Element.allCases {
                XCTAssertEqual(tier.filter { $0.element == element }.count, 2, "\(rarity) \(element)")
            }
            XCTAssertEqual(tier.filter { $0.element == nil }.count, 1, "\(rarity) plain")
        }
    }

    func testTileSet_followsTheBudget() {
        for tile in TileSet.all {
            XCTAssertTrue(edges(tile).allSatisfy { Tile.edgeRange.contains($0) }, "\(tile.id) edges")
            let expected = tile.rarity.edgeSum + (tile.element == nil ? Tile.plainBonus : 0)
            XCTAssertEqual(edges(tile).reduce(0, +), expected, "\(tile.id) edge sum")
        }
    }

    func testTileSet_noTileDominatesAnotherInItsTier() {
        for rarity in Rarity.allCases {
            let tier = TileSet.all.filter { $0.rarity == rarity }
            for a in tier {
                for b in tier where a.id != b.id {
                    XCTAssertFalse(dominates(a, b), "\(a.id) dominates \(b.id)")
                }
            }
        }
    }

    func testTileSet_tilesInATierAreVaried() {
        for rarity in Rarity.allCases {
            let tier = TileSet.all.filter { $0.rarity == rarity }
            let shapes = Set(tier.map { edges($0).sorted() })
            XCTAssertEqual(shapes.count, tier.count, "\(rarity): two tiles are rotations of each other")
        }
    }

    // MARK: - Tile to Stone

    func testStone_carriesTheTilesEdgesElementAndStableID() {
        let tile = Tile(id: "rare-fire-1", top: 5, right: 6, bottom: 4, left: 5, element: .fire, rarity: .rare)

        let stone = tile.stone(owner: 2)

        XCTAssertEqual([stone.top, stone.right, stone.bottom, stone.left], [5, 6, 4, 5])
        XCTAssertEqual(stone.element, .fire)
        XCTAssertEqual(stone.owner, 2)
        XCTAssertEqual(stone.tileID, "rare-fire-1")
        XCTAssertNotEqual(tile.stone(owner: 2).id, stone.id, "each Stone is its own piece in play")
    }

    func testStone_withoutATileHasNoTileID() {
        XCTAssertNil(Stone(top: 1, right: 2, bottom: 3, left: 4, owner: 1).tileID)
    }
}
