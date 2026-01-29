import SwiftUI

struct WorkoutsListView: View {
    @Binding var workouts: [Workout]
    @State private var editingWorkout: Workout?
    @State private var showingNewWorkout = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.phaseReady
                .ignoresSafeArea()

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
                    showingNewWorkout = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
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
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))

            Text("No Workouts Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Text("Create a workout with custom exercises")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))

            Button {
                showingNewWorkout = true
            } label: {
                Text("Create Workout")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 8)

            Spacer()
        }
    }

    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(workouts) { workout in
                    WorkoutCard(workout: workout) {
                        editingWorkout = workout
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}

struct WorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.buttonTap()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                    Label("\(workout.workTime)s work", systemImage: "flame")
                    Label("\(workout.restTime)s rest", systemImage: "pause")
                }
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    NavigationStack {
        WorkoutsListView(workouts: .constant([.sampleUpperBody, .sampleCore]))
    }
}
