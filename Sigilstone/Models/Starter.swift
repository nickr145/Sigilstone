//
//  Starter.swift
//  Sigilstone
//

import Foundation

/// What a new player owns: the 8 elemental commons, 2 per element. Held in code until
/// the player profile exists; it becomes that profile's starting values.
enum Starter {
    static let collection: [String] = [
        "common-fire-1", "common-fire-2",
        "common-water-1", "common-water-2",
        "common-earth-1", "common-earth-2",
        "common-air-1", "common-air-2",
    ]
}

extension Deck {
    /// The default deck: five owned commons that cover all four elements.
    static let starter = Deck(tileIDs: ["common-fire-1", "common-water-1", "common-earth-1", "common-air-1", "common-fire-2"])

    /// PvP is separate from progression: both players use the same standard deck.
    static let standard = starter
}
