import SwiftUI

enum TimerMode: String, CaseIterable {
    case timer = "Timer"
    case workouts = "Workouts"

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .workouts: return "dumbbell"
        }
    }
}

struct SettingsCard: View {
    @Binding var selectedWorkout: Workout?
    @Binding var workTime: Int
    @Binding var restTime: Int
    @Binding var rounds: Int
    let workouts: [Workout]
    let onManageWorkouts: () -> Void
    let onCreateWorkout: () -> Void
    @Binding var isOnWorkoutsTabWithNoWorkouts: Bool

    @State private var mode: TimerMode = .timer
    @Namespace private var tabNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var validWorkouts: [Workout] {
        workouts.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty && !$0.exercises.isEmpty }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Mode tabs with glass morphing
            tabSelector

            // Content based on mode
            Group {
                if mode == .timer {
                    timerModeContent
                } else {
                    workoutsModeContent
                }
            }
            .animation(
                reduceMotion ? nil : AnimationConstants.glassResize,
                value: mode
            )
        }
        .padding(20)
        .glassBackground(cornerRadius: 24)
        .padding(.horizontal, 24)
        .onAppear {
            // Set initial mode based on whether a workout is selected
            if selectedWorkout != nil {
                mode = .workouts
            }
            updateIsOnWorkoutsTabWithNoWorkouts()
        }
        .onChange(of: mode) { _, _ in
            updateIsOnWorkoutsTabWithNoWorkouts()
        }
        .onChange(of: workouts) { _, _ in
            // Auto-switch to timer mode if valid workouts become empty
            if validWorkouts.isEmpty && mode == .workouts {
                withAnimation(AnimationConstants.glassMorph) {
                    mode = .timer
                    selectedWorkout = nil
                }
            }
            // Clear selected workout if it no longer exists in valid workouts
            if let selected = selectedWorkout,
               !validWorkouts.contains(where: { $0.id == selected.id }) {
                if let first = validWorkouts.first {
                    selectedWorkout = first
                } else {
                    withAnimation(AnimationConstants.glassMorph) {
                        mode = .timer
                        selectedWorkout = nil
                    }
                }
            }
            updateIsOnWorkoutsTabWithNoWorkouts()
        }
    }

    private func updateIsOnWorkoutsTabWithNoWorkouts() {
        isOnWorkoutsTabWithNoWorkouts = mode == .workouts && validWorkouts.isEmpty
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(TimerMode.allCases, id: \.self) { tabMode in
                Button {
                    withAnimation(AnimationConstants.glassMorph) {
                        mode = tabMode
                        if tabMode == .timer {
                            selectedWorkout = nil
                        } else if tabMode == .workouts && !validWorkouts.isEmpty {
                            if selectedWorkout == nil {
                                selectedWorkout = validWorkouts.first
                            }
                        }
                    }
                    HapticManager.shared.buttonTap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tabMode.icon)
                            .font(.system(size: 13, weight: .medium))
                            .accessibilityHidden(true)

                        Text(tabMode.rawValue)
                            .font(Typography.tabLabel)
                    }
                    .foregroundStyle(mode == tabMode ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background {
                        if mode == tabMode {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.2))
                                .matchedGeometryEffect(id: "tab", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(tabMode.rawValue) mode")
                .accessibilityAddTraits(mode == tabMode ? .isSelected : [])
            }
        }
        .padding(4)
        .glassBackground(cornerRadius: 12)
    }

    // Fixed height for content area to prevent layout shift
    private let contentHeight: CGFloat = 180

    // MARK: - Timer Mode Content

    private var timerModeContent: some View {
        VStack(spacing: 14) {
            GlassSettingRow(
                icon: "figure.run",
                iconColor: .orange,
                label: "Work",
                value: $workTime,
                range: 5...300,
                unit: "sec"
            )

            GlassSettingRow(
                icon: "moon.fill",
                iconColor: .blue,
                label: "Rest",
                value: $restTime,
                range: 5...300,
                unit: "sec"
            )

            GlassSettingRow(
                icon: "repeat",
                iconColor: .purple,
                label: "Rounds",
                value: $rounds,
                range: 1...50,
                unit: "",
                step: 1
            )
        }
        .frame(height: contentHeight)
    }

    // MARK: - Workouts Mode Content

    private var workoutsModeContent: some View {
        VStack(spacing: 12) {
            if validWorkouts.isEmpty {
                emptyWorkoutsState
            } else {
                workoutPicker
            }
        }
        .frame(height: contentHeight)
    }

    private var emptyWorkoutsState: some View {
        VStack(spacing: 12) {
            Spacer()

            Text("No workouts yet")
                .font(Typography.settingLabel)
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            manageWorkoutsButton
        }
    }

    private var workoutPicker: some View {
        VStack(spacing: 12) {
            Picker("Workout", selection: workoutSelectionBinding) {
                ForEach(validWorkouts) { workout in
                    Text(workout.name)
                        .tag(workout.id.uuidString)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .clipShape(.rect(cornerRadius: 12))
            .onAppear {
                if selectedWorkout == nil, let first = validWorkouts.first {
                    selectedWorkout = first
                }
            }

            manageWorkoutsButton
        }
    }

    private var manageWorkoutsButton: some View {
        Button {
            HapticManager.shared.buttonTap()
            onManageWorkouts()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                Text("Manage Workouts")
                    .font(Typography.buttonSmall)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .glassBackground(cornerRadius: 10)
        }
        .buttonStyle(GlassButtonStyle())
    }

    private var workoutSelectionBinding: Binding<String> {
        Binding(
            get: {
                selectedWorkout?.id.uuidString ?? validWorkouts.first?.id.uuidString ?? ""
            },
            set: { newValue in
                if let workout = validWorkouts.first(where: { $0.id.uuidString == newValue }) {
                    selectedWorkout = workout
                }
            }
        )
    }
}

// MARK: - Glass Setting Row

struct GlassSettingRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    var step: Int = 5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .glassCircle()
                .accessibilityHidden(true)

            // Label
            Text(label)
                .font(Typography.settingLabel)
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            // Stepper controls
            HStack(spacing: 8) {
                // Minus button
                Button {
                    if value > range.lowerBound {
                        value -= step
                        value = max(value, range.lowerBound)
                        HapticManager.shared.buttonTap()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .glassCircle()
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
                .buttonStyle(IconGlassButtonStyle())
                .disabled(value <= range.lowerBound)
                .opacity(value <= range.lowerBound ? 0.4 : 1.0)
                .accessibilityLabel("Decrease \(label)")

                // Value
                Text(formattedValue)
                    .font(Typography.settingValue.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(minWidth: 56)
                    .contentTransition(.numericText())
                    .animation(
                        reduceMotion ? nil : AnimationConstants.numeric,
                        value: value
                    )
                    .accessibilityHidden(true)

                // Plus button
                Button {
                    if value < range.upperBound {
                        value += step
                        value = min(value, range.upperBound)
                        HapticManager.shared.buttonTap()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .glassCircle()
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
                .buttonStyle(IconGlassButtonStyle())
                .disabled(value >= range.upperBound)
                .opacity(value >= range.upperBound ? 0.4 : 1.0)
                .accessibilityLabel("Increase \(label)")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(label), \(formattedValue)")
        }
    }

    private var formattedValue: String {
        if unit.isEmpty {
            return "\(value)"
        } else if unit == "sec" {
            // Format seconds as m + s if >= 60
            if value >= 60 {
                let minutes = value / 60
                let seconds = value % 60
                if seconds == 0 {
                    return "\(minutes)m"
                }
                return "\(minutes)m \(seconds)s"
            }
            return "\(value)s"
        } else {
            return "\(value) \(unit)"
        }
    }
}

// MARK: - Previews

#Preview("With Workouts") {
    ZStack {
        Color.phaseReady
            .ignoresSafeArea()
        SettingsCard(
            selectedWorkout: .constant(nil),
            workTime: .constant(45),
            restTime: .constant(15),
            rounds: .constant(8),
            workouts: [.sampleUpperBody, .sampleCore],
            onManageWorkouts: {},
            onCreateWorkout: {},
            isOnWorkoutsTabWithNoWorkouts: .constant(false)
        )
    }
}

#Preview("Empty Workouts") {
    ZStack {
        Color.phaseReady
            .ignoresSafeArea()
        SettingsCard(
            selectedWorkout: .constant(nil),
            workTime: .constant(45),
            restTime: .constant(15),
            rounds: .constant(8),
            workouts: [],
            onManageWorkouts: {},
            onCreateWorkout: {},
            isOnWorkoutsTabWithNoWorkouts: .constant(false)
        )
    }
}
