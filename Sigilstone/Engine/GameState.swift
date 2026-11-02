//
//  GameState.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import Foundation

/// A stone placed on a cell. The stone carries its owner.
struct Move: Equatable {
    let stone: Stone
    let cell: Int
}

/// Everything about a game in progress that the rules care about, and nothing
/// the UI cares about. It is a value type, so copying it gives an independent
/// game, which is what lets the AI try moves without touching the real one.
struct GameState: Equatable {
    var board: [Stone?]
    var player1Hand: [Stone]
    var player2Hand: [Stone]
    var currentPlayer: Int
    /// The element of each cell's square, or nil for a plain cell. Stones placed on an
    /// elemental square must match it or they break.
    var cellElements: [Element?] = Array(repeating: nil, count: BoardGeometry.cellCount)
    /// Cells holding a block: a broken stone that can't be played on, owned or scored.
    var blocks: Set<Int> = []
    
    init(player1Hand: [Stone], player2Hand: [Stone], startingPlayer: Int) {
        self.board = Array(repeating: nil, count: BoardGeometry.cellCount)
        self.player1Hand = player1Hand
        self.player2Hand = player2Hand
        self.currentPlayer = startingPlayer
    }
    
    init(board: [Stone?], player1Hand: [Stone], player2Hand: [Stone], currentPlayer: Int) {
        self.board = board
        self.player1Hand = player1Hand
        self.player2Hand = player2Hand
        self.currentPlayer = currentPlayer
    }
    
    /// Cells that are neither holding a stone nor blocked.
    var emptyCells: [Int] {
        board.indices.filter { board[$0] == nil && !blocks.contains($0) }
    }
    
    /// The game ends when every cell is filled or blocked
    var isOver: Bool {
        emptyCells.isEmpty
    }
    
    func hand(for player: Int) -> [Stone] {
        player == 1 ? player1Hand : player2Hand
    }
    
    func score(for player: Int) -> Int {
        Scoring.score(for: player, on: board)
    }
    
    /// The player with more stones, or nil on a tie
    var winner: Int? {
        Scoring.winner(on: board)
    }
}

