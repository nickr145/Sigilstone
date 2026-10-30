//
//  GameStringConstants.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-11-18.
//

import Foundation

public enum GameStringConstants {
    // SF Symbol names, one per difficulty level.
    static let difficultyImageStrings = ["1.circle.fill", "2.circle.fill", "3.circle.fill", "4.circle.fill", "5.circle.fill", "6.circle.fill"]
    static let difficultyLevelNameStrings = ["Level 1", "Level 2", "Level 3", "Level 4", "Level 5", "Level 6"]
    // Bundled track names (without extension). Empty until audio is added; fill in
    // one name per difficulty level, or leave empty for silence.
    static let musicDifficultyStrings: [String] = []
    static let titleMusicString: String? = nil
    static let instructionsMusicString: String? = nil
    static let difficultySelectionMusicString: String? = nil
    static let gameMusicString: String? = nil
}
