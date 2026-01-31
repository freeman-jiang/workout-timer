import SwiftUI
import Combine

struct TimerView: View {
    @State private var timerState = TimerState()
    @State private var audioManager = AudioManager()
    @State private var workouts: [Workout] = []
    @State private var showingWorkoutsList = false
    @State private var timerSubscription: AnyCancellable?
    @State private var isOnWorkoutsTabWithNoWorkouts = false

    // Celebration state
    @State private var showingWorkoutComplete = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background that transitions with phase
                AnimatedPhaseBackground(
                    phase: timerState.currentPhase,
                    isRunning: timerState.isRunning
                )

                // Main content
                VStack(spacing: 0) {
                    // Timer section - fixed position from top
                    VStack(spacing: 0) {
                        // Phase label
                        PhaseLabel(
                            phase: timerState.currentPhase,
                            isWorkoutMode: timerState.selectedWorkout != nil
                        )
                            .padding(.bottom, 8)
                            .animation(
                                reduceMotion ? nil : AnimationConstants.phaseTransition,
                                value: timerState.currentPhase
                            )

                        // Exercise name or workout name
                        if timerState.currentPhase == .ready,
                           let workoutName = timerState.selectedWorkout?.name {
                            // Show workout name before starting
                            Text(workoutName)
                                .font(Typography.exercise)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                                .transition(.opacity)
                        } else if timerState.currentPhase == .warmup,
                                  let firstExercise = timerState.currentExerciseName {
                            // During warmup, show the first exercise coming up
                            Text(firstExercise)
                                .font(Typography.exercise)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                                .transition(.opacity)
                        } else if timerState.currentPhase == .rest,
                                  let nextExercise = timerState.nextExerciseName {
                            // During rest, show the upcoming exercise
                            Text(nextExercise)
                                .font(Typography.exercise)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                                .transition(.opacity)
                        } else if timerState.currentPhase == .work,
                                  let exerciseName = timerState.currentExerciseName {
                            // During work, show current exercise
                            Text(exerciseName)
                                .font(Typography.exercise)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                                .transition(.opacity)
                        }

                        // Timer display
                        TimerDisplay(time: displayTime)
                            .padding(.bottom, 8)

                        // Round info
                        Text(timerState.roundInfoText)
                            .font(Typography.roundInfo)
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.bottom, 4)
                            .contentTransition(.numericText())
                            .animation(
                                reduceMotion ? nil : AnimationConstants.numeric,
                                value: timerState.currentRound
                            )
                    }
                    .padding(.top, timerState.currentPhase == .ready ? 60 : 100)

                    Spacer()

                    // Control buttons
                    ControlButtons(
                        buttonText: timerState.buttonText,
                        isWorkoutActive: timerState.isRunning || timerState.isPaused,
                        isStartDisabled: isStartDisabled,
                        onStartPause: {
                            timerState.startOrToggle()
                            updateNowPlaying()
                        },
                        onReset: {
                            timerState.reset()
                            updateNowPlaying()
                        }
                    )
                    .padding(.bottom, 24)

                    // Settings card (hidden when running)
                    if !timerState.isRunning && timerState.currentPhase == .ready {
                        SettingsCard(
                            selectedWorkout: Binding(
                                get: { timerState.selectedWorkout },
                                set: { timerState.selectedWorkout = $0 }
                            ),
                            workTime: Binding(
                                get: { timerState.quickWorkTime },
                                set: {
                                    timerState.quickWorkTime = $0
                                    saveQuickSettings()
                                }
                            ),
                            restTime: Binding(
                                get: { timerState.quickRestTime },
                                set: {
                                    timerState.quickRestTime = $0
                                    saveQuickSettings()
                                }
                            ),
                            rounds: Binding(
                                get: { timerState.quickRounds },
                                set: {
                                    timerState.quickRounds = $0
                                    saveQuickSettings()
                                }
                            ),
                            workouts: workouts,
                            onManageWorkouts: {
                                showingWorkoutsList = true
                            },
                            onCreateWorkout: {
                                // Not used - create workout flows through WorkoutsListView
                            },
                            isOnWorkoutsTabWithNoWorkouts: $isOnWorkoutsTabWithNoWorkouts
                        )
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            )
                        )
                        .padding(.bottom, 24)
                    }
                }
                .animation(
                    reduceMotion ? nil : AnimationConstants.appear,
                    value: timerState.isRunning
                )

                // Workout complete overlay
                if showingWorkoutComplete {
                    WorkoutCompleteOverlay(
                        totalRounds: timerState.totalRounds,
                        workTime: timerState.workTime,
                        restTime: timerState.restTime,
                        onDismiss: {
                            withAnimation(AnimationConstants.disappear) {
                                showingWorkoutComplete = false
                            }
                            timerState.reset()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .navigationDestination(isPresented: $showingWorkoutsList) {
                WorkoutsListView(workouts: $workouts)
            }
        }
        .tint(.white)
        .preferredColorScheme(.dark)
        .onAppear {
            setupTimer()
            loadData()
            setupNowPlaying()
        }
        .onDisappear {
            timerSubscription?.cancel()
        }
        .onChange(of: workouts) { _, newWorkouts in
            // Sync selected workout with updated workouts array
            if let selected = timerState.selectedWorkout,
               let updated = newWorkouts.first(where: { $0.id == selected.id }) {
                timerState.selectedWorkout = updated
            }
        }
    }

    // MARK: - Computed Properties

    private var displayTime: String {
        switch timerState.currentPhase {
        case .ready:
            return timerState.formattedTotalDurationTimer
        case .complete:
            return "0:00"
        default:
            return timerState.formattedTimeRemaining
        }
    }

    /// Start button should be disabled if on workouts tab with no workouts,
    /// or if selected workout doesn't exist
    private var isStartDisabled: Bool {
        // On workouts tab with no workouts = disabled
        if isOnWorkoutsTabWithNoWorkouts {
            return true
        }
        // If a workout is selected but doesn't exist in the list, disable
        if let selected = timerState.selectedWorkout {
            return !workouts.contains(where: { $0.id == selected.id })
        }
        // Timer mode is always valid
        return false
    }

    // MARK: - Setup

    private func setupTimer() {
        // Setup callbacks for audio and haptics
        timerState.onCountdownBeep = { [audioManager] in
            audioManager.playCountdownBeep()
            HapticManager.shared.countdownBeep()
        }

        timerState.onPhaseTransition = { [audioManager] (phase: TimerPhase) in
            switch phase {
            case .work:
                // Warmup -> Work: high pitch (start of race)
                audioManager.playWorkStart()
            case .rest:
                // Work -> Rest: low pitch
                audioManager.playRestStart()
            default:
                break
            }
            HapticManager.shared.phaseTransition()
            updateNowPlaying()
        }

        timerState.onRestStart = { [audioManager] in
            // Rest -> Work: high pitch (start of race)
            audioManager.playWorkStart()
            HapticManager.shared.phaseTransition()
            updateNowPlaying()
        }

        timerState.onWorkoutComplete = { [audioManager] in
            audioManager.playWorkoutComplete()
            HapticManager.shared.celebration()

            // Show celebration overlay
            withAnimation(AnimationConstants.celebratory) {
                showingWorkoutComplete = true
            }

            updateNowPlaying()
        }

        timerState.onTimerStart = { [audioManager] in
            audioManager.startBackgroundAudio()
        }

        timerState.onTimerStop = { [audioManager] in
            audioManager.stopBackgroundAudio()
        }

        // Start the tick timer (100ms interval)
        timerSubscription = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                timerState.tick()
            }
    }

    private func loadData() {
        var loadedWorkouts = WorkoutStorage.shared.loadWorkouts()

        // Clean up invalid workouts (empty name or no exercises) on startup
        let validCount = loadedWorkouts.count
        loadedWorkouts.removeAll { workout in
            workout.name.trimmingCharacters(in: .whitespaces).isEmpty || workout.exercises.isEmpty
        }
        if loadedWorkouts.count != validCount {
            WorkoutStorage.shared.saveWorkouts(loadedWorkouts)
        }

        workouts = loadedWorkouts
        let quickSettings = WorkoutStorage.shared.loadQuickSettings()
        timerState.quickWorkTime = quickSettings.workTime
        timerState.quickRestTime = quickSettings.restTime
        timerState.quickRounds = quickSettings.rounds
    }

    private func saveQuickSettings() {
        let settings = WorkoutStorage.QuickSettings(
            workTime: timerState.quickWorkTime,
            restTime: timerState.quickRestTime,
            rounds: timerState.quickRounds
        )
        WorkoutStorage.shared.saveQuickSettings(settings)
    }

    private func setupNowPlaying() {
        NowPlayingManager.shared.configure(timerState: timerState) { [timerState] in
            timerState.startOrToggle()
        }
    }

    private func updateNowPlaying() {
        NowPlayingManager.shared.updateNowPlayingInfo()
    }
}

#Preview {
    TimerView()
}
