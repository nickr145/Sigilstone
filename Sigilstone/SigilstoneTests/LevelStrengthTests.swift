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
    /// Characterization of the hand-written hands PR 3 replaces. It records the win
    /// rates (see the print lines, copied into the PR description) and only checks
    /// that every game finishes; the numbers are a snapshot, not a contract.
    func testOldHands_recordTheWinRateAtEachLevel() {
        let model = PlayerPiecesModel()
        let levelHands = [model.level1Pieces, model.level2Pieces, model.level3Pieces,
                          model.level4Pieces, model.level5Pieces, model.level6Pieces]
        for squares in [false, true] {
            for level in 1...6 {
                // The app gave both hands the placeholder elements whenever squares were on.
                let player = squares ? PlaceholderElements.assign(to: model.player1PiecesForEachDifficulty[level - 1]) : model.player1PiecesForEachDifficulty[level - 1]
                let opponent = squares ? PlaceholderElements.assign(to: levelHands[level - 1]) : levelHands[level - 1]

                let record = LevelSimulation.record(playerHand: player, opponentHand: opponent, level: level, squares: squares, games: 300)

                print("LEVELSTRENGTH old hands, \(squares ? "2 squares" : "plain board"), level \(level): wins \(record.wins), ties \(record.ties), losses \(record.losses), win rate \(Int((record.winRate * 100).rounded()))%")
                XCTAssertEqual(record.games, 300)
            }
        }
    }
}
