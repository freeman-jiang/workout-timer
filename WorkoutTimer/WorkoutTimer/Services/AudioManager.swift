import AVFoundation
import Foundation

enum SoundEffect: String {
    case countdown = "countdown"
    case phase = "phase"
    case rest = "rest"
    case complete = "complete"
}

@Observable
final class AudioManager: NSObject, AVAudioPlayerDelegate {
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var activePlayers: [AVAudioPlayer] = [] // Keep strong references to playing sounds
    private var isSessionConfigured = false

    override init() {
        super.init()
        configureAudioSession()
        loadSounds()
    }

    private func configureAudioSession() {
        do {
            // Use .playback with .duckOthers to duck other audio (like music) when playing sounds
            // .mixWithOthers allows our sounds to play alongside music
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            isSessionConfigured = true
        } catch {
            print("Failed to configure audio session: \(error)")
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

    func playSound(_ sound: SoundEffect, times: Int = 1) {
        guard times > 0 else { return }

        // Play first instance immediately
        playSoundOnce(sound)

        // Schedule additional plays with 200ms delay between each
        if times > 1 {
            for i in 1..<times {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) { [weak self] in
                    self?.playSoundOnce(sound)
                }
            }
        }
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
        activePlayers.removeAll { $0 === player }
    }

    func playCountdownBeep() {
        playSound(.countdown, times: 1)
    }

    func playPhaseTransition() {
        playSound(.phase, times: 2)
    }

    func playRestStart() {
        playSound(.rest, times: 2)
    }

    func playWorkoutComplete() {
        playSound(.complete, times: 3)
    }
}
