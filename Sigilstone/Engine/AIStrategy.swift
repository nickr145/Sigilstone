//
//  AIStrategy.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-10-31.
//

import Foundation

/// Decides which move the player to move makes. Pure: it reads a GameState and
/// returns a Move, and never changes anything. All randomness comes from
/// `generator`, so tests can replay a game with a seeded one.

protocol AIStrategy {
    func chooseMove<G: RandomNumberGenerator>(in state: GameState, using generator: inout G) -> Move?
}

enum AIStrategies {
    /// The strategy for difficulty `level`, 1 to 6. Anything else plays like level 1.
    static func strategy(forlevel level: Int) -> any AIStrategy {
        switch level {
        case 2: return CornerStrategy()
        case 3, 4: return CaptureFirstStrategy()
        case 5: return GreedyCaptureStrategy()
        case 6: return LookAheadStrategy()
        default: return RandomStrategy()
        }
    }
}
