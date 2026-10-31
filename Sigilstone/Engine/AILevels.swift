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
/// stone captures something, otherwise plays randomly. The old level 4 code was
/// identical to level 3 apart from comments claiming minimax, so they share this.
struct CaptureFirstStrategy: AIStrategy {
    func chooseMove<G>(in state: GameState, using generator: inout G) -> Move? where G : RandomNumberGenerator {
        let hand = state.hand(for: state.currentPlayer)
        guard !hand.isEmpty else { return nil }
        
        for cell in state.emptyCells {
            if let stone = hand.randomElement(using: &generator),
               !CaptureRules.capturedCells(by: stone, at: cell, on: state.board).isEmpty {
                return Move(stone: stone, cell: cell)
            }
        }
        return RandomStrategy().chooseMove(in: state, using: &generator)
    }
}

/// Level 5: for every empty cell it tries one randomly drawn stone, then plays the
/// cell where that stone captures the most. Ties go to the lowest cell. (The old
/// comments called this minimax with pruning; it never was.)
struct GreedyCaptureStrategy: AIStrategy {
    func chooseMove<G: RandomNumberGenerator>(in state: GameState, using generator: inout G) -> Move? {
        let hand = state.hand(for: state.currentPlayer)
        guard !hand.isEmpty else { return nil }

        var bestScore = Int.min
        var bestMove: Move?
        for cell in state.emptyCells {
            if let stone = hand.randomElement(using: &generator) {
                let score = CaptureRules.capturedCells(by: stone, at: cell, on: state.board).count
                if score > bestScore {
                    bestScore = score
                    bestMove = Move(stone: stone, cell: cell)
                }
            }
        }
        return bestMove
    }
}

/// Level 6: tries every stone on every cell and scores a move as the stones it
/// captures minus the most the opponent could capture in reply. Ties go to the first
/// move in legalMoves order (lowest cell, then hand order).
struct LookAheadStrategy: AIStrategy {
    func chooseMove<G: RandomNumberGenerator>(in state: GameState, using generator: inout G) -> Move? {
        let opponentHand = state.hand(for: state.currentPlayer == 1 ? 2 : 1)

        var bestScore = Int.min
        var bestMove: Move?
        for move in GameRules.legalMoves(in: state) {
            let gain = CaptureRules.capturedCells(by: move.stone, at: move.cell, on: state.board).count
            let reply = LookAheadStrategy.worstReply(after: move, on: state.board, opponentHand: opponentHand)
            if gain - reply > bestScore {
                bestScore = gain - reply
                bestMove = move
            }
        }
        return bestMove
    }

    /// The most stones the opponent could capture right after `move`. Like the old
    /// code, this puts the stone on the board WITHOUT applying its own captures. A
    /// real search (Phase 6) will fix that.
    static func worstReply(after move: Move, on board: [Stone?], opponentHand: [Stone]) -> Int {
        var hypothetical = board
        hypothetical[move.cell] = move.stone

        var worst = 0
        for cell in hypothetical.indices where hypothetical[cell] == nil {
            for stone in opponentHand {
                worst = max(worst, CaptureRules.capturedCells(by: stone, at: cell, on: hypothetical).count)
            }
        }
        return worst
    }
}

