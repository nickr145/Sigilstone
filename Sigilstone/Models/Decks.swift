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
/// first N of a tier", so regenerating the tile set cannot silently change a level.
/// Edge totals follow from the fixed per-tier sums: 60, 60, 68, 76, 88, 104. Levels 1 and 2
/// both hold five commons, so which five is the only lever between them: level 1 holds a
/// weak-fitting five and level 2 a strong-fitting five (checked by the ladder test).
enum OpponentDecks {
    /// The deck for level 1 to 6. Anything else gets level 1's deck, like the strategies.
    static func deck(forLevel level: Int) -> Deck {
        switch level {
        case 2: return Deck(tileIDs: ["common-fire-1", "common-fire-2", "common-water-2", "common-earth-2", "common-air-1"])
        case 3: return Deck(tileIDs: ["common-fire-1", "common-water-1", "common-earth-2", "uncommon-air-1", "uncommon-fire-1"])
        case 4: return Deck(tileIDs: ["common-air-2", "uncommon-fire-1", "uncommon-water-1", "uncommon-earth-1", "uncommon-air-2"])
        case 5: return Deck(tileIDs: ["uncommon-fire-2", "uncommon-water-2", "uncommon-earth-2", "rare-air-1", "rare-fire-1"])
        case 6: return Deck(tileIDs: ["rare-fire-2", "rare-water-1", "rare-earth-1", "rare-air-2", "epic-water-2"])
        default: return Deck(tileIDs: ["common-fire-1", "common-fire-2", "common-water-1", "common-earth-1", "common-air-2"])
        }
    }
}
