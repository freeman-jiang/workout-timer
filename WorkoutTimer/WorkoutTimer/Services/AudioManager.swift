import AVFoundation
import AudioToolbox
import Foundation

enum SoundEffect: String {
    case countdown = "countdown"
    case phase = "phase"
    case rest = "rest"
    case complete = "complete"
}

@Observable
@MainActor
final class AudioManager: NSObject, AVAudioPlayerDelegate {
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var activePlayers: [AVAudioPlayer] = [] // Keep strong references to playing sounds
    private var silentPlayer: AVAudioPlayer? // Keeps audio session alive in background
    private var isSessionConfigured = false
    private var isBackgroundAudioActive = false
    private var isDucking = false
    private var duckingWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        configureAudioSession()
        loadSounds()
        prepareSilentAudio()
    }

    private func configureAudioSession() {
        do {
            // Use .playback to enable background audio
            // .mixWithOthers allows our sounds to play alongside music without ducking
            // We'll enable ducking temporarily only when playing actual sound effects
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            isSessionConfigured = true
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func enableDucking() {
        guard !isDucking else { return }
        isDucking = true
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .mixWithOthers]
            )
        } catch {
            print("Failed to enable ducking: \(error)")
        }
    }

    private func disableDucking() {
        guard isDucking else { return }
        isDucking = false
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            print("Failed to disable ducking: \(error)")
        }
    }

    private func loadSounds() {
        for sound in [SoundEffect.countdown, .phase, .rest, .complete] {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players[sound] = player
                } catch {
                    print("Failed to load sound \(sound.rawValue): \(error)")
                }
            } else {
                print("Sound file not found: \(sound.rawValue).mp3")
            }
        }
    }

    // MARK: - Silent Audio (keeps audio session alive in background)

    private func prepareSilentAudio() {
        // Create a silent audio player that loops to keep the audio session active
        // This allows our sound effects to play even when the app is backgrounded
        guard let url = Bundle.main.url(forResource: "countdown", withExtension: "mp3") else {
            return
        }

        do {
            silentPlayer = try AVAudioPlayer(contentsOf: url)
            silentPlayer?.numberOfLoops = -1 // Loop forever
            silentPlayer?.volume = 0.0 // Silent
            silentPlayer?.prepareToPlay()
        } catch {
            print("Failed to prepare silent audio: \(error)")
        }
    }

    /// Start background audio session - call when timer starts
    func startBackgroundAudio() {
        guard !isBackgroundAudioActive else { return }
        silentPlayer?.play()
        isBackgroundAudioActive = true
    }

    /// Stop background audio session - call when timer stops/completes
    func stopBackgroundAudio() {
        guard isBackgroundAudioActive else { return }
        silentPlayer?.stop()
        isBackgroundAudioActive = false
    }

    // MARK: - Sound Effects

    /// Begin a ducking sequence - enables ducking and cancels any pending unduck.
    /// Use this at the start of a countdown sequence (3s mark) to keep music ducked
    /// until the phase transition sound finishes.
    func beginDuckingSequence() {
        duckingWorkItem?.cancel()
        enableDucking()
    }

    /// Play a sound without any ducking management.
    /// Use this for sounds in the middle of a ducking sequence (countdown beeps).
    func playSound(_ sound: SoundEffect, times: Int = 1) {
        guard times > 0 else { return }

        let delayBetweenSounds: TimeInterval = 0.2

        // Play first instance immediately
        playSoundOnce(sound)

        // Schedule additional plays with 200ms delay between each
        if times > 1 {
            for i in 1..<times {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * delayBetweenSounds) { [weak self] in
                    self?.playSoundOnce(sound)
                }
            }
        }
    }

    /// Play a sound and schedule unduck after all repetitions finish.
    /// Use this for the final sound in a ducking sequence (phase transition, rest start, complete).
    func playSoundAndEndDucking(_ sound: SoundEffect, times: Int = 1) {
        guard times > 0 else { return }

        // Cancel any pending unduck
        duckingWorkItem?.cancel()

        // Enable ducking if not already ducked (for standalone sounds like rest/complete)
        if !isDucking {
            enableDucking()
        }

        // Calculate total duration of all sounds
        let singleSoundDuration: TimeInterval = 0.3 // approximate duration of beep
        let delayBetweenSounds: TimeInterval = 0.2
        let totalDuration = singleSoundDuration + (Double(times - 1) * delayBetweenSounds) + singleSoundDuration

        // Play the sounds
        playSound(sound, times: times)

        // Schedule ducking to be disabled after all sounds finish
        let workItem = DispatchWorkItem { [weak self] in
            self?.disableDucking()
        }
        duckingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.2, execute: workItem)
    }

    private func playSoundOnce(_ sound: SoundEffect) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            print("Sound file not found: \(sound.rawValue).mp3")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()

            // Keep a strong reference so it doesn't get deallocated
            activePlayers.append(player)

            player.play()
        } catch {
            print("Failed to play sound \(sound.rawValue): \(error)")
        }
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Remove the player from active players once it finishes
        // Don't remove the silent player
        if player !== silentPlayer {
            activePlayers.removeAll { $0 === player }
        }
    }

    /// Called at 3s mark - begins ducking sequence
    func playCountdownBeep() {
        beginDuckingSequence()
        playSound(.countdown, times: 1)
    }

    /// Called at phase transition - ends ducking sequence
    func playPhaseTransition() {
        playSoundAndEndDucking(.phase, times: 2)
    }

    /// Called at rest start - ends ducking sequence (in case no countdown preceded it)
    func playRestStart() {
        playSoundAndEndDucking(.rest, times: 2)
    }

    /// Called at workout complete - plays phase sound
    func playWorkoutComplete() {
        playSoundAndEndDucking(.phase, times: 2)
    }
}
