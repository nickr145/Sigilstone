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
/// per-tier sums: 17, 25, 28, 32, 43, 48. Each deck holds at least 2 elemental tiles
/// while every PvC board has elemental squares. The decks were picked by a throwaway
/// search against the standard deck (win rate near the old ladder, at least 2 captures
/// a game). These per-level lists are interim: the campaign PR replaces them with a
/// reference to a representative node's deck.
enum OpponentDecks {
    /// The deck for level 1 to 6. Anything else gets level 1's deck, like the strategies.
    static func deck(forLevel level: Int) -> Deck {
        switch level {
        case 2: return Deck(tileIDs: ["basic-air", "common-air", "common-fire", "common-plain-3", "common-plain-4"])
        case 3: return Deck(tileIDs: ["common-fire", "common-plain-1", "common-plain-3", "common-plain-6", "common-water"])
        case 4: return Deck(tileIDs: ["common-fire", "common-water", "uncommon-fire", "uncommon-plain-3", "uncommon-water"])
        case 5: return Deck(tileIDs: ["rare-earth", "rare-fire", "rare-plain-2", "uncommon-plain-6", "uncommon-water"])
        case 6: return Deck(tileIDs: ["epic-plain-1", "rare-air", "rare-earth", "rare-fire", "rare-water"])
        default: return Deck(tileIDs: ["basic-air", "basic-fire", "basic-plain-1", "basic-plain-4", "basic-water"])
        }
    }
}
