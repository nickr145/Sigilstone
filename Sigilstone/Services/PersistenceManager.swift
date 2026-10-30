//
//  PersistenceManager.swift
//  Sigilstone
//

import Foundation

struct GamePreferences: Codable, Equatable {
    var preferredDifficulty: Int = 1
    var isAudioMuted: Bool = false
}

struct GameStats: Codable, Equatable {
    var gamesPlayed: Int = 0
    var gamesWonByPlayer1: Int = 0
    var gamesWonByPlayer2: Int = 0
}

protocol PersistenceStore {
    func loadPreferences() -> GamePreferences
    func save(_ preferences: GamePreferences)
    func loadStats() -> GameStats
    func save(_ stats: GameStats)
}

final class UserDefaultsPersistenceStore: PersistenceStore {
    private let defaults: UserDefaults
    private enum Keys {
        static let preferences = "gamePreferences"
        static let stats = "gameStats"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadPreferences() -> GamePreferences {
        guard let data = defaults.data(forKey: Keys.preferences),
              let decoded = try? JSONDecoder().decode(GamePreferences.self, from: data) else {
            return GamePreferences()
        }
        return decoded
    }

    func save(_ preferences: GamePreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: Keys.preferences)
    }

    func loadStats() -> GameStats {
        guard let data = defaults.data(forKey: Keys.stats),
              let decoded = try? JSONDecoder().decode(GameStats.self, from: data) else {
            return GameStats()
        }
        return decoded
    }

    func save(_ stats: GameStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: Keys.stats)
    }
}
