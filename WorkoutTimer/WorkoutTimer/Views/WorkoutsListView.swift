import SwiftUI

struct WorkoutsListView: View {
    @Binding var workouts: [Workout]
    @State private var editingWorkout: Workout?
    @State private var showingNewWorkout = false
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
                    showingNewWorkout = true
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
        .sheet(isPresented: $showingNewWorkout) {
            WorkoutEditorView(
                workout: nil,
                onSave: { workout in
                    workouts.append(workout)
                    WorkoutStorage.shared.saveWorkouts(workouts)
                },
                onDelete: nil
            )
        }
        .sheet(item: $editingWorkout) { workout in
            WorkoutEditorView(
                workout: workout,
                onSave: { updated in
                    if let index = workouts.firstIndex(where: { $0.id == updated.id }) {
                        workouts[index] = updated
                        WorkoutStorage.shared.saveWorkouts(workouts)
                    }
                },
                onDelete: { toDelete in
                    workouts.removeAll { $0.id == toDelete.id }
                    WorkoutStorage.shared.saveWorkouts(workouts)
                }
            )
        }
        .preferredColorScheme(.dark)
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
                showingNewWorkout = true
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
                ForEach(workouts) { workout in
                    GlassWorkoutCard(workout: workout) {
                        editingWorkout = workout
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
                HStack(spacing: 16) {
                    statBadge(icon: "list.bullet", value: "\(workout.exercises.count)", label: "exercises")
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

            Text(value)
                .font(Typography.cardSubtitle)
                .foregroundStyle(.white.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
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
