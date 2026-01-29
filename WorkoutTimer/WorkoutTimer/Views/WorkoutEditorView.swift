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
                // Background - tappable to dismiss keyboard
                AnimatedPhaseBackground(phase: .ready, isRunning: false)
                    .onTapGesture {
                        dismissKeyboard()
                    }

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
                .scrollDismissesKeyboard(.interactively)
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
        .onAppear {
            // Auto-focus name field for new workouts
            if !isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFieldFocused = true
                }
            }
        }
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
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .glassBackground(cornerRadius: 12)
                .contentShape(Rectangle())
                .focused($isNameFieldFocused)
                .onSubmit {
                    // Move focus to exercise field after entering name
                    isExerciseFieldFocused = true
                }
        }
    }

    private func dismissKeyboard() {
        isNameFieldFocused = false
        isExerciseFieldFocused = false
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
                    .padding(.horizontal, 16)
                    .frame(minHeight: 52)
                    .glassBackground(cornerRadius: 12)
                    .contentShape(Rectangle())
                    .focused($isExerciseFieldFocused)
                    .onSubmit {
                        addExercise()
                    }

                Button {
                    addExercise()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .glassCircle(prominent: true)
                        .contentShape(Circle())
                }
                .buttonStyle(IconGlassButtonStyle())
                .disabled(newExercise.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newExercise.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
            }

            // Exercise list with native drag and drop
            if !exercises.isEmpty {
                ExerciseListView(
                    exercises: $exercises,
                    onDelete: { indexSet in
                        withAnimation(AnimationConstants.subtle) {
                            exercises.remove(atOffsets: indexSet)
                        }
                    },
                    onMove: { from, to in
                        withAnimation(AnimationConstants.subtle) {
                            exercises.move(fromOffsets: from, toOffset: to)
                        }
                        HapticManager.shared.buttonTap()
                    }
                )
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
            .frame(minHeight: 52)
            .contentShape(Rectangle())
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

        // Keep focus on exercise field for adding multiple exercises
        isExerciseFieldFocused = true
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

// MARK: - Exercise List View (Gesture-based drag reordering)

struct ExerciseListView: View {
    @Binding var exercises: [ExerciseItem]
    let onDelete: (IndexSet) -> Void
    let onMove: (IndexSet, Int) -> Void

    @State private var draggingItem: ExerciseItem?
    @State private var dragOffset: CGFloat = 0
    @State private var currentTargetIndex: Int?
    @GestureState private var isDragging = false

    private let rowHeight: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                let isBeingDragged = draggingItem?.id == exercise.id

                ExerciseRowContent(
                    index: displayIndex(for: index),
                    name: exercise.name,
                    isDragging: isBeingDragged,
                    onDelete: {
                        withAnimation(AnimationConstants.subtle) {
                            exercises.removeAll { $0.id == exercise.id }
                        }
                        HapticManager.shared.buttonTap()
                    }
                )
                .zIndex(isBeingDragged ? 1 : 0)
                .offset(y: isBeingDragged ? dragOffset : offsetForRow(at: index))
                .animation(.snappy(duration: 0.25), value: currentTargetIndex)
                .gesture(
                    LongPressGesture(minimumDuration: 0.15)
                        .sequenced(before: DragGesture())
                        .updating($isDragging) { value, state, _ in
                            if case .second(true, _) = value {
                                state = true
                            }
                        }
                        .onChanged { value in
                            switch value {
                            case .second(true, let drag):
                                if draggingItem == nil {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        draggingItem = exercise
                                        currentTargetIndex = index
                                    }
                                    HapticManager.shared.buttonTap()
                                }
                                if let drag = drag {
                                    dragOffset = drag.translation.height
                                    updateTargetIndex(from: index)
                                }
                            default:
                                break
                            }
                        }
                        .onEnded { value in
                            if case .second(true, _) = value {
                                finishDrag(from: index)
                            }
                        }
                )

                // Separator
                if index < exercises.count - 1 {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.leading, 48)
                        .opacity(isBeingDragged ? 0 : 1)
                }
            }
        }
        .glassBackground(cornerRadius: 12)
        .onChange(of: isDragging) { _, newValue in
            if !newValue && draggingItem != nil {
                // Gesture was cancelled
                resetDrag()
            }
        }
    }

    private func updateTargetIndex(from dragIndex: Int) {
        let newTarget = calculateTargetIndex(for: dragOffset, from: dragIndex)
        if newTarget != currentTargetIndex {
            withAnimation(.snappy(duration: 0.2)) {
                currentTargetIndex = newTarget
            }
            HapticManager.shared.selection()
        }
    }

    private func displayIndex(for arrayIndex: Int) -> Int {
        guard let draggingItem = draggingItem,
              let dragIndex = exercises.firstIndex(where: { $0.id == draggingItem.id }),
              let targetIdx = currentTargetIndex else {
            return arrayIndex + 1
        }

        if arrayIndex == dragIndex {
            return targetIdx + 1
        } else if dragIndex < arrayIndex && arrayIndex <= targetIdx {
            return arrayIndex
        } else if targetIdx <= arrayIndex && arrayIndex < dragIndex {
            return arrayIndex + 2
        }
        return arrayIndex + 1
    }

    private func offsetForRow(at index: Int) -> CGFloat {
        guard let draggingItem = draggingItem,
              let dragIndex = exercises.firstIndex(where: { $0.id == draggingItem.id }),
              let targetIdx = currentTargetIndex else {
            return 0
        }

        if index == dragIndex {
            return 0
        } else if dragIndex < index && index <= targetIdx {
            return -rowHeight
        } else if targetIdx <= index && index < dragIndex {
            return rowHeight
        }
        return 0
    }

    private func calculateTargetIndex(for offset: CGFloat, from startIndex: Int) -> Int {
        let rowsMoved = Int(round(offset / rowHeight))
        let newIndex = startIndex + rowsMoved
        return max(0, min(exercises.count - 1, newIndex))
    }

    private func finishDrag(from originalIndex: Int) {
        guard let draggingItem = draggingItem,
              let fromIndex = exercises.firstIndex(where: { $0.id == draggingItem.id }),
              let toIndex = currentTargetIndex else {
            resetDrag()
            return
        }

        if fromIndex != toIndex {
            withAnimation(.snappy(duration: 0.25)) {
                let item = exercises.remove(at: fromIndex)
                exercises.insert(item, at: toIndex)
            }
            HapticManager.shared.buttonTap()
        }

        resetDrag()
    }

    private func resetDrag() {
        withAnimation(.snappy(duration: 0.25)) {
            draggingItem = nil
            dragOffset = 0
            currentTargetIndex = nil
        }
    }
}

// MARK: - Exercise Row Content

struct ExerciseRowContent: View {
    let index: Int
    let name: String
    var isDragging: Bool = false
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(isDragging ? 0.6 : 0.35))
                .frame(width: 36, height: 56)
                .contentShape(Rectangle())

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

            // Delete button - larger hitbox for accessibility
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(.red.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .padding(.trailing, 8)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDragging ? Color.white.opacity(0.1) : Color.clear)
                .padding(.horizontal, 4)
        )
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: 8, y: 4)
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

            // Delete button - larger hitbox for accessibility
            Button {
                HapticManager.shared.buttonTap()
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(.red.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
