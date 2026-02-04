import AVFoundation
import os.log

private let logger = Logger(subsystem: "com.workout.timer", category: "SpeechManager")

@MainActor
final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func announce(_ text: String) {
        guard AppSettings.shared.announceExercises else { return }
        guard !text.isEmpty else { return }

        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Enable ducking before speaking (with 0.5s lead time)
        enableDucking()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.volume = AppSettings.shared.volume * 0.9

        logger.info("Announcing: \(text)")

        // Delay speech slightly to let ducking ramp down
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.synthesizer.speak(utterance)
        }
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        disableDucking()
    }

    // MARK: - Audio Ducking

    private func enableDucking() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            logger.info("Audio ducking enabled")
        } catch {
            logger.error("Failed to enable ducking: \(error.localizedDescription)")
        }
    }

    private func disableDucking() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            logger.info("Audio ducking disabled")
        } catch {
            logger.error("Failed to disable ducking: \(error.localizedDescription)")
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Delay unduck to let audio ramp back up smoothly
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            disableDucking()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            disableDucking()
        }
    }
}
