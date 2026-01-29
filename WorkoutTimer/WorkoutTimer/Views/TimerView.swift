import SwiftUI
import Combine

struct TimerView: View {
    @State private var timerState = TimerState()
    @State private var audioManager = AudioManager()
    @State private var workouts: [Workout] = []
    @State private var showingWorkoutsList = false
    @State private var showingNewWorkout = false
    @State private var timerSubscription: AnyCancellable?

    // Celebration state
    @State private var showingWorkoutComplete = false
    @State private var showingRoundBadge = false
    @State private var completedRound = 0

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
                    Spacer()

                    // Phase label
                    PhaseLabel(phase: timerState.currentPhase)
                        .padding(.bottom, 8)
                        .animation(
                            reduceMotion ? nil : AnimationConstants.phaseTransition,
                            value: timerState.currentPhase
                        )

                    // Exercise name or workout name (if custom workout)
                    if timerState.currentPhase == .ready,
                       let workoutName = timerState.selectedWorkout?.name {
                        // Show workout name before starting
                        Text(workoutName)
                            .font(Typography.exercise)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    } else if let exerciseName = timerState.currentExerciseName,
                              timerState.currentPhase != .complete {
                        // Show current exercise name during workout
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

                    // Next exercise (during rest phase only)
                    if timerState.currentPhase == .rest,
                       let nextExercise = timerState.nextExerciseName {
                        Text("Next: \(nextExercise)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    }

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
                                showingNewWorkout = true
                            }
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

                // Round complete badge overlay (top of screen, no layout shift)
                VStack {
                    RoundCompleteBadge(
                        roundNumber: completedRound,
                        totalRounds: timerState.totalRounds
                    )
                    .padding(.top, 16)

                    Spacer()
                }
                .opacity(showingRoundBadge ? 1 : 0)
                .offset(y: showingRoundBadge ? 0 : -20)
                .animation(.easeOut(duration: 0.3), value: showingRoundBadge)
                .allowsHitTesting(false)
                .onChange(of: showingRoundBadge) { _, isShowing in
                    if isShowing {
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            showingRoundBadge = false
                        }
                    }
                }

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
            .sheet(isPresented: $showingNewWorkout) {
                WorkoutEditorView(
                    workout: nil,
                    onSave: { workout in
                        workouts.append(workout)
                        WorkoutStorage.shared.saveWorkouts(workouts)
                        timerState.selectedWorkout = workout
                    },
                    onDelete: nil
                )
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

    /// Start button should be disabled if on workouts mode but no valid workout is selected
    private var isStartDisabled: Bool {
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

        timerState.onPhaseTransition = { [audioManager] phase in
            audioManager.playPhaseTransition()
            HapticManager.shared.phaseTransition()
            updateNowPlaying()

            // Show round badge when entering rest phase
            if phase == .rest {
                showRoundCompleteBadge()
            }
        }

        timerState.onRestStart = { [audioManager] in
            audioManager.playRestStart()
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

    private func showRoundCompleteBadge() {
        completedRound = timerState.currentRound
        showingRoundBadge = true
    }

    private func loadData() {
        workouts = WorkoutStorage.shared.loadWorkouts()
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
