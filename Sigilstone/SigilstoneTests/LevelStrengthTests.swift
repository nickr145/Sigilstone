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
    /// Stones flipped, and stones broken into blocks, summed over all games.
    var captures = 0
    var breaks = 0
    var games: Int { wins + ties + losses }
    var capturesPerGame: Double { games == 0 ? 0 : Double(captures) / Double(games) }
    var breaksPerGame: Double { games == 0 ? 0 : Double(breaks) / Double(games) }
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
                record.captures += GameRules.capturedCells(by: move, in: state).count
                if GameRules.breaks(move, in: state) { record.breaks += 1 }
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
    /// standard deck (five plain commons, the same deck PvP uses) at EVERY level and
    /// plays 2-square boards with the computer moving first; the opponent holds that
    /// level's deck. The win rate should fall as the level rises, but each rate comes
    /// from 300 games and carries about 2 points of standard error, so a rate may rise
    /// by up to `tolerance` between adjacent levels before the test fails. Levels may
    /// also tie: the top levels can both be near zero. The same seeded layouts are used
    /// at every level.
    func testLadder_winRateDoesNotRiseAsTheLevelRisesBeyondTheTolerance() {
        let tolerance = 0.05
        let records = ladder(player: Deck.standard, label: "standard deck")
        let rates = records.map(\.winRate)
        for level in 1..<6 {
            XCTAssertLessThanOrEqual(rates[level], rates[level - 1] + tolerance, "level \(level + 1) is easier than level \(level) by more than the tolerance")
        }
        // With edges 0 to 4 many facing edges tie and nothing flips. The standard deck must
        // still flip at least `floor` stones per game at every level, so games stay lively.
        // Only the standard deck is asserted; the starter deck's numbers are printed.
        let floor = 2.0
        for (index, record) in records.enumerated() {
            XCTAssertGreaterThanOrEqual(record.capturesPerGame, floor, "level \(index + 1) averages too few captures per game")
        }
    }

    /// For the record only: the same ladder for the deck a player holds after the
    /// tutorial. It is not asserted; the five starter tiles are meant to be outclassed
    /// from the middle levels on until the player collects more.
    func testLadder_starterDeckRatesArePrinted() {
        XCTAssertEqual(ladder(player: Deck.starter, label: "starter deck").count, 6)
    }

    private func ladder(player deck: Deck, label: String) -> [LevelRecord] {
        let player = deck.stones(owner: 1)
        var records: [LevelRecord] = []
        for level in 1...6 {
            let opponent = OpponentDecks.deck(forLevel: level).stones(owner: 2)

            let record = LevelSimulation.record(playerHand: player, opponentHand: opponent, level: level, squares: true, games: 300)

            print("LEVELSTRENGTH v2 (\(label) vs level deck), 2 squares, level \(level): wins \(record.wins), ties \(record.ties), losses \(record.losses), win rate \(Int((record.winRate * 100).rounded()))%, captures per game \(String(format: "%.2f", record.capturesPerGame)), breaks per game \(String(format: "%.2f", record.breaksPerGame))")
            XCTAssertEqual(record.games, 300)
            records.append(record)
        }
        return records
    }
}
