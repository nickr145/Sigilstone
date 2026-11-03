//
//  AILevels.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-10-31.
//

import Foundation

/// Level 1: a random stone from the hand on a random empty cell.
struct RandomStrategy: AIStrategy {
    func chooseMove<G>(in state: GameState, using generator: inout G) -> Move? where G : RandomNumberGenerator {
        let hand = state.hand(for: state.currentPlayer)
        guard !hand.isEmpty,
              let cell = state.emptyCells.randomElement(using: &generator),
              let stone = hand.randomElement(using: &generator) else { return nil }
        return Move(stone: stone, cell: cell)
        
    }
}

/// Level 2: prefers corner cells, which have only two neighbors and so are the
/// hardest to recapture. The stone is random.
struct CornerStrategy: AIStrategy {
    private let corners: Set<Int> = [0, 2, 6, 8]
    
    func chooseMove<G>(in state: GameState, using generator: inout G) -> Move? where G : RandomNumberGenerator {
        let hand = state.hand(for: state.currentPlayer)
        let available = state.emptyCells
        let preferred = available.filter { corners.contains($0) }
        let chosenCell = preferred.isEmpty ? available.randomElement(using: &generator) : preferred.randomElement(using: &generator)
        guard let stone = hand.randomElement(using: &generator), let cell = chosenCell else { return nil }
        return Move(stone: stone, cell: cell)
    }
}

/// Levels 3 and 4: takes the first empty cell (lowest index) where a randomly drawn
/// stone captures something; a stone that would break captures nothing. If no cell
/// captures, plays randomly but avoids breaking when a safe move exists. The old
/// level 4 code was identical to level 3, so they share this.
struct CaptureFirstStrategy: AIStrategy {
    func chooseMove<G: RandomNumberGenerator>(in state: GameState, using generator: inout G) -> Move? {
        let hand = state.hand(for: state.currentPlayer)
        guard !hand.isEmpty else { return nil }

        for cell in state.emptyCells {
            if let stone = hand.randomElement(using: &generator) {
                let move = Move(stone: stone, cell: cell)
                if !GameRules.capturedCells(by: move, in: state).isEmpty {
                    return move
                }
            }
        }

        let moves = GameRules.legalMoves(in: state)
        let safeMoves = moves.filter { !GameRules.breaks($0, in: state) }
        return (safeMoves.isEmpty ? moves : safeMoves).randomElement(using: &generator)
    }
}

/// Level 5: for every empty cell it tries one randomly drawn stone, then plays the
/// cell where that stone captures the most. A move that would break scores -1, below
/// any harmless move. Ties go to the lowest cell. (The old comments called this
/// minimax with pruning; it never was.)
struct GreedyCaptureStrategy: AIStrategy {
    func chooseMove<G: RandomNumberGenerator>(in state: GameState, using generator: inout G) -> Move? {
        let hand = state.hand(for: state.currentPlayer)
        guard !hand.isEmpty else { return nil }

        var bestScore = Int.min
        var bestMove: Move?
        for cell in state.emptyCells {
            if let stone = hand.randomElement(using: &generator) {
                let move = Move(stone: stone, cell: cell)
                let score = GameRules.breaks(move, in: state)
                    ? -1
                    : GameRules.capturedCells(by: move, in: state).count
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }
        }
        return bestMove
    }
}

/// Level 6: tries every stone on every cell and scores a move as one point for a
/// stone that stays on the board, plus the stones it captures, minus the most the
/// opponent could capture in reply. A stone that breaks scores no point and
/// captures nothing, but leaves a block the opponent can't use, so sacrificing a
/// stone can still win the comparison. On a plain board every move gets the same
/// one point, so choices match the old look-ahead exactly. Ties go to the first
/// move in legalMoves order (lowest cell, then hand order).
struct LookAheadStrategy: AIStrategy {
    func chooseMove<G: RandomNumberGenerator>(in state: GameState, using generator: inout G) -> Move? {
        var bestScore = Int.min
        var bestMove: Move?
        for move in GameRules.legalMoves(in: state) {
            let kept = GameRules.breaks(move, in: state) ? 0 : 1
            let gain = GameRules.capturedCells(by: move, in: state).count
            let reply = LookAheadStrategy.worstReply(after: move, in: state)
            if kept + gain - reply > bestScore {
                bestScore = kept + gain - reply
                bestMove = move
            }
        }
        return bestMove
    }

    /// The most stones the opponent could capture right after `move`. Like the old
    /// code, this puts the stone on the board WITHOUT applying its own captures. A
    /// real search (Phase 6) will fix that. A move that breaks leaves a block instead
    /// of a stone, and the opponent's own stones break on elemental squares too.
    static func worstReply(after move: Move, in state: GameState) -> Int {
        var hypothetical = state
        if GameRules.breaks(move, in: state) {
            hypothetical.blocks.insert(move.cell)
        } else {
            hypothetical.board[move.cell] = move.stone
        }

        let opponent = move.stone.owner == 1 ? 2 : 1
        var worst = 0
        for cell in hypothetical.emptyCells {
            for stone in state.hand(for: opponent) {
                let reply = Move(stone: stone, cell: cell)
                worst = max(worst, GameRules.capturedCells(by: reply, in: hypothetical).count)
            }
        }
        return worst
    }
}

