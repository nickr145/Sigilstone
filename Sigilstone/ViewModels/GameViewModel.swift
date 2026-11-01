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
    
//    @Published var board: [Stone?] = Array(repeating: nil, count: 9)
//    @Published var player1Pieces: [Stone]
//    @Published var player2Pieces: [Stone]
//    @Published var selectedPiece: Stone?
//    @Published var currentPlayer: Int
//    @Published var isGameOver: Bool = false
//    @Published var winner: Int?
//    @Published var player1Score: Int = 0
//    @Published var player2Score: Int = 0
//    @Published var isAITurnPending: Bool = false
    
    // The whole game as one value. The engine reads and replaces it; everything else
    // in this class is UI state or side effects.
    @Published private(set) var gameState: GameState
    @Published var selectedPiece: Stone?
    @Published var isGameOver: Bool = false
    @Published var winner: Int?
    @Published var isAITurnPending: Bool = false
    
    // Bumped every time the computer becomes due to move. Views watch this instead of
    // guessing from currentPlayer, which doesn't change when the computer makes the
    // last move of one game and the first move of the next.
    @Published private(set) var computerTurnToken = 0
    
    // Forwarders so views an dtests keep using the same names.
    var board: [Stone?] {
        get { gameState.board }
        set { gameState.board = newValue }
    }
    var player1Pieces: [Stone] {
        get { gameState.player1Hand }
        set { gameState.player1Hand = newValue }
    }
    var player2Pieces: [Stone] {
        get { gameState.player2Hand }
        set { gameState.player2Hand = newValue }
    }
    var currentPlayer: Int {
        get { gameState.currentPlayer }
        set { gameState.currentPlayer = newValue }
    }
    var player1Score: Int { gameState.score(for: 1) }
    var player2Score: Int { gameState.score(for: 2) }

    /// Single source of truth for who moves first, shared by init and resetGame() so the two can never drift out of sync again.
    private let startingPlayer = 2
    private let computerPlayer = 2
    private var isPlayingComputer = false

    private var level1Pieces: [Stone]
    private var level2Pieces: [Stone]
    private var level3Pieces: [Stone]
    private var level4Pieces: [Stone]
    private var level5Pieces: [Stone]
    private var level6Pieces: [Stone]

    private var player1PiecesForEachDifficulty: [[Stone]]

    private let persistence: PersistenceStore
    private let analytics: AnalyticsService
    
    private let pvpPlayer1Hand: [Stone]
    private let pvpPlayer2Hand: [Stone]

    init(persistence: PersistenceStore = UserDefaultsPersistenceStore(), analytics: AnalyticsService = ConsoleAnalyticsService()) {
        let piecesModel = PlayerPiecesModel()
        self.gameState = GameState(player1Hand: piecesModel.player1Pieces, player2Hand: piecesModel.player2Pieces, startingPlayer: startingPlayer)
        self.level1Pieces = piecesModel.level1Pieces
        self.level2Pieces = piecesModel.level2Pieces
        self.level3Pieces = piecesModel.level3Pieces
        self.level4Pieces = piecesModel.level4Pieces
        self.level5Pieces = piecesModel.level5Pieces
        self.level6Pieces = piecesModel.level6Pieces
        self.player1PiecesForEachDifficulty = piecesModel.player1PiecesForEachDifficulty
        self.persistence = persistence
        self.analytics = analytics
        self.pvpPlayer1Hand = piecesModel.player1Pieces
        self.pvpPlayer2Hand = piecesModel.player2Pieces
    }
    
    var selectedDifficulty: Int = 1
    
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
        isPlayingComputer = true
        requestComputerMoveIfDue()
    }
    
    func recordDifficultySelection(_ level: Int) {
        persistence.save(GamePreferences(preferredDifficulty: level))
        analytics.track(event: "difficulty_selected", properties: ["level": level])
    }
    
    /// Asks the strategy for the current difficulty for a move, then plays it.
    func performComputerMove() {
        guard currentPlayer == computerPlayer else { return }
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
        
        if gameState.isOver {
            isGameOver = true
            winner = gameState.winner
            
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
        } else {
            requestComputerMoveIfDue()
        }
        
        return true
        
    }
    
    func resetGame() {
        let player1Hand: [Stone]
        let player2Hand: [Stone]
        if isPlayingComputer {
            let hands = pieces(forDifficulty: selectedDifficulty)
            player1Hand = hands.player1
            player2Hand = hands.computer
        } else {
            // PvP never sets a difficulty, so refill with the hands the game started with.
            player1Hand = pvpPlayer1Hand
            player2Hand = pvpPlayer2Hand
        }
        gameState = GameState(player1Hand: player1Hand, player2Hand: player2Hand, startingPlayer: startingPlayer)
        isGameOver = false
        winner = nil
        requestComputerMoveIfDue()
    }
    
    // Tells the view the computer is due to move, but only in a PvC game that is still going
    private func requestComputerMoveIfDue() {
        if isPlayingComputer && currentPlayer == computerPlayer && !isGameOver {
            computerTurnToken += 1
        }
    }
}
