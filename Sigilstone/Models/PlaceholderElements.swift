//
//  PlaceholderElements.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2026-11-02.
//

enum PlaceholderElements {
    /// Until Phase 4 designs the real tile set: gives the first four stones of a hand
    /// the four elements in order and leaves the fifth neutral. Same stones, same ids.
    static func assign(to hand: [Stone]) -> [Stone] {
        var result = hand
        for (index, element) in Element.allCases.enumerated() where result.indices.contains(index) {
            result[index].element = element
        }
        return result
    }
}
