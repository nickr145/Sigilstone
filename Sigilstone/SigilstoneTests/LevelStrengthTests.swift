//
//  LevelStrengthTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

/// How a fixed reference player (player 1, the look-ahead strategy) fares against
/// the AI for a level, over seeded games where the computer moves first.
struct LevelRecord {
    var wins = 0
    var ties = 0
    var losses = 0
    var games: Int { wins + ties + losses }
    var winRate: Double { games == 0 ? 0 : Double(wins) / Double(games) }
}

enum LevelSimulation {
    /// Plays `games` seeded games. Game `n` uses the same square layout whatever the
    /// level, so levels are compared on identical boards. With `squares`, each game
    /// gets 1 or 2 elemental squares, like the app.
    static func record(playerHand: [Stone], opponentHand: [Stone], level: Int, squares: Bool, games: Int, seed: UInt64 = 2026) -> LevelRecord {
        var record = LevelRecord()
        let opponent = AIStrategies.strategy(forlevel: level)
        let reference = LookAheadStrategy()
        for game in 0..<games {
            var layoutRng = SeededGenerator(seed: seed &+ UInt64(game))
            var state = GameState(player1Hand: playerHand, player2Hand: opponentHand, startingPlayer: 2)
            if squares {
                let count = Int.random(in: 1...2, using: &layoutRng)
                state.cellElements = BoardGenerator.elementalSquares(count: count, using: &layoutRng)
            }
            var rng = SeededGenerator(seed: seed &+ 1_000_000 &+ UInt64(game))
            while !state.isOver {
                let strategy: any AIStrategy = state.currentPlayer == 1 ? reference : opponent
                guard let move = strategy.chooseMove(in: state, using: &rng) else { break }
                state = GameRules.apply(move, to: state)
            }
            if let winner = state.winner {
                if winner == 1 { record.wins += 1 } else { record.losses += 1 }
            } else {
                record.ties += 1
            }
        }
        return record
    }
}

final class LevelStrengthTests: XCTestCase {
    /// The difficulty ladder. The reference player (look-ahead, player 1) holds the
    /// starter deck at EVERY level and plays 2-square boards with the computer moving
    /// first; the opponent holds that level's deck. A level may be no easier than the
    /// one before it, but levels may tie: with the starter deck, levels 5 and 6 can
    /// both be near zero. The same seeded layouts are used at every level.
    func testLadder_winRateNeverIncreasesAsTheLevelRises() {
        let player = Deck.starter.stones(owner: 1)
        var rates: [Double] = []
        for level in 1...6 {
            let opponent = OpponentDecks.deck(forLevel: level).stones(owner: 2)

            let record = LevelSimulation.record(playerHand: player, opponentHand: opponent, level: level, squares: true, games: 300)

            print("LEVELSTRENGTH new decks (starter deck vs level deck), 2 squares, level \(level): wins \(record.wins), ties \(record.ties), losses \(record.losses), win rate \(Int((record.winRate * 100).rounded()))%")
            XCTAssertEqual(record.games, 300)
            rates.append(record.winRate)
        }
        for level in 1..<6 {
            XCTAssertLessThanOrEqual(rates[level], rates[level - 1], "level \(level + 1) is easier than level \(level)")
        }
    }
}
