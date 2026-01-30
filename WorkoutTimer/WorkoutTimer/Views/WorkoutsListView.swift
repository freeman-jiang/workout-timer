import SwiftUI

// MARK: - Int Identifiable Extension

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct WorkoutsListView: View {
    @Binding var workouts: [Workout]
    @State private var editingWorkoutIndex: Int?
    @State private var newWorkoutIndex: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Animated background
            AnimatedPhaseBackground(phase: .ready, isRunning: false)

            VStack(spacing: 0) {
                if workouts.isEmpty {
                    emptyState
                } else {
                    workoutsList
                }
            }
        }
        .navigationTitle("My Workouts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.buttonTap()
                    createNewWorkout()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .glassCircle()
                }
                .buttonStyle(IconGlassButtonStyle())
                .accessibilityLabel("Add workout")
            }
        }
        .sheet(item: $newWorkoutIndex) { index in
            if index < workouts.count {
                WorkoutEditorView(
                    workout: $workouts[index],
                    isNewWorkout: true,
                    onDelete: nil
                )
                .onDisappear {
                    cleanupNewWorkoutIfInvalid(at: index)
                }
            }
        }
        .sheet(item: $editingWorkoutIndex) { index in
            if index < workouts.count {
                WorkoutEditorView(
                    workout: $workouts[index],
                    isNewWorkout: false,
                    onDelete: { toDelete in
                        workouts.removeAll { $0.id == toDelete.id }
                        WorkoutStorage.shared.saveWorkouts(workouts)
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions

    private func createNewWorkout() {
        // Create a placeholder workout and add it to the array
        let newWorkout = Workout(
            id: UUID(),
            name: "",
            workTime: 45,
            restTime: 15,
            exercises: []
        )
        workouts.append(newWorkout)
        newWorkoutIndex = workouts.count - 1
    }

    private func cleanupNewWorkoutIfInvalid(at index: Int) {
        // If the workout at this index is still invalid (empty name or no exercises),
        // remove it from the list
        guard index < workouts.count else { return }
        let workout = workouts[index]

        let isValid = !workout.name.trimmingCharacters(in: .whitespaces).isEmpty && !workout.exercises.isEmpty

        if !isValid {
            workouts.remove(at: index)
            // No need to save - it was never persisted
        } else {
            // Ensure it's persisted
            WorkoutStorage.shared.saveWorkouts(workouts)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "dumbbell")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.25))

            Text("No Workouts Yet")
                .font(Typography.celebration)
                .foregroundStyle(.white)

            Text("Create a workout with custom exercises")
                .font(Typography.settingLabel)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                HapticManager.shared.buttonTap()
                createNewWorkout()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Create Workout")
                        .font(Typography.button)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .glassCapsule(prominent: true)
            }
            .buttonStyle(PrimaryGlassButtonStyle())
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                    GlassWorkoutCard(workout: workout) {
                        editingWorkoutIndex = index
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Glass Workout Card

struct GlassWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            HapticManager.shared.buttonTap()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Title row
                HStack {
                    Text(workout.name)
                        .font(Typography.cardTitle)
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // Stats row
                HStack(spacing: 12) {
                    statBadge(icon: "clock", value: formatDuration(workout.totalDuration), label: "")
                    statBadge(
                        icon: "list.bullet",
                        value: "\(workout.exercises.count)",
                        label: workout.exercises.count == 1 ? "exercise" : "exercises"
                    )
                    statBadge(icon: "figure.run", value: "\(workout.workTime)s", label: "work")
                    statBadge(icon: "moon.fill", value: "\(workout.restTime)s", label: "rest")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassBackground(cornerRadius: 16)
        }
        .buttonStyle(GlassButtonStyle())
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .accessibilityHidden(true)

            Text(label.isEmpty ? value : "\(value) \(label)")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.white.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label.isEmpty ? value : "\(value) \(label)")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if seconds == 0 {
            return "\(minutes)m"
        }
        return "\(minutes)m \(seconds)s"
    }
}

#Preview {
    NavigationStack {
        WorkoutsListView(workouts: .constant([.sampleUpperBody, .sampleCore]))
    }
}

#Preview("Empty") {
    NavigationStack {
        WorkoutsListView(workouts: .constant([]))
    }
}
