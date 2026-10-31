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
    
    init(player1Hand: [Stone], player2Hand: [Stone], startingPlayer: Int) {
        self.board = Array(repeating: nil, count: BoardGeometry.cellCount)
        self.player1Hand = player1Hand
        self.player2Hand = player2Hand
        self.currentPlayer = startingPlayer
    }
    
    var emptyCells: [Int] {
        board.indices.filter { board[$0] == nil }
    }
    
    /// The game ends when every cell is filled
    var isOver: Bool {
        emptyCells.isEmpty
    }
    
    func hand(for player: Int) -> [Stone] {
        player == 1 ? player1Hand : player2Hand
    }
    
    func score(for player: Int) -> Int {
        board.filter { $0?.owner == player }.count
    }
    
    /// The player with more stones, or nil on a tie
    var winner: Int? {
        let player1 = score(for: 1)
        let player2 = score(for: 2)
        if player1 == player2 { return nil }
        return player1 > player2 ? 1 : 2
    }
}

