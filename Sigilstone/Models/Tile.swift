//
//  Tile.swift
//  Sigilstone
//

import Foundation

/// How rare a tile is. Each tier has one fixed edge sum, so no tile can strictly beat
/// another in its own tier by construction; a higher tier beating a lower one is the
/// point of rarity. Keep these numbers in step with scripts/generate_tiles.py; the
/// tests fail if the shipped set drifts from them.
enum Rarity: String, CaseIterable {
    case common, uncommon, rare, epic

    /// What the four edges of an elemental tile in this tier add up to.
    var edgeSum: Int {
        switch self {
        case .common: return 12
        case .uncommon: return 16
        case .rare: return 20
        case .epic: return 24
        }
    }
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

    /// Every edge value is a single digit so it fits on the stone.
    static let edgeRange = 1...9

    /// The highest edge minus the lowest may not exceed this, so no tile is a spike
    /// like 1/9/1/1. Keep it in step with MAX_SPREAD in scripts/generate_tiles.py.
    static let maxEdgeSpread = 6

    /// A plain tile breaks on every elemental square, so at equal edges an elemental
    /// tile is strictly better. Plain tiles get this much extra edge sum to compensate.
    static let plainBonus = 1

    /// A fresh piece for one match. Each call makes a new `Stone` (new `id`), and the
    /// stone remembers which tile it came from.
    func stone(owner: Int) -> Stone {
        Stone(top: top, right: right, bottom: bottom, left: left, owner: owner, element: element, tileID: id)
    }
}
