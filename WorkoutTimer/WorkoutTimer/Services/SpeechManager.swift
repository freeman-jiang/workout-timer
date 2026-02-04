import AVFoundation
import os.log

private let logger = Logger(subsystem: "com.workout.timer", category: "SpeechManager")

@MainActor
final class SpeechManager: NSObject {
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
    }

    func announce(_ text: String) {
        guard AppSettings.shared.announceExercises else { return }
        guard !text.isEmpty else { return }

        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.volume = AppSettings.shared.volume * 0.7 // Quieter than beeps

        logger.info("Announcing: \(text)")
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
