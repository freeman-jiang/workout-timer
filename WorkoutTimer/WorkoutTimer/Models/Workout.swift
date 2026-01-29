import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var workTime: Int // seconds
    var restTime: Int // seconds
    var exercises: [String]

    init(
        id: UUID = UUID(),
        name: String,
        workTime: Int = 45,
        restTime: Int = 15,
        exercises: [String]
    ) {
        self.id = id
        self.name = name
        self.workTime = workTime
        self.restTime = restTime
        self.exercises = exercises
    }

    var totalRounds: Int {
        exercises.count
    }

    var totalDuration: TimeInterval {
        let workTotal = Double(workTime * exercises.count)
        let restTotal = Double(restTime * (exercises.count - 1)) // No rest after last round
        return workTotal + restTotal
    }

    func exerciseName(forRound round: Int) -> String? {
        guard round >= 1 && round <= exercises.count else { return nil }
        return exercises[round - 1]
    }

    func nextExerciseName(afterRound round: Int) -> String? {
        guard round >= 1 && round < exercises.count else { return nil }
        return exercises[round]
    }
}

// Sample workouts for testing
extension Workout {
    static let sampleUpperBody = Workout(
        name: "Upper Body",
        workTime: 45,
        restTime: 15,
        exercises: [
            "Push-ups",
            "Pull-ups",
            "Dips",
            "Diamond Push-ups",
            "Chin-ups",
            "Pike Push-ups",
            "Inverted Rows",
            "Archer Push-ups"
        ]
    )

    static let sampleCore = Workout(
        name: "Core Blast",
        workTime: 30,
        restTime: 10,
        exercises: [
            "Plank",
            "Mountain Climbers",
            "Russian Twists",
            "Bicycle Crunches",
            "Leg Raises",
            "Dead Bug"
        ]
    )
}
