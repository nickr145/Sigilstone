//
//  GameRules.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import Foundation

enum GameRules {
    /// Whether `move` may be played right now. This is exactly what
    /// GameViewModel.placeSelectedPiece enforces today: the game isn't over, the
    /// stone belongs to the player whose turn it is, and the cell exists and is empty.
    /// It does NOT check that the stone is in that player's hand. The UI only offers
    /// hand stones, and tightening this is a deliberate later change.
    static func isLegal(_ move: Move, in state: GameState) -> Bool {
        guard !state.isOver else { return false }
        guard move.stone.owner == state.currentPlayer else { return false }
        guard state.board.indices.contains(move.cell) else { return false }
        return state.board[move.cell] == nil
    }
    
    /// Every move the player to move can make from their hand: for each empty cell
    /// in ascending order, each stone in hand order. The level 6 AI breaks ties by
    /// taking the first best move in exactly this order, so keep it stable.
    static func legalMoves(in state: GameState) -> [Move] {
        guard !state.isOver else { return [] }
        let hand = state.hand(for: state.currentPlayer)
        var moves: [Move] = []
        for cell in state.emptyCells {
            for stone in hand {
                moves.append(Move(stone: stone, cell: cell))
            }
        }
        return moves
    }
    
    /// The state after `move` is played. The caller checks `isLegal` first; this
    /// trusts it. The stone captures every neighbor it beats, leaves its owner's
    /// hand, and the turn passes, except after the final move, when the turn stays
    /// put because the game is over.
    static func apply(_ move: Move, to state: GameState) -> GameState {
        var next = state
        next.board[move.cell] = move.stone
        
        for neighbor in CaptureRules.capturedCells(by: move.stone, at: move.cell, on: next.board) {
            next.board[neighbor]?.owner = move.stone.owner
        }
        
        if move.stone.owner == 1 {
            if let index = next.player1Hand.firstIndex(of: move.stone) {
                next.player1Hand.remove(at: index)
            }
        } else {
            if let index = next.player2Hand.firstIndex(of: move.stone) {
                next.player2Hand.remove(at: index)
            }
        }
        
        if !next.isOver {
            next.currentPlayer = state.currentPlayer == 1 ? 2 : 1
        }
        
        return next
    }
}
