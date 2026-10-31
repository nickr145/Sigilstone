//
//  BoardGeometry.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-10-30.
//

import Foundation

/// The shape of the 3x3 board: which cells touch which. Cells are numbered 0...8, left to right and top to bottom.
enum BoardGeometry {
    static let columns = 3
    static let cellCount = 9
    
    /// The cells touching `index` each with the dir you look from `index` to reach it.
    /// Order is top, bottom, left, right.
    static func neighbors(of index: Int) -> [(direction: Direction, index: Int)] {
        var result: [(direction: Direction, index: Int)] = []
        if index >= columns { result.append((.top, index - columns)) }
        if index < cellCount - columns { result.append((.bottom, index + columns)) }
        if index % columns != 0 { result.append((.left, index - 1)) }
        if index % columns != columns - 1 { result.append((.right, index + 1)) }
        return result
    }
}

