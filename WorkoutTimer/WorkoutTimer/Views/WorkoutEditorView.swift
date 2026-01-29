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

    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isExerciseFieldFocused: Bool

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
                // Background
                AnimatedPhaseBackground(phase: .ready, isRunning: false)

                ScrollView {
                    VStack(spacing: 24) {
                        // Name field
                        nameSection

                        // Time settings
                        timeSettingsSection

                        // Exercises
                        exercisesSection

                        // Delete button (for existing workouts)
                        if isEditing {
                            deleteButton
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
                        HapticManager.shared.success()
                        saveWorkout()
                    }
                    .font(.system(size: 17, weight: .semibold))
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

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Name")
                .font(Typography.settingLabel)
                .foregroundStyle(.white.opacity(0.7))

            TextField("e.g. Upper Body", text: $name)
                .font(Typography.listItem)
                .foregroundStyle(.white)
                .padding(14)
                .glassBackground(cornerRadius: 12)
                .focused($isNameFieldFocused)
        }
    }

    private var timeSettingsSection: some View {
        VStack(spacing: 14) {
            GlassSettingRow(
                icon: "flame.fill",
                iconColor: .orange,
                label: "Work Time",
                value: $workTime,
                range: 5...300,
                unit: "sec"
            )

            GlassSettingRow(
                icon: "pause.fill",
                iconColor: .blue,
                label: "Rest Time",
                value: $restTime,
                range: 5...300,
                unit: "sec"
            )
        }
        .padding(16)
        .glassBackground(cornerRadius: 16)
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercises")
                    .font(Typography.settingLabel)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text("\(exercises.count)")
                    .font(Typography.settingValue)
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Add new exercise
            HStack(spacing: 10) {
                TextField("Add exercise", text: $newExercise)
                    .font(Typography.listItem)
                    .foregroundStyle(.white)
                    .padding(14)
                    .glassBackground(cornerRadius: 12)
                    .focused($isExerciseFieldFocused)
                    .onSubmit {
                        addExercise()
                    }

                Button {
                    addExercise()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .glassCircle(prominent: true)
                }
                .buttonStyle(IconGlassButtonStyle())
                .disabled(newExercise.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newExercise.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
            }

            // Exercise list with drag and drop
            if !exercises.isEmpty {
                List {
                    ForEach(exercises) { exercise in
                        DraggableExerciseRow(
                            index: (exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0) + 1,
                            name: exercise.name,
                            onDelete: {
                                withAnimation(AnimationConstants.subtle) {
                                    exercises.removeAll { $0.id == exercise.id }
                                }
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                        HapticManager.shared.buttonTap()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                .frame(minHeight: CGFloat(exercises.count * 52))
                .glassBackground(cornerRadius: 12)
            }
        }
    }

    private var deleteButton: some View {
        Button {
            HapticManager.shared.warning()
            showingDeleteConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .medium))
                Text("Delete Workout")
                    .font(Typography.button)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(GlassButtonStyle())
        .padding(.top, 16)
    }

    // MARK: - Actions

    private func addExercise() {
        let trimmed = newExercise.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        withAnimation(AnimationConstants.subtle) {
            exercises.append(ExerciseItem(name: trimmed))
        }
        newExercise = ""
        HapticManager.shared.buttonTap()
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

// MARK: - Supporting Types

struct ExerciseItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
}

// MARK: - Draggable Exercise Row (for List with drag-and-drop)

struct DraggableExerciseRow: View {
    let index: Int
    let name: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Index badge
            Text("\(index)")
                .font(Typography.cardSubtitle.monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 24)

            // Exercise name
            Text(name)
                .font(Typography.listItem)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Delete button
            Button {
                HapticManager.shared.buttonTap()
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Glass Exercise Row (standalone, with optional reorder buttons)

struct GlassExerciseRow: View {
    let index: Int
    let name: String
    let onDelete: () -> Void
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Index badge
            Text("\(index)")
                .font(Typography.cardSubtitle.monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 28, height: 28)
                .glassCircle()

            // Exercise name
            Text(name)
                .font(Typography.listItem)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Delete button
            Button {
                HapticManager.shared.buttonTap()
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Legacy Components (kept for compatibility)

struct EditorSettingRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        GlassSettingRow(
            icon: iconForLabel,
            iconColor: colorForLabel,
            label: label,
            value: $value,
            range: range,
            unit: unit,
            step: 5
        )
    }

    private var iconForLabel: String {
        switch label.lowercased() {
        case "work time": return "flame.fill"
        case "rest time": return "pause.fill"
        default: return "circle"
        }
    }

    private var colorForLabel: Color {
        switch label.lowercased() {
        case "work time": return .orange
        case "rest time": return .blue
        default: return .white
        }
    }
}

struct ExerciseRow: View {
    let index: Int
    let name: String
    let onDelete: () -> Void

    var body: some View {
        GlassExerciseRow(
            index: index,
            name: name,
            onDelete: onDelete
        )
    }
}

// MARK: - Previews

#Preview("New") {
    WorkoutEditorView(
        workout: nil,
        onSave: { _ in },
        onDelete: nil
    )
}

#Preview("Edit") {
    WorkoutEditorView(
        workout: .sampleUpperBody,
        onSave: { _ in },
        onDelete: { _ in }
    )
}
