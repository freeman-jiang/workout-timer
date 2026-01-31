import MediaPlayer
import UIKit

@MainActor
final class NowPlayingManager {
    static let shared = NowPlayingManager()

    private var timerState: TimerState?
    private var onPlayPause: (() -> Void)?

    private init() {
        setupRemoteCommands()
    }

    func configure(timerState: TimerState, onPlayPause: @escaping () -> Void) {
        self.timerState = timerState
        self.onPlayPause = onPlayPause
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.onPlayPause?()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.onPlayPause?()
            return .success
        }

        // Toggle play/pause
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.onPlayPause?()
            return .success
        }

        // Disable skip commands (not applicable for our timer)
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
    }

    func updateNowPlayingInfo() {
        guard let state = timerState else { return }

        var nowPlayingInfo = [String: Any]()

        // Title: Phase name
        nowPlayingInfo[MPMediaItemPropertyTitle] = state.currentPhase.displayText

        // Artist: Exercise name or "HIIT Timer"
        if let exercise = state.currentExerciseName {
            nowPlayingInfo[MPMediaItemPropertyArtist] = exercise
        } else {
            nowPlayingInfo[MPMediaItemPropertyArtist] = "HIIT Interval Timer"
        }

        // Album: Round info
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = state.roundInfoText

        // Playback info
        let duration = state.timeRemaining + (state.isRunning ? 0 : 0)
        let elapsed = 0.0

        if state.currentPhase != .ready && state.currentPhase != .complete {
            // For active phases, show time remaining as duration
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = state.timeRemaining
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        }

        // Playback rate (1.0 = playing, 0.0 = paused)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = state.isRunning ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
