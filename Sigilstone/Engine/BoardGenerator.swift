//
//  BoardGenerator.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-11-02.
//

import Foundation

enum BoardGenerator {
    /// A board layout with `count` elemental squares on distinct random cells, each with
    /// a random element. Pass a seeded generator for a layout that repeats (a campaign
    /// node); pass the system generator for a different board every time.
    static func elementalSquares<G: RandomNumberGenerator>(count: Int, using generator: inout G) -> [Element?] {
        var squares: [Element?] = Array(repeating: nil, count: BoardGeometry.cellCount)
        let wanted = min(max(count, 0), BoardGeometry.cellCount)
        let cells = Array(0..<BoardGeometry.cellCount).shuffled(using: &generator).prefix(wanted)
        for cell in cells {
            squares[cell] = Element.allCases.randomElement(using: &generator)
        }
        return squares
    }
}
