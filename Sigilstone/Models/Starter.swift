//
//  Starter.swift
//  Sigilstone
//

import Foundation

/// What a new player owns: four plain basic tiles with four different profiles (a
/// vanguard, a flanker, an anchor and a shield). The tutorial's reward is a fifth plain
/// basic tile with another profile, which completes the starting deck. Held in code until
/// the player profile exists; it becomes that profile's starting values.
enum Starter {
    static let collection: [String] = ["basic-plain-1", "basic-plain-2", "basic-plain-3", "basic-plain-4"]

    /// The tile the tutorial node drops. Not owned at the start.
    static let tutorialTileID = "basic-plain-5"
}

extension Deck {
    /// The deck a player has after the tutorial: the four starters plus the tutorial tile.
    /// Until the deck builder exists this is the default PvC hand.
    static let starter = Deck(tileIDs: Starter.collection + [Starter.tutorialTileID])

    /// PvP is separate from progression: both players use the same standard deck of five
    /// plain commons. The board is plain in PvP, where an element does nothing, so the
    /// deck has no elemental tile.
    static let standard = Deck(tileIDs: ["common-plain-1", "common-plain-2", "common-plain-3", "common-plain-4", "common-plain-5"])
}
