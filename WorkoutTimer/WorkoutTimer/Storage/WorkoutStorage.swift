import Foundation
import os.log

private let logger = Logger(subsystem: "com.workout.timer", category: "WorkoutStorage")

final class WorkoutStorage {
    static let shared = WorkoutStorage()

    private let workoutsKey = "workout-timer-workouts"
    private let quickSettingsKey = "workout-timer-quick-settings"

    private init() {}

    // MARK: - Workouts
    func loadWorkouts() -> [Workout] {
        guard let data = UserDefaults.standard.data(forKey: workoutsKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([Workout].self, from: data)
        } catch {
            logger.error("Failed to decode workouts: \(error.localizedDescription)")
            return []
        }
    }

    func saveWorkouts(_ workouts: [Workout]) {
        do {
            let data = try JSONEncoder().encode(workouts)
            UserDefaults.standard.set(data, forKey: workoutsKey)
        } catch {
            logger.error("Failed to encode workouts: \(error.localizedDescription)")
        }
    }

    func addWorkout(_ workout: Workout) {
        var workouts = loadWorkouts()
        workouts.append(workout)
        saveWorkouts(workouts)
    }

    func updateWorkout(_ workout: Workout) {
        var workouts = loadWorkouts()
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
            saveWorkouts(workouts)
        }
    }

    func deleteWorkout(_ workout: Workout) {
        var workouts = loadWorkouts()
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts(workouts)
    }

    // MARK: - Quick Timer Settings
    struct QuickSettings: Codable {
        var workTime: Int
        var restTime: Int
        var rounds: Int
    }

    func loadQuickSettings() -> QuickSettings {
        guard let data = UserDefaults.standard.data(forKey: quickSettingsKey) else {
            return QuickSettings(workTime: 45, restTime: 15, rounds: 8)
        }
        do {
            return try JSONDecoder().decode(QuickSettings.self, from: data)
        } catch {
            return QuickSettings(workTime: 45, restTime: 15, rounds: 8)
        }
    }

    func saveQuickSettings(_ settings: QuickSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: quickSettingsKey)
        } catch {
            logger.error("Failed to encode quick settings: \(error.localizedDescription)")
        }
    }
}
