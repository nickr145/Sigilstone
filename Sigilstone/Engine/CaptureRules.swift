//
//  CaptureRules.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import Foundation

enum CaptureRules {
    /// The neighboring cells that `stone` would capture if it sat at `cell`.
    /// A neighbor is captured when it belongs to the other player and the edge of
    /// `stone` facing it is strictly higher than the neighbor's facing edge.
    static func capturedCells(by stone: Stone, at cell: Int, on board: [Stone?]) -> [Int] {
        var captured: [Int] = []
        for (direction, neighborIndex) in BoardGeometry.neighbors(of: cell) {
            if let neighbor = board[neighborIndex], neighbor.owner != stone.owner, stone.canCapture(neighbor, direction: direction) {
                captured.append(neighborIndex)
            }
        }
        return captured
    }
    
}
