import SwiftUI

// MARK: - Save Status

enum SaveStatus: Equatable {
    case idle
    case saving
    case saved
}

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss

    /// Binding to the workout being edited (for existing workouts)
    @Binding var workout: Workout

    /// Called when the workout should be deleted
    let onDelete: ((Workout) -> Void)?

    /// Called when a new workout should be saved (only used for new workouts)
    let onSave: ((Workout) -> Void)?

    /// Whether this is a new workout that hasn't been persisted yet
    let isNewWorkout: Bool

    @State private var name: String
    @State private var workTime: Int
    @State private var restTime: Int
    @State private var exercises: [ExerciseItem]
    @State private var newExercise: String = ""
    @State private var showingDeleteConfirmation = false
    @State private var saveStatus: SaveStatus = .idle
    @State private var saveTask: Task<Void, Never>?
    @State private var hasBeenValidOnce = false
    @State private var needsSave = false

    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isExerciseFieldFocused: Bool

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !exercises.isEmpty
    }

    init(
        workout: Binding<Workout>,
        isNewWorkout: Bool = false,
        onDelete: ((Workout) -> Void)?,
        onSave: ((Workout) -> Void)? = nil
    ) {
        self._workout = workout
        self.isNewWorkout = isNewWorkout
        self.onDelete = onDelete
        self.onSave = onSave
        _name = State(initialValue: workout.wrappedValue.name)
        _workTime = State(initialValue: workout.wrappedValue.workTime)
        _restTime = State(initialValue: workout.wrappedValue.restTime)
        _exercises = State(initialValue: workout.wrappedValue.exercises.map { ExerciseItem(name: $0) })
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
                        if !isNewWorkout {
                            deleteButton
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(isNewWorkout ? "New Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    saveStatusIndicator
                }
            }
            .alert("Delete Workout?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete?(workout)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Auto-focus name field for new workouts
            if isNewWorkout {
                try? await Task.sleep(for: .seconds(0.5))
                isNameFieldFocused = true
            }
        }
        .onChange(of: name) { _, _ in needsSave = true }
        .onChange(of: workTime) { _, _ in needsSave = true }
        .onChange(of: restTime) { _, _ in needsSave = true }
        .onChange(of: exercises) { _, _ in needsSave = true }
        .onChange(of: needsSave) { _, shouldSave in
            if shouldSave {
                needsSave = false
                scheduleAutoSave()
            }
        }
        .onDisappear {
            saveTask?.cancel()
            // If new workout was never valid, it will be cleaned up by the parent
        }
    }

    // MARK: - Save Status Indicator

    @ViewBuilder
    private var saveStatusIndicator: some View {
        switch saveStatus {
        case .idle:
            EmptyView()
        case .saving:
            HStack(spacing: 6) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                    .scaleEffect(0.7)
                Text("Saving")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        case .saved:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                Text("Saved")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.green.opacity(0.8))
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
                icon: "figure.run",
                iconColor: .orange,
                label: "Work Time",
                value: $workTime,
                range: 5...300,
                unit: "sec"
            )

            GlassSettingRow(
                icon: "moon.fill",
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
                .accessibilityLabel("Add exercise")
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

    // MARK: - Auto-Save

    private func scheduleAutoSave() {
        // For new workouts, don't save until valid
        guard isValid else {
            // If it was valid before and now isn't, we still keep the binding updated
            // but don't persist to storage (validation prevents empty name/no exercises)
            if hasBeenValidOnce {
                updateBinding()
            }
            return
        }

        // Mark that this workout has been valid at least once
        let isFirstValidSave = !hasBeenValidOnce
        if !hasBeenValidOnce {
            hasBeenValidOnce = true
        }

        saveTask?.cancel()
        saveStatus = .saving

        saveTask = Task {
            // Debounce: wait 500ms after last change
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            // Update the binding (which updates the parent's array)
            await MainActor.run {
                updateBinding()

                // For new workouts, call onSave to add to the list
                if isNewWorkout && isFirstValidSave, let onSave = onSave {
                    onSave(workout)
                } else if !isNewWorkout {
                    // Persist to storage for existing workouts
                    WorkoutStorage.shared.updateWorkout(workout)
                }
                saveStatus = .saved
            }

            // Fade out the "Saved" indicator after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                if saveStatus == .saved {
                    withAnimation(.easeOut(duration: 0.3)) {
                        saveStatus = .idle
                    }
                }
            }
        }
    }

    private func updateBinding() {
        workout.name = name.trimmingCharacters(in: .whitespaces)
        workout.workTime = workTime
        workout.restTime = restTime
        workout.exercises = exercises.map { $0.name }
    }
}

// MARK: - Supporting Types

struct ExerciseItem: Identifiable, Equatable {
    let id: UUID
    var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }

    static func == (lhs: ExerciseItem, rhs: ExerciseItem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

// MARK: - Exercise List View (Gesture-based drag reordering)

struct ExerciseListView: View {
    @Binding var exercises: [ExerciseItem]
    let onDelete: (IndexSet) -> Void
    let onMove: (IndexSet, Int) -> Void

    @State private var draggingItem: ExerciseItem?
    @State private var draggingIndex: Int?  // Cached drag index to avoid O(n) lookups
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
                    name: $exercises[index].name,
                    isDragging: isBeingDragged,
                    onDelete: {
                        withAnimation(AnimationConstants.subtle) {
                            exercises.removeAll { $0.id == exercise.id }
                        }
                        HapticManager.shared.buttonTap()
                    },
                    onMoveUp: {
                        guard index > 0 else { return }
                        withAnimation(AnimationConstants.subtle) {
                            exercises.move(fromOffsets: IndexSet(integer: index), toOffset: index - 1)
                        }
                        HapticManager.shared.buttonTap()
                    },
                    onMoveDown: {
                        guard index < exercises.count - 1 else { return }
                        withAnimation(AnimationConstants.subtle) {
                            exercises.move(fromOffsets: IndexSet(integer: index), toOffset: index + 2)
                        }
                        HapticManager.shared.buttonTap()
                    },
                    isFirst: index == 0,
                    isLast: index == exercises.count - 1
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
                                        draggingIndex = index
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
        guard let dragIndex = draggingIndex,
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
        guard let dragIndex = draggingIndex,
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
        guard let fromIndex = draggingIndex,
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
            draggingIndex = nil
            dragOffset = 0
            currentTargetIndex = nil
        }
    }
}

// MARK: - Exercise Row Content

struct ExerciseRowContent: View {
    let index: Int
    @Binding var name: String
    var isDragging: Bool = false
    let onDelete: () -> Void
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var isFirst: Bool = false
    var isLast: Bool = false

    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(isDragging ? 0.6 : 0.35))
                .frame(width: 36, height: 56)
                .contentShape(Rectangle())
                .accessibilityHidden(true)

            // Index badge
            Text("\(index)")
                .font(Typography.cardSubtitle.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 24)
                .accessibilityHidden(true)

            // Exercise name - tappable to edit
            if isEditing {
                TextField("Exercise name", text: $name)
                    .font(Typography.listItem)
                    .foregroundStyle(.white)
                    .focused($isFocused)
                    .onSubmit {
                        isEditing = false
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            isEditing = false
                        }
                    }
            } else {
                Text(name)
                    .font(Typography.listItem)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEditing = true
                        isFocused = true
                    }
            }

            Spacer(minLength: 0)

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
            .accessibilityLabel("Delete \(name)")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exercise \(index), \(name)")
        .accessibilityHint("Tap to edit, long press and drag to reorder")
        .accessibilityActions {
            if let onMoveUp = onMoveUp, !isFirst {
                Button("Move Up") {
                    onMoveUp()
                }
            }
            if let onMoveDown = onMoveDown, !isLast {
                Button("Move Down") {
                    onMoveDown()
                }
            }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Previews

#Preview("New") {
    WorkoutEditorView(
        workout: .constant(Workout(name: "", exercises: [])),
        isNewWorkout: true,
        onDelete: nil
    )
}

#Preview("Edit") {
    WorkoutEditorView(
        workout: .constant(.sampleUpperBody),
        isNewWorkout: false,
        onDelete: { _ in }
    )
}
