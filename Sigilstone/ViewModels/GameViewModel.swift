//
//  GameViewModel.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-20.
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var difficultyImageStrings = GameStringConstants.difficultyImageStrings
    @Published var difficultyLevelNameStrings = GameStringConstants.difficultyLevelNameStrings
    @Published var musicDifficultyStrings = GameStringConstants.musicDifficultyStrings
    @Published var piecesModel = PlayerPiecesModel()
    
    @Published var board: [Stone?] = Array(repeating: nil, count: 9)
    @Published var player1Pieces: [Stone]
    @Published var player2Pieces: [Stone]
    @Published var selectedPiece: Stone?
    @Published var currentPlayer: Int
    @Published var isGameOver: Bool = false
    @Published var winner: Int?
    @Published var player1Score: Int = 0
    @Published var player2Score: Int = 0
    @Published var isAITurnPending: Bool = false

    /// Single source of truth for who moves first, shared by init and resetGame() so the two can never drift out of sync again.
    private let startingPlayer = 2

    private var level1Pieces: [Stone]
    private var level2Pieces: [Stone]
    private var level3Pieces: [Stone]
    private var level4Pieces: [Stone]
    private var level5Pieces: [Stone]
    private var level6Pieces: [Stone]

    private var player1PiecesForEachDifficulty: [[Stone]]

    private let persistence: PersistenceStore
    private let analytics: AnalyticsService

    init(persistence: PersistenceStore = UserDefaultsPersistenceStore(), analytics: AnalyticsService = ConsoleAnalyticsService()) {
        let piecesModel = PlayerPiecesModel()
        self.player1Pieces = piecesModel.player1Pieces
        self.player2Pieces = piecesModel.player2Pieces
        self.level1Pieces = piecesModel.level1Pieces
        self.level2Pieces = piecesModel.level2Pieces
        self.level3Pieces = piecesModel.level3Pieces
        self.level4Pieces = piecesModel.level4Pieces
        self.level5Pieces = piecesModel.level5Pieces
        self.level6Pieces = piecesModel.level6Pieces
        self.player1PiecesForEachDifficulty = piecesModel.player1PiecesForEachDifficulty
        self.currentPlayer = startingPlayer
        self.persistence = persistence
        self.analytics = analytics
    }
    
    var selectedDifficulty: Int = 1
    
    /// Bridge to the engine until GameState becomes the stored property (step 7):
    /// reads the published fields into a GameState, and writes a new one back.
    private var gameState: GameState {
        get {
            GameState(board: board, player1Hand: player1Pieces, player2Hand: player2Pieces, currentPlayer: currentPlayer)
        }
        set {
            board = newValue.board
            player1Pieces = newValue.player1Hand
            player2Pieces = newValue.player2Hand
            currentPlayer = newValue.currentPlayer
        }
    }
    
    
    func updateScores() {
        player1Score = Scoring.score(for: 1, on: board)
        player2Score = Scoring.score(for: 2, on: board)
    }
    
    /// Difficulty is always 1-6 in practice (the picker that drives it only offers
    /// those values), but Int isn't exhaustively switchable, so `default` falls
    /// back to level 1 rather than being duplicated across every caller.
    private func pieces(forDifficulty level: Int) -> (computer: [Stone], player1: [Stone]) {
        switch level {
        case 1: return (level1Pieces, player1PiecesForEachDifficulty[0])
        case 2: return (level2Pieces, player1PiecesForEachDifficulty[1])
        case 3: return (level3Pieces, player1PiecesForEachDifficulty[2])
        case 4: return (level4Pieces, player1PiecesForEachDifficulty[3])
        case 5: return (level5Pieces, player1PiecesForEachDifficulty[4])
        case 6: return (level6Pieces, player1PiecesForEachDifficulty[5])
        default: return (level1Pieces, player1PiecesForEachDifficulty[0])
        }
    }

    func setupComputerDifficulty(_ level: Int) {
        selectedDifficulty = level
        analytics.track(event: "game_started", properties: ["mode": "pvc", "difficulty": level])
        (player2Pieces, player1Pieces) = pieces(forDifficulty: level)
    }
    
    func recordDifficultySelection(_ level: Int) {
        persistence.save(GamePreferences(preferredDifficulty: level))
        analytics.track(event: "difficulty_selected", properties: ["level": level])
    }
    
    /// Asks the strategy for the current difficulty for a move, then plays it.
    func performComputerMove() {
        guard currentPlayer == 2 else { return }
        var generator = SystemRandomNumberGenerator()
        let strategy = AIStrategies.strategy(forlevel: selectedDifficulty)
        guard let move = strategy.chooseMove(in: gameState, using: &generator) else { return }
        selectedPiece = move.stone
        placeSelectedPiece(at: move.cell)
    }
    
    /// The single point of legality enforcement for placing a piece: the piece must
    /// belong to the player whose turn it is, and the cell must be empty. This is the
    /// seam any future remote/networked move must also be validated against — the
    /// View layer only decides what's shown, never what's legal.
    @discardableResult
    func placeSelectedPiece(at index: Int) -> Bool {
        guard !isGameOver else { return false }
        guard let selectedPiece = selectedPiece else { return false }
        
        // The engine decides what is legal and what a move does. This function only
        // writes the result back and handles what happens when the game ends.
        let move = Move(stone: selectedPiece, cell: index)
        guard GameRules.isLegal(move, in: gameState) else { return false }
        gameState = GameRules.apply(move, to: gameState)
        
        // Reset selected piece
        self.selectedPiece = nil
        
        if checkGameOver() {
            isGameOver = true
            winner = calculateWinner()
            
            var stats = persistence.loadStats()
            stats.gamesPlayed += 1
            if let winner = winner {
                if winner == 1 { stats.gamesWonByPlayer1 += 1 } else { stats.gamesWonByPlayer2 += 1 }
            }
            persistence.save(stats)
            analytics.track(event: "game_ended",
                            properties:
                                ["mode": "pvc",
                                 "winner": winner.map { "player\($0)" } ?? "tie", "difficulty": selectedDifficulty
                                ]
            )
        }
        
        updateScores()
        return true
        
    }
    
    func resetGame() {
        board = Array(repeating: nil, count: 9)

        (player2Pieces, player1Pieces) = pieces(forDifficulty: selectedDifficulty)

        currentPlayer = startingPlayer
        isGameOver = false
        winner = nil
        player1Score = 0
        player2Score = 0
    }

    func checkGameOver() -> Bool {
        Scoring.isFull(board)
    }

    /// Returns nil on a tie. Unreachable on the current fixed 9-cell board (an odd
    /// count can't split evenly), kept explicit for correctness if that ever changes.
    func calculateWinner() -> Int? {
        Scoring.winner(on: board)
    }
}
