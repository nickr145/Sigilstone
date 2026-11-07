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
        .basic: (6, 4), .common: (8, 4), .uncommon: (8, 4), .rare: (6, 4), .epic: (4, 4),
    ]

    func testRarity_runsFromBasicUpAndEachTierHasOneEdgeSum() {
        XCTAssertEqual(Rarity.allCases, [.basic, .common, .uncommon, .rare, .epic])
        XCTAssertEqual(Rarity.allCases.map(\.edgeSum), [9, 12, 16, 20, 24])
    }

    func testTileSet_hasFiftyTwoTilesInFiveTiers() {
        XCTAssertEqual(TileSet.all.count, 52)
        XCTAssertEqual(Set(TileSet.all.map(\.id)).count, 52, "ids are unique")
        XCTAssertEqual(TileSet.all.filter { $0.element == nil }.count, 32, "plain")
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

    func testTileSet_noTileIsTooLopsided() {
        for tile in TileSet.all {
            let spread = edges(tile).max()! - edges(tile).min()!
            XCTAssertLessThanOrEqual(spread, Tile.maxEdgeSpread, "\(tile.id) spread")
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
        XCTAssertEqual(pairsChecked, 10 * 9 + 12 * 11 + 12 * 11 + 10 * 9 + 8 * 7, "every ordered pair in every tier")
    }

    func testTileSet_tilesInATierAreVaried() {
        for rarity in Rarity.allCases {
            let shapes = Set(tier(rarity).map { edges($0).sorted() })
            XCTAssertEqual(shapes.count, tier(rarity).count, "\(rarity): two tiles are rotations of each other")
        }
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

    func testSources_countsAre4Starter8Shop40Campaign() {
        XCTAssertEqual(TileSet.all.filter { $0.source == .starter }.count, 4)
        XCTAssertEqual(TileSet.all.filter { $0.source == .shop }.count, 8)
        XCTAssertEqual(TileSet.all.filter { $0.source == .campaign }.count, 40)
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
        "basic-fire 1/1/6/1 fire basic campaign",
        "basic-water 1/3/1/4 water basic campaign",
        "basic-earth 1/5/1/2 earth basic campaign",
        "basic-air 1/4/2/2 air basic campaign",
        "basic-plain-1 6/2/1/1 plain basic starter",
        "basic-plain-2 1/4/1/4 plain basic starter",
        "basic-plain-3 3/3/2/2 plain basic starter",
        "basic-plain-4 3/3/3/1 plain basic starter",
        "basic-plain-5 2/5/2/1 plain basic campaign",
        "basic-plain-6 1/5/1/3 plain basic campaign",
        "common-fire 1/7/2/2 fire common campaign",
        "common-water 1/3/5/3 water common campaign",
        "common-earth 3/2/6/1 earth common campaign",
        "common-air 2/3/3/4 air common campaign",
        "common-plain-1 5/1/2/5 plain common campaign",
        "common-plain-2 5/1/4/3 plain common campaign",
        "common-plain-3 2/1/4/6 plain common campaign",
        "common-plain-4 2/1/3/7 plain common campaign",
        "common-plain-5 3/6/3/1 plain common campaign",
        "common-plain-6 2/4/2/5 plain common campaign",
        "common-plain-7 3/5/3/2 plain common campaign",
        "common-plain-8 4/3/4/2 plain common campaign",
        "uncommon-fire 4/3/7/2 fire uncommon campaign",
        "uncommon-water 2/5/3/6 water uncommon campaign",
        "uncommon-earth 3/6/3/4 earth uncommon campaign",
        "uncommon-air 4/1/4/7 air uncommon campaign",
        "uncommon-plain-1 7/2/6/2 plain uncommon campaign",
        "uncommon-plain-2 6/3/2/6 plain uncommon campaign",
        "uncommon-plain-3 7/3/4/3 plain uncommon campaign",
        "uncommon-plain-4 4/1/6/6 plain uncommon campaign",
        "uncommon-plain-5 4/8/2/3 plain uncommon campaign",
        "uncommon-plain-6 3/4/5/5 plain uncommon campaign",
        "uncommon-plain-7 3/7/1/6 plain uncommon campaign",
        "uncommon-plain-8 7/2/1/7 plain uncommon campaign",
        "rare-fire 3/7/2/8 fire rare shop",
        "rare-water 2/4/6/8 water rare shop",
        "rare-earth 2/7/7/4 earth rare shop",
        "rare-air 4/7/3/6 air rare shop",
        "rare-plain-1 5/3/6/7 plain rare campaign",
        "rare-plain-2 5/8/6/2 plain rare campaign",
        "rare-plain-3 5/9/4/3 plain rare campaign",
        "rare-plain-4 4/5/5/7 plain rare campaign",
        "rare-plain-5 3/6/4/8 plain rare campaign",
        "rare-plain-6 6/6/5/4 plain rare campaign",
        "epic-fire 5/8/4/7 fire epic shop",
        "epic-water 3/5/8/8 water epic shop",
        "epic-earth 3/8/6/7 earth epic shop",
        "epic-air 7/5/6/6 air epic shop",
        "epic-plain-1 4/6/9/6 plain epic campaign",
        "epic-plain-2 9/6/5/5 plain epic campaign",
        "epic-plain-3 9/5/8/3 plain epic campaign",
        "epic-plain-4 5/6/8/6 plain epic campaign",
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
