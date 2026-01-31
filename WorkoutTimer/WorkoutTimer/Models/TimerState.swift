import Foundation
import Combine

@Observable
@MainActor
final class TimerState {
    // MARK: - Constants
    private let warmupDuration: TimeInterval = 5.0

    // MARK: - Configuration
    var selectedWorkout: Workout?
    var quickWorkTime: Int = 45
    var quickRestTime: Int = 15
    var quickRounds: Int = 10

    // MARK: - Timer State
    private(set) var currentPhase: TimerPhase = .ready
    private(set) var currentRound: Int = 1
    private(set) var isRunning: Bool = false
    private(set) var isPaused: Bool = false

    // MARK: - Timing (timestamp-based for accuracy)
    private var phaseStartTime: Date?
    private var phaseDuration: TimeInterval = 0
    private var pausedTimeRemaining: TimeInterval = 0

    // MARK: - Callbacks for audio/haptics
    var onCountdownBeep: (() -> Void)?
    var onPhaseTransition: ((TimerPhase) -> Void)?
    var onRestStart: (() -> Void)?
    var onWorkoutComplete: (() -> Void)?
    var onTimerStart: (() -> Void)?
    var onTimerStop: (() -> Void)?

    /// Called when a phase starts to schedule countdown beeps and transition sound
    /// Parameters: (phaseDuration, nextPhase where .work means high pitch, .rest means low pitch, playTransitionNow)
    var onScheduleAudio: ((TimeInterval, TimerPhase, Bool) -> Void)?
    /// Called when timer is paused/reset to cancel scheduled audio
    var onCancelScheduledAudio: (() -> Void)?

    // MARK: - Beep tracking
    private var lastBeepedSecond: Int = -1

    // MARK: - Display Time (updated on each tick to trigger UI refresh)
    private(set) var displayTimeRemaining: TimeInterval = 0

    // MARK: - Computed Properties
    var timeRemaining: TimeInterval {
        guard let startTime = phaseStartTime else {
            return phaseDuration > 0 ? phaseDuration : 0
        }
        if isPaused {
            return pausedTimeRemaining
        }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, phaseDuration - elapsed)
    }

    var workTime: Int {
        selectedWorkout?.workTime ?? quickWorkTime
    }

    var restTime: Int {
        selectedWorkout?.restTime ?? quickRestTime
    }

    var totalRounds: Int {
        selectedWorkout?.totalRounds ?? quickRounds
    }

    var currentExerciseName: String? {
        selectedWorkout?.exerciseName(forRound: currentRound)
    }

    var nextExerciseName: String? {
        selectedWorkout?.nextExerciseName(afterRound: currentRound)
    }

    var roundInfoText: String {
        switch currentPhase {
        case .ready:
            return "\(totalRounds) rounds"
        case .warmup:
            return "Starting soon..."
        case .work, .rest:
            return "\(currentRound)/\(totalRounds)"
        case .complete:
            return "Workout complete"
        }
    }

    var totalWorkoutDuration: TimeInterval {
        let workTotal = Double(workTime * totalRounds)
        let restTotal = Double(restTime * totalRounds)
        return workTotal + restTotal
    }

    var formattedTotalDuration: String {
        let totalSeconds = Int(totalWorkoutDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if seconds == 0 {
            return "\(minutes) min"
        } else {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
    }

    /// Total duration formatted in timer style (M:SS)
    var formattedTotalDurationTimer: String {
        let totalSeconds = Int(totalWorkoutDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedTimeRemaining: String {
        // Use ceiling so we show "5" at the start, and transition happens at 0
        let time = Int(ceil(displayTimeRemaining))
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var buttonText: String {
        if currentPhase == .complete {
            return "Start"
        }
        if isPaused {
            return "Resume"
        }
        if isRunning {
            return "Pause"
        }
        return "Start"
    }

    // MARK: - Actions
    func startOrToggle() {
        if currentPhase == .complete {
            reset()
            start()
        } else if isPaused {
            resume()
        } else if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        currentPhase = .warmup
        currentRound = 1
        isRunning = true
        isPaused = false
        phaseDuration = warmupDuration
        phaseStartTime = Date()
        lastBeepedSecond = -1
        displayTimeRemaining = warmupDuration
        onTimerStart?()
        // Schedule countdown and work-start sound for end of warmup (no transition sound at start)
        onScheduleAudio?(warmupDuration, .work, false)
    }

    func pause() {
        guard isRunning && !isPaused else { return }
        pausedTimeRemaining = timeRemaining
        displayTimeRemaining = pausedTimeRemaining
        isPaused = true
        isRunning = false
        onCancelScheduledAudio?()
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        isRunning = true
        // Recalculate phaseStartTime so that timeRemaining picks up from where we left off
        phaseStartTime = Date().addingTimeInterval(-(phaseDuration - pausedTimeRemaining))
        // Re-schedule audio for remaining time (no transition sound on resume)
        let nextPhase: TimerPhase = currentPhase == .work ? .rest : .work
        onScheduleAudio?(pausedTimeRemaining, nextPhase, false)
    }

    func reset() {
        currentPhase = .ready
        currentRound = 1
        isRunning = false
        isPaused = false
        phaseStartTime = nil
        phaseDuration = 0
        pausedTimeRemaining = 0
        lastBeepedSecond = -1
        displayTimeRemaining = 0
        onCancelScheduledAudio?()
        onTimerStop?()
    }

    // MARK: - Tick (called every 100ms)
    func tick() {
        guard isRunning && !isPaused else { return }

        let remaining = timeRemaining

        // Update the display property to trigger UI refresh
        displayTimeRemaining = remaining

        // Countdown beeps are now hardware-scheduled via onScheduleAudio
        // Haptic feedback still uses polling for visual sync
        let secondsLeft = Int(floor(remaining))
        if secondsLeft <= 2 && secondsLeft >= 0 && secondsLeft != lastBeepedSecond {
            lastBeepedSecond = secondsLeft
            onCountdownBeep?()  // Now only triggers haptics, not audio
        }

        // Check for phase transition
        if remaining <= 0 {
            transitionToNextPhase()
        }
    }

    private func transitionToNextPhase() {
        lastBeepedSecond = -1

        switch currentPhase {
        case .ready:
            // Should not happen, but handle gracefully
            break

        case .warmup:
            // Warmup -> Work
            currentPhase = .work
            phaseDuration = TimeInterval(workTime)
            phaseStartTime = Date()
            displayTimeRemaining = phaseDuration
            onPhaseTransition?(.work)
            // Schedule audio for countdown beeps; transition to rest (or complete on last round)
            onScheduleAudio?(phaseDuration, .rest, true)

        case .work:
            // Work -> Rest (or Complete if last round)
            if currentRound >= totalRounds {
                // Last round done - skip rest and complete
                currentPhase = .complete
                isRunning = false
                phaseStartTime = nil
                phaseDuration = 0
                displayTimeRemaining = 0
                onWorkoutComplete?()
                onTimerStop?()
            } else {
                // Not last round - go to rest
                currentPhase = .rest
                phaseDuration = TimeInterval(restTime)
                phaseStartTime = Date()
                displayTimeRemaining = phaseDuration
                onPhaseTransition?(.rest)
                // Schedule audio for transition to next work phase
                onScheduleAudio?(phaseDuration, .work, true)
            }

        case .rest:
            // Rest -> next round Work or Complete
            if currentRound >= totalRounds {
                // Workout complete
                currentPhase = .complete
                isRunning = false
                phaseStartTime = nil
                phaseDuration = 0
                displayTimeRemaining = 0
                onWorkoutComplete?()
                onTimerStop?()
            } else {
                // Next round
                currentRound += 1
                currentPhase = .work
                phaseDuration = TimeInterval(workTime)
                phaseStartTime = Date()
                displayTimeRemaining = phaseDuration
                onRestStart?()
                // Schedule audio for countdown beeps; transition to rest (or complete on last round)
                onScheduleAudio?(phaseDuration, .rest, true)
            }

        case .complete:
            // Already complete, nothing to do
            break
        }
    }
}
