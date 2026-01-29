import SwiftUI

enum TimerMode: String, CaseIterable {
    case timer = "Timer"
    case workouts = "Workouts"
}

struct SettingsCard: View {
    @Binding var selectedWorkout: Workout?
    @Binding var workTime: Int
    @Binding var restTime: Int
    @Binding var rounds: Int
    let workouts: [Workout]
    let onManageWorkouts: () -> Void
    let onCreateWorkout: () -> Void

    @State private var mode: TimerMode = .timer

    var body: some View {
        VStack(spacing: 16) {
            // Mode tabs
            HStack(spacing: 0) {
                ForEach(TimerMode.allCases, id: \.self) { tabMode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            mode = tabMode
                            if tabMode == .timer {
                                // Clear workout selection when switching to timer mode
                                selectedWorkout = nil
                            } else if tabMode == .workouts && !workouts.isEmpty {
                                // Auto-select first workout when switching to workouts mode
                                if selectedWorkout == nil {
                                    selectedWorkout = workouts.first
                                }
                            }
                        }
                    } label: {
                        Text(tabMode.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(mode == tabMode ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(mode == tabMode ? .white.opacity(0.2) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Content based on mode
            if mode == .timer {
                timerModeContent
            } else {
                workoutsModeContent
            }
        }
        .padding(20)
        .background(.white.opacity(0.1))
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
        .onAppear {
            // Set initial mode based on whether a workout is selected
            if selectedWorkout != nil {
                mode = .workouts
            }
        }
    }

    // Fixed height for content area to prevent layout shift
    private let contentHeight: CGFloat = 180

    // MARK: - Timer Mode Content
    private var timerModeContent: some View {
        VStack(spacing: 16) {
            SettingRow(
                label: "Work",
                value: $workTime,
                range: 5...300,
                unit: "sec"
            )

            SettingRow(
                label: "Rest",
                value: $restTime,
                range: 5...300,
                unit: "sec"
            )

            SettingRow(
                label: "Rounds",
                value: $rounds,
                range: 1...50,
                unit: ""
            )
        }
        .frame(height: contentHeight)
    }

    // MARK: - Workouts Mode Content
    private var workoutsModeContent: some View {
        VStack(spacing: 12) {
            if workouts.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Spacer()
                    Text("No workouts yet")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.6))

                    Button {
                        onCreateWorkout()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("Create Workout")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                }
            } else {
                // Workout list with wheel picker
                Picker("Workout", selection: workoutSelectionBinding) {
                    ForEach(workouts) { workout in
                        Text(workout.name)
                            .tag(workout.id.uuidString)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onAppear {
                    // Auto-select first workout if none selected
                    if selectedWorkout == nil, let first = workouts.first {
                        selectedWorkout = first
                    }
                }

                // Manage workouts button
                Button {
                    onManageWorkouts()
                } label: {
                    Text("Manage Workouts")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(height: contentHeight)
    }

    private var workoutSelectionBinding: Binding<String> {
        Binding(
            get: {
                selectedWorkout?.id.uuidString ?? workouts.first?.id.uuidString ?? ""
            },
            set: { newValue in
                if let workout = workouts.first(where: { $0.id.uuidString == newValue }) {
                    selectedWorkout = workout
                }
            }
        )
    }
}

struct SettingRow: View {
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
                        value -= (label == "Rounds" ? 1 : 5)
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

                Text("\(value)\(unit.isEmpty ? "" : " \(unit)")")
                    .font(.system(size: 14, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 70)

                Button {
                    if value < range.upperBound {
                        value += (label == "Rounds" ? 1 : 5)
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
            onCreateWorkout: {}
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
            onCreateWorkout: {}
        )
    }
}
