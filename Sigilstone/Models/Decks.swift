//
//  Decks.swift
//  Sigilstone
//

import Foundation

extension TileSet {
    /// Every tile by its stable id.
    static let byID: [String: Tile] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}

/// Five tiles that become a player's hand in a match. Hands are always visible and
/// never drawn from a larger deck, so exact AI search stays possible.
struct Deck: Equatable {
    static let size = 5

    let tileIDs: [String]

    /// The tiles, in deck order. A test checks that every id in every shipped deck resolves.
    var tiles: [Tile] { tileIDs.compactMap { TileSet.byID[$0] } }

    /// A fresh hand for one match. Each call makes new stones, so build a hand once per
    /// game setup and refill from it on reset.
    func stones(owner: Int) -> [Stone] { tiles.map { $0.stone(owner: owner) } }
}

/// The AI opponent's deck for each level, as explicit tile ids. Explicit, not "the
/// first N of a tier", so regenerating the tile set cannot silently change a level (and
/// the tile-set fingerprint test fails if it does). Edge totals follow from the fixed
/// per-tier sums: 48, 59, 63, 75, 95, 107. Each deck holds at least 2 elemental tiles
/// while every PvC board has elemental squares. These per-level lists are interim: the
/// campaign PR replaces them with a reference to a representative node's deck.
enum OpponentDecks {
    /// The deck for level 1 to 6. Anything else gets level 1's deck, like the strategies.
    static func deck(forLevel level: Int) -> Deck {
        switch level {
        case 2: return Deck(tileIDs: ["common-water", "common-plain-3", "common-plain-1", "common-earth", "basic-fire"])
        case 3: return Deck(tileIDs: ["common-plain-1", "common-fire", "common-plain-7", "common-plain-8", "common-water"])
        case 4: return Deck(tileIDs: ["uncommon-air", "uncommon-plain-8", "common-water", "common-plain-8", "uncommon-plain-1"])
        case 5: return Deck(tileIDs: ["rare-plain-1", "rare-plain-2", "rare-water", "uncommon-plain-3", "uncommon-fire"])
        case 6: return Deck(tileIDs: ["rare-plain-6", "rare-plain-5", "rare-fire", "epic-earth", "rare-plain-3"])
        default: return Deck(tileIDs: ["basic-plain-1", "basic-plain-3", "basic-fire", "basic-water", "basic-plain-2"])
        }
    }
}
