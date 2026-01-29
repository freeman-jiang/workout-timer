import SwiftUI

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let workout: Workout?
    let onSave: (Workout) -> Void
    let onDelete: ((Workout) -> Void)?

    @State private var name: String
    @State private var workTime: Int
    @State private var restTime: Int
    @State private var exercises: [ExerciseItem]
    @State private var newExercise: String = ""
    @State private var showingDeleteConfirmation = false

    private var isEditing: Bool { workout != nil }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !exercises.isEmpty
    }

    init(
        workout: Workout?,
        onSave: @escaping (Workout) -> Void,
        onDelete: ((Workout) -> Void)?
    ) {
        self.workout = workout
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: workout?.name ?? "")
        _workTime = State(initialValue: workout?.workTime ?? 45)
        _restTime = State(initialValue: workout?.restTime ?? 15)
        _exercises = State(initialValue: (workout?.exercises ?? []).map { ExerciseItem(name: $0) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.phaseReady
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Workout Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))

                            TextField("e.g. Upper Body", text: $name)
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Time settings
                        VStack(spacing: 16) {
                            EditorSettingRow(
                                label: "Work Time",
                                value: $workTime,
                                range: 5...300,
                                unit: "sec"
                            )

                            EditorSettingRow(
                                label: "Rest Time",
                                value: $restTime,
                                range: 5...300,
                                unit: "sec"
                            )
                        }

                        // Exercises
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercises (\(exercises.count))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))

                            // Add new exercise
                            HStack(spacing: 8) {
                                TextField("Add exercise", text: $newExercise)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onSubmit {
                                        addExercise()
                                    }

                                Button {
                                    addExercise()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                        .background(.white.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .disabled(newExercise.trimmingCharacters(in: .whitespaces).isEmpty)
                            }

                            // Exercise list with drag and drop
                            if !exercises.isEmpty {
                                List {
                                    ForEach(exercises) { exercise in
                                        ExerciseRow(
                                            index: (exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0) + 1,
                                            name: exercise.name,
                                            onDelete: {
                                                exercises.removeAll { $0.id == exercise.id }
                                            }
                                        )
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                        .listRowSeparator(.hidden)
                                    }
                                    .onMove { from, to in
                                        exercises.move(fromOffsets: from, toOffset: to)
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .environment(\.editMode, .constant(.active))
                                .frame(minHeight: CGFloat(exercises.count * 52))
                                .background(.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        // Delete button (for existing workouts)
                        if isEditing {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                Text("Delete Workout")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(.red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.top, 16)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(isEditing ? "Edit Workout" : "New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .foregroundStyle(isValid ? .white : .white.opacity(0.4))
                    .disabled(!isValid)
                }
            }
            .alert("Delete Workout?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let workout = workout {
                        onDelete?(workout)
                    }
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addExercise() {
        let trimmed = newExercise.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        exercises.append(ExerciseItem(name: trimmed))
        newExercise = ""
    }

    private func saveWorkout() {
        let savedWorkout = Workout(
            id: workout?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            workTime: workTime,
            restTime: restTime,
            exercises: exercises.map { $0.name }
        )
        onSave(savedWorkout)
        dismiss()
    }
}

// Identifiable wrapper for exercises to support drag-and-drop
struct ExerciseItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
}

struct EditorSettingRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if value > range.lowerBound {
                        value -= 5
                        value = max(value, range.lowerBound)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())

                Text("\(value) \(unit)")
                    .font(.system(size: 14, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 70)

                Button {
                    if value < range.upperBound {
                        value += 5
                        value = min(value, range.upperBound)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

struct ExerciseRow: View {
    let index: Int
    let name: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 14, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 24)

            Text(name)
                .font(.system(size: 16))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

#Preview {
    WorkoutEditorView(
        workout: .sampleUpperBody,
        onSave: { _ in },
        onDelete: { _ in }
    )
}
