//
//  Scoring.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import Foundation

enum Scoring {
    /// How many stones `player` owns on the board
    static func score(for player: Int, on board: [Stone?]) -> Int {
        board.filter { $0?.owner == player }.count
    }
    
    /// The game ends when every cell is filled.
    static func isFull(_ board: [Stone?]) -> Bool {
        !board.contains { $0 == nil }
    }
        
    /// The player with more stones, or nil on a tie. A tie can't happen on a full
    /// 9-cell board (9 is odd), but the rule stays explicit for boards with blocks later.
    static func winner(on board: [Stone?]) -> Int? {
        let player1 = score(for: 1, on: board)
        let player2 = score(for: 2, on: board)
        if player1 == player2 { return nil }
        
        return player1 > player2 ? 1 : 2
    }
    
}
