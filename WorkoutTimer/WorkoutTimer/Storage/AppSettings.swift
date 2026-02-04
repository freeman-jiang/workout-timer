import Foundation
import os.log

private let logger = Logger(subsystem: "com.workout.timer", category: "AppSettings")

final class AppSettings {
    static let shared = AppSettings()

    private let settingsKey = "workout-timer-app-settings"

    private init() {
        loadSettings()
    }

    // MARK: - Settings

    private(set) var volume: Float = 1.0

    private struct Settings: Codable {
        var volume: Float
    }

    // MARK: - Persistence

    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            return
        }
        do {
            let settings = try JSONDecoder().decode(Settings.self, from: data)
            volume = settings.volume
        } catch {
            logger.error("Failed to decode app settings: \(error.localizedDescription)")
        }
    }

    private func saveSettings() {
        let settings = Settings(volume: volume)
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            logger.error("Failed to encode app settings: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        saveSettings()
    }
}
