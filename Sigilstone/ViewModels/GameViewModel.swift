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

    // Single source of truth for who moves first, shared by init and resetGame()
    // so the two can never drift out of sync again.
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
    
    // Bridge to the engine until GameState becomes the stored property (step 7):
    // reads the published fields into a GameState, and writes a new one back.
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
    
    // Difficulty is always 1-6 in practice (the picker that drives it only offers
    // those values), but Int isn't exhaustively switchable, so `default` falls
    // back to level 1 rather than being duplicated across every caller.
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

    // Method to perform moves based on difficulty level
    func performComputerMove() {
        switch selectedDifficulty {
        case 1:
            Lvl1ComputerMove()  // Random moves
        case 2:
            Lvl2ComputerMove()  // Basic strategy: avoid bad spots
        case 3:
            Lvl3ComputerMove()  // More advanced strategy
        case 4:
            Lvl4ComputerMove()  // MiniMax algorithm, depth limited
        case 5:
            Lvl5ComputerMove()  // MiniMax with Alpha-Beta pruning
        case 6:
            Lvl6ComputerMove()
        default:
            Lvl1ComputerMove()  // Default to level 1 if not specified
        }
    }
    
    func Lvl1ComputerMove() {
        let availableCells = board.indices.filter { board[$0] == nil }
        
        // Ensure the computer has pieces left to place
        guard !player2Pieces.isEmpty, let randomCell = availableCells.randomElement() else { return }
        
        // Pick a random piece from player2's available pieces
        if let randomPiece = player2Pieces.randomElement() {
            selectedPiece = randomPiece
            placeSelectedPiece(at: randomCell) // Use placeSelectedPiece to handle removing the piece
        }
    }
    
    // The 3x3 board's corners have only 2 neighbors, making them the safest
    // cells to occupy (fewest directions a piece can be recaptured from).
    private let cornerIndices: Set<Int> = [0, 2, 6, 8]

    // Level 2 AI: Avoid bad spots, basic capture logic
    func Lvl2ComputerMove() {
        let availableCells = board.indices.filter { board[$0] == nil }

        // Basic heuristic: prefer corners, which are hardest to counter-capture
        let prioritizedCells = availableCells.filter { cornerIndices.contains($0) }

        let cellToPlace = prioritizedCells.isEmpty ? availableCells.randomElement() : prioritizedCells.randomElement()
        
        if let randomPiece = player2Pieces.randomElement(), let cell = cellToPlace {
            selectedPiece = randomPiece
            placeSelectedPiece(at: cell)
        }
    }
    
    // Level 3 AI: Aggressive capture strategy
    func Lvl3ComputerMove() {
        let availableCells = board.indices.filter { board[$0] == nil }
        
        // Prioritize capture moves
        for cell in availableCells {
            if let piece = player2Pieces.randomElement() {
                if canCaptureAdjacent(at: cell, with: piece) {
                    selectedPiece = piece
                    placeSelectedPiece(at: cell)
                    return
                }
            }
        }
        
        // Fall back to random if no captures available
        Lvl1ComputerMove()
    }
    
    func Lvl4ComputerMove() {
        let availableCells = board.indices.filter { board[$0] == nil }
        guard !player2Pieces.isEmpty else { return }
        
        // Try to find a move that will capture stones
        for cell in availableCells {
            if let randomPiece = player2Pieces.randomElement() {
                if canCaptureAt(cell: cell, with: randomPiece) {
                    selectedPiece = randomPiece
                    placeSelectedPiece(at: cell)
                    return
                }
            }
        }
        
        // Fallback to random move if no capture opportunities
        if let randomCell = availableCells.randomElement(),
           let randomPiece = player2Pieces.randomElement() {
            selectedPiece = randomPiece
            placeSelectedPiece(at: randomCell)
        }
    }
    
    func Lvl5ComputerMove() {
        let availableCells = board.indices.filter { board[$0] == nil }
        guard !player2Pieces.isEmpty else { return }
        
        var bestScore = Int.min
        var bestMove: (cell: Int, piece: Stone)?
        
        for cell in availableCells {
            if let randomPiece = player2Pieces.randomElement() {
                // Simulate placing the piece and calculate the score
                let simulatedScore = simulateMove(for: randomPiece, at: cell)
                if simulatedScore > bestScore {
                    bestScore = simulatedScore
                    bestMove = (cell, randomPiece)
                }
            }
        }
        
        // Perform the best move
        if let bestMove = bestMove {
            selectedPiece = bestMove.piece
            placeSelectedPiece(at: bestMove.cell)
        }
    }
    
    func Lvl6ComputerMove() {
        let availableCells = board.indices.filter { board[$0] == nil }
        guard !player2Pieces.isEmpty else { return }
        
        var bestScore = Int.min
        var bestMove: (cell: Int, piece: Stone)?
        
        for cell in availableCells {
            for piece in player2Pieces {
                // Simulate placing the piece
                let simulatedScore = simulateMove(for: piece, at: cell)
                
                // Look ahead: Simulate the opponent's best possible response
                let opponentScore = simulateOpponentMove(for: piece, at: cell)
                
                // Net score prioritizes aggressive play while considering blocking Player 1
                let netScore = simulatedScore - opponentScore
                
                if netScore > bestScore {
                    bestScore = netScore
                    bestMove = (cell, piece)
                }
            }
        }
        
        // Perform the best move
        if let bestMove = bestMove {
            selectedPiece = bestMove.piece
            placeSelectedPiece(at: bestMove.cell)
        }
    }
    
    // simulation function needed for lvl6
    // Evaluates the opponent's best possible reply against a board where `piece`
    // has already been placed at `cell`, so the AI can see retaliation against
    // the stone it's about to place, not just against the board as it is now.
    func simulateOpponentMove(for piece: Stone, at cell: Int) -> Int {
        var hypotheticalBoard = board
        hypotheticalBoard[cell] = piece
        let availableCells = hypotheticalBoard.indices.filter { hypotheticalBoard[$0] == nil }
        var worstOutcome = 0

        for opponentCell in availableCells {
            for opponentPiece in player1Pieces {
                // Simulate Player 1's best response
                let simulatedOpponentScore = simulateMove(for: opponentPiece, at: opponentCell, on: hypotheticalBoard)
                worstOutcome = max(worstOutcome, simulatedOpponentScore)
            }
        }

        return worstOutcome
    }

    // Logic for being able to capture adjacent cells with a given piece for level 3 AI
    func canCaptureAdjacent(at index: Int, with piece: Stone) -> Bool {
        canCaptureAt(cell: index, with: piece)
    }

    // Logic to capture a certain cell for a given piece for level 4 AI
    func canCaptureAt(cell: Int, with piece: Stone) -> Bool {
        !CaptureRules.capturedCells(by: piece, at: cell, on: board).isEmpty
    }

    // Logic to simulate a certain move and return how many stones can be potentially
    // captured, used to determine the best possible move for level 5/6 AI. Defaults to
    // the live board, but accepts a hypothetical one so lookahead can be evaluated
    // against a board that already has another candidate move applied.
    func simulateMove(for piece: Stone, at cell: Int, on board: [Stone?]? = nil) -> Int {
        var simulatedBoard = board ?? self.board
        simulatedBoard[cell] = piece
        return captureSimulatedStones(at: cell, board: simulatedBoard)
    }

    // Logic to identify all capturable stones at a place in the board for level 5/6 AI
    func captureSimulatedStones(at index: Int, board: [Stone?]) -> Int {
        guard let stone = board[index] else { return 0 }
        return CaptureRules.capturedCells(by: stone, at: index, on: board).count
    }
    
    
    // The single point of legality enforcement for placing a piece: the piece must
    // belong to the player whose turn it is, and the cell must be empty. This is the
    // seam any future remote/networked move must also be validated against — the
    // View layer only decides what's shown, never what's legal.
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
    
//    @discardableResult
//    func placeSelectedPiece(at index: Int) -> Bool {
//        guard !isGameOver else { return false }
//        guard let selectedPiece = selectedPiece else { return false }
//        guard selectedPiece.owner == currentPlayer else { return false }
//        guard index >= 0, index < board.count, board[index] == nil else { return false }
//
//        board[index] = selectedPiece
//        captureAdjacentStones(at: index)
//
//        // Remove the placed piece from its owner's available pieces
//        if selectedPiece.owner == 1 {
//            if let selectedIndex = player1Pieces.firstIndex(of: selectedPiece) {
//                player1Pieces.remove(at: selectedIndex)
//            }
//        } else {
//            if let selectedIndex = player2Pieces.firstIndex(of: selectedPiece) {
//                player2Pieces.remove(at: selectedIndex)
//            }
//        }
//
//        // Reset selected piece
//        self.selectedPiece = nil
//
//        if checkGameOver() {
//            isGameOver = true
//            winner = calculateWinner()
//
//            var stats = persistence.loadStats()
//            stats.gamesPlayed += 1
//            if let winner = winner {
//                if winner == 1 { stats.gamesWonByPlayer1 += 1 } else { stats.gamesWonByPlayer2 += 1 }
//            }
//            persistence.save(stats)
//
//            analytics.track(event: "game_ended", properties: ["mode": "pvc", "winner": winner.map { "player\($0)" } ?? "tie", "difficulty": selectedDifficulty])
//        } else {
//            currentPlayer = currentPlayer == 1 ? 2 : 1
//        }
//
//        updateScores()
//        return true
//    }

//    func captureAdjacentStones(at index: Int) {
//        guard let stone = board[index] else { return }
//        for neighborIndex in CaptureRules.capturedCells(by: stone, at: index, on: board) {
//            board[neighborIndex]?.owner = stone.owner
//        }
//    }
    
    
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

    // Returns nil on a tie. Unreachable on the current fixed 9-cell board (an odd
    // count can't split evenly), kept explicit for correctness if that ever changes.
    func calculateWinner() -> Int? {
        Scoring.winner(on: board)
    }
}
