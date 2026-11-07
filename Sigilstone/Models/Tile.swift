//
//  Tile.swift
//  Sigilstone
//

import Foundation

/// How rare a tile is, lowest tier first. Each tier has one fixed edge sum, so no tile
/// can strictly beat another in its own tier by construction; a higher tier beating a
/// lower one is the point of rarity. Keep these numbers in step with
/// scripts/generate_tiles.py; the tests fail if the shipped set drifts from them.
enum Rarity: String, CaseIterable {
    case basic, common, uncommon, rare, epic

    /// What the four edges of an elemental tile in this tier add up to.
    var edgeSum: Int {
        switch self {
        case .basic: return 3
        case .common: return 5
        case .uncommon: return 7
        case .rare: return 9
        case .epic: return 11
        }
    }
}

/// Where a tile comes from. Starter tiles are owned from the first launch, campaign
/// tiles are dropped by NPC nodes, and shop tiles can only be bought with gold, never
/// dropped.
enum TileSource: String {
    case starter, campaign, shop
}

/// A collectible tile: the fixed design a player owns and puts in a deck. In a match
/// it becomes a `Stone` (see `stone(owner:)`). The id is stable across launches, so a
/// collection can be saved as a set of ids.
struct Tile: Identifiable, Equatable {
    let id: String
    let top: Int
    let right: Int
    let bottom: Int
    let left: Int
    let element: Element?
    let rarity: Rarity
    let source: TileSource

    /// Every edge is 0 to 4. A tile has at least one nonzero edge, never four equal edges,
    /// and a 4 only in rare and epic tiles, at most one per tile (TileSetTests checks all
    /// of this). Keep it in step with scripts/generate_tiles.py.
    static let edgeRange = 0...4

    /// A plain tile breaks on every elemental square, so at equal edges an elemental
    /// tile is strictly better. Plain tiles get this much extra edge sum to compensate.
    static let plainBonus = 1

    /// A fresh piece for one match. Each call makes a new `Stone` (new `id`), and the
    /// stone remembers which tile it came from.
    func stone(owner: Int) -> Stone {
        Stone(top: top, right: right, bottom: bottom, left: left, owner: owner, element: element, tileID: id)
    }
}
