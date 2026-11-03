//
//  ElementStyle.swift
//  Sigilstone
//

import SwiftUI

/// How an element looks on screen. Every element has a symbol as well as a color,
/// so the squares and stones never depend on color alone. Placeholder looks until
/// Phase 4 designs the tile set.
extension Element {
    var symbolName: String {
        switch self {
        case .fire: return "flame.fill"
        case .water: return "drop.fill"
        case .earth: return "mountain.2.fill"
        case .air: return "wind"
        }
    }

    var color: Color {
        switch self {
        case .fire: return .orange
        case .water: return .cyan
        case .earth: return .green
        case .air: return .mint
        }
    }

    var displayName: String { rawValue.capitalized }
}
