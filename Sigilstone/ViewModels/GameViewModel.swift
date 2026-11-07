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

    /// The player's hand in PvC is always their active deck. Opponents have decks per level.
    private let playerDeck: Deck

    // Hands built once per game setup and refilled on reset, so a reset deals the same
    // stones (same ids) again.
    private var pvcPlayerHand: [Stone] = []
    private var pvcComputerHand: [Stone] = []

    private let persistence: PersistenceStore
    private let analytics: AnalyticsService
    
    private let pvpPlayer1Hand: [Stone]
    private let pvpPlayer2Hand: [Stone]

    init(persistence: PersistenceStore = UserDefaultsPersistenceStore(), analytics: AnalyticsService = ConsoleAnalyticsService(), playerDeck: Deck = .starter) {
        let standardHand1 = Deck.standard.stones(owner: 1)
        let standardHand2 = Deck.standard.stones(owner: 2)
        self.gameState = GameState(player1Hand: standardHand1, player2Hand: standardHand2, startingPlayer: startingPlayer)
        self.persistence = persistence
        self.analytics = analytics
        self.playerDeck = playerDeck
        self.pvpPlayer1Hand = standardHand1
        self.pvpPlayer2Hand = standardHand2
    }
    
    var selectedDifficulty: Int = 1
    
    /// The most elemental squares a new game may get. 0 keeps boards plain, so unit
    /// tests stay deterministic; the game screens set it to 2. Stones carry their tile's
    /// element either way; only the squares depend on this.
    var maxElementalSquares = 0
    
    /// A random layout of 1 to `maxElementalSquares` squares, or all plain when the max is 0.
    private func newSquares() -> [Element?] {
        guard maxElementalSquares > 0 else { return Array(repeating: nil, count: BoardGeometry.cellCount) }
        var generator = SystemRandomNumberGenerator()
        let count = Int.random(in: 1...maxElementalSquares, using: &generator)
        return BoardGenerator.elementalSquares(count: count, using: &generator)
    }
    
    func setupComputerDifficulty(_ level: Int) {
        selectedDifficulty = level
        analytics.track(event: "game_started", properties: ["mode": "pvc", "difficulty": level])
        pvcPlayerHand = playerDeck.stones(owner: 1)
        pvcComputerHand = OpponentDecks.deck(forLevel: level).stones(owner: 2)
        player1Pieces = pvcPlayerHand
        player2Pieces = pvcComputerHand
        gameState.cellElements = newSquares()
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
            
            // Stats and analytics cover PvC games only.
            if isPlayingComputer {
                var stats = persistence.loadStats()
                stats.gamesPlayed += 1
                if let winner = winner {
                    if winner == 1 { stats.gamesWonByPlayer1 += 1 } else { stats.gamesWonByPlayer2 += 1 }
                }
                persistence.save(stats)
                analytics.track(event: "game_ended", properties: ["mode": "pvc", "winner": winner.map { "player\($0)" } ?? "tie", "difficulty": selectedDifficulty])
            }
        } else {
            requestComputerMoveIfDue()
        }
        
        return true
        
    }
    
    func resetGame() {
        // PvP never sets a difficulty, so it refills with the hands it started with.
        let player1Hand = isPlayingComputer ? pvcPlayerHand : pvpPlayer1Hand
        let player2Hand = isPlayingComputer ? pvcComputerHand : pvpPlayer2Hand
        gameState = GameState(player1Hand: player1Hand, player2Hand: player2Hand, startingPlayer: startingPlayer)
        gameState.cellElements = newSquares()
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
