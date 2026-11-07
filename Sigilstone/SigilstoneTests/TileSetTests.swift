//
//  TileSetTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

/// A tile's edges as the smallest of their four rotations. Two tiles are the same design
/// exactly when their keys are equal: turning a tile a quarter turn does not make a new one,
/// but putting the same edges on different sides (adjacent against opposite) does.
func rotationKey(_ tile: Tile) -> [Int] {
    let e = [tile.top, tile.right, tile.bottom, tile.left]
    return (0..<4).map { shift in Array(e[shift...] + e[..<shift]) }.min { $0.lexicographicallyPrecedes($1) }!
}

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

    private func tile(_ e: [Int], _ element: Element?, rarity: Rarity = .common, source: TileSource = .campaign) -> Tile {
        Tile(id: "t", top: e[0], right: e[1], bottom: e[2], left: e[3], element: element, rarity: rarity, source: source)
    }

    private func tier(_ rarity: Rarity) -> [Tile] { TileSet.all.filter { $0.rarity == rarity } }

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

    /// Plain and elemental tiles per tier: mostly elementless, one tile per element.
    private let shape: [Rarity: (plain: Int, elemental: Int)] = [
        .basic: (5, 4), .common: (6, 4), .uncommon: (6, 4), .rare: (4, 4), .epic: (3, 4),
    ]

    func testRarity_runsFromBasicUpAndEachTierHasOneEdgeSum() {
        XCTAssertEqual(Rarity.allCases, [.basic, .common, .uncommon, .rare, .epic])
        XCTAssertEqual(Rarity.allCases.map(\.edgeSum), [3, 5, 7, 9, 11])
    }

    func testTileSet_hasFortyFourTilesInFiveTiers() {
        XCTAssertEqual(TileSet.all.count, 44)
        XCTAssertEqual(Set(TileSet.all.map(\.id)).count, 44, "ids are unique")
        XCTAssertEqual(TileSet.all.filter { $0.element == nil }.count, 24, "plain")
        XCTAssertEqual(TileSet.all.filter { $0.element != nil }.count, 20, "elemental")
        for rarity in Rarity.allCases {
            let expected = shape[rarity]!
            XCTAssertEqual(tier(rarity).count, expected.plain + expected.elemental, "\(rarity)")
            XCTAssertEqual(tier(rarity).filter { $0.element == nil }.count, expected.plain, "\(rarity) plain")
            for element in Element.allCases {
                XCTAssertEqual(tier(rarity).filter { $0.element == element }.count, 1, "\(rarity) \(element)")
            }
        }
    }

    func testTileSet_followsTheBudget() {
        for tile in TileSet.all {
            XCTAssertTrue(edges(tile).allSatisfy { Tile.edgeRange.contains($0) }, "\(tile.id) edges")
            let expected = tile.rarity.edgeSum + (tile.element == nil ? Tile.plainBonus : 0)
            XCTAssertEqual(edges(tile).reduce(0, +), expected, "\(tile.id) edge sum")
        }
    }

    /// The owner's rule: every edge is 0 to 4, at least one is above 0, no tile has four
    /// equal edges, and a 4 appears only in rare and epic tiles, at most once per tile.
    func testTileSet_followsTheEdgeRules() {
        XCTAssertEqual(Tile.edgeRange, 0...4)
        for tile in TileSet.all {
            let e = edges(tile)
            XCTAssertTrue(e.allSatisfy { Tile.edgeRange.contains($0) }, "\(tile.id) edge outside 0 to 4")
            XCTAssertGreaterThan(e.max()!, 0, "\(tile.id) has no nonzero edge")
            XCTAssertGreaterThan(Set(e).count, 1, "\(tile.id) has four equal edges")
            let fours = e.filter { $0 == 4 }.count
            XCTAssertLessThanOrEqual(fours, 1, "\(tile.id) has more than one 4")
            if tile.rarity != .rare && tile.rarity != .epic {
                XCTAssertEqual(fours, 0, "\(tile.id) has a 4 below rare")
            }
        }
    }

    func testTileSet_noTileDominatesAnotherInItsTier() {
        var pairsChecked = 0
        for rarity in Rarity.allCases {
            for a in tier(rarity) {
                for b in tier(rarity) where a.id != b.id {
                    pairsChecked += 1
                    XCTAssertFalse(dominates(a, b), "\(a.id) dominates \(b.id)")
                }
            }
        }
        XCTAssertEqual(pairsChecked, 9 * 8 + 10 * 9 + 10 * 9 + 8 * 7 + 7 * 6, "every ordered pair in every tier")
    }

    func testTileSet_tilesInATierAreVaried() {
        for rarity in Rarity.allCases {
            let designs = Set(tier(rarity).map(rotationKey))
            XCTAssertEqual(designs.count, tier(rarity).count, "\(rarity): two tiles are rotations of each other")
        }
    }

    func testRotationKey_ignoresTurnsButNotArrangement() {
        XCTAssertEqual(rotationKey(tile([2, 0, 0, 2], nil)), rotationKey(tile([2, 2, 0, 0], nil)), "adjacent pairs are rotations of each other")
        XCTAssertNotEqual(rotationKey(tile([2, 0, 2, 0], nil)), rotationKey(tile([2, 2, 0, 0], nil)), "opposite against adjacent differ")
    }

    // MARK: - Sources

    func testSources_followTheRules() {
        for tile in TileSet.all {
            let isStarter = tile.rarity == .basic && tile.element == nil && Starter.collection.contains(tile.id)
            let isShop = (tile.rarity == .rare || tile.rarity == .epic) && tile.element != nil
            let expected: TileSource = isStarter ? .starter : (isShop ? .shop : .campaign)
            XCTAssertEqual(tile.source, expected, tile.id)
        }
    }

    func testSources_countsAre4Starter8Shop32Campaign() {
        XCTAssertEqual(TileSet.all.filter { $0.source == .starter }.count, 4)
        XCTAssertEqual(TileSet.all.filter { $0.source == .shop }.count, 8)
        XCTAssertEqual(TileSet.all.filter { $0.source == .campaign }.count, 32)
        XCTAssertTrue(TileSet.all.filter { $0.source == .shop }.allSatisfy { $0.element != nil }, "the shop sells elemental tiles")
    }

    // MARK: - Fingerprint

    /// Pins every shipped tile: id, edges (top right bottom left), element, rarity, source.
    /// If this fails after regenerating the set, the tiles changed. That needs the owner's
    /// approval and a rerun of the level checks (LevelStrengthTests now, the winnability
    /// check later) before the expected list below is updated.
    func testFingerprint_pinsTheShippedTiles() {
        let shipped = TileSet.all.map { "\($0.id) \(edges($0).map(String.init).joined(separator: "/")) \($0.element?.rawValue ?? "plain") \($0.rarity) \($0.source)" }
        XCTAssertEqual(shipped, Self.expectedFingerprint)
    }

    static let expectedFingerprint: [String] = [
        "basic-fire 0/0/2/1 fire basic campaign",
        "basic-water 0/1/1/1 water basic campaign",
        "basic-earth 0/0/3/0 earth basic campaign",
        "basic-air 0/1/2/0 air basic campaign",
        "basic-plain-1 2/0/0/2 plain basic starter",
        "basic-plain-2 0/2/0/2 plain basic starter",
        "basic-plain-3 0/1/2/1 plain basic starter",
        "basic-plain-4 3/1/0/0 plain basic starter",
        "basic-plain-5 0/3/0/1 plain basic campaign",
        "common-fire 1/0/1/3 fire common campaign",
        "common-water 0/3/0/2 water common campaign",
        "common-earth 0/1/2/2 earth common campaign",
        "common-air 1/3/0/1 air common campaign",
        "common-plain-1 1/2/1/2 plain common campaign",
        "common-plain-2 3/0/1/2 plain common campaign",
        "common-plain-3 3/1/0/2 plain common campaign",
        "common-plain-4 0/3/3/0 plain common campaign",
        "common-plain-5 0/3/2/1 plain common campaign",
        "common-plain-6 2/0/2/2 plain common campaign",
        "uncommon-fire 1/3/0/3 fire uncommon campaign",
        "uncommon-water 2/2/1/2 water uncommon campaign",
        "uncommon-earth 1/3/2/1 earth uncommon campaign",
        "uncommon-air 1/3/3/0 air uncommon campaign",
        "uncommon-plain-1 2/1/2/3 plain uncommon campaign",
        "uncommon-plain-2 2/3/3/0 plain uncommon campaign",
        "uncommon-plain-3 2/2/3/1 plain uncommon campaign",
        "uncommon-plain-4 3/2/2/1 plain uncommon campaign",
        "uncommon-plain-5 1/3/1/3 plain uncommon campaign",
        "uncommon-plain-6 1/3/3/1 plain uncommon campaign",
        "rare-fire 4/3/2/0 fire rare shop",
        "rare-water 1/4/1/3 water rare shop",
        "rare-earth 0/2/4/3 earth rare shop",
        "rare-air 0/4/2/3 air rare shop",
        "rare-plain-1 2/4/1/3 plain rare campaign",
        "rare-plain-2 2/2/4/2 plain rare campaign",
        "rare-plain-3 3/4/3/0 plain rare campaign",
        "rare-plain-4 3/4/2/1 plain rare campaign",
        "epic-fire 2/3/4/2 fire epic shop",
        "epic-water 2/2/4/3 water epic shop",
        "epic-earth 3/3/3/2 earth epic shop",
        "epic-air 3/4/3/1 air epic shop",
        "epic-plain-1 2/3/3/4 plain epic campaign",
        "epic-plain-2 2/4/3/3 plain epic campaign",
        "epic-plain-3 4/3/2/3 plain epic campaign",
    ]

    // MARK: - Tile to Stone

    func testStone_carriesTheTilesEdgesElementAndStableID() {
        let tile = Tile(id: "rare-fire", top: 5, right: 6, bottom: 4, left: 5, element: .fire, rarity: .rare, source: .shop)

        let stone = tile.stone(owner: 2)

        XCTAssertEqual([stone.top, stone.right, stone.bottom, stone.left], [5, 6, 4, 5])
        XCTAssertEqual(stone.element, .fire)
        XCTAssertEqual(stone.owner, 2)
        XCTAssertEqual(stone.tileID, "rare-fire")
        XCTAssertNotEqual(tile.stone(owner: 2).id, stone.id, "each Stone is its own piece in play")
    }

    func testStone_withoutATileHasNoTileID() {
        XCTAssertNil(Stone(top: 1, right: 2, bottom: 3, left: 4, owner: 1).tileID)
    }
}
