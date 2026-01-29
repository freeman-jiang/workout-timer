import SwiftUI
import AVFoundation

@main
struct WorkoutTimerApp: App {
    init() {
        // Configure audio session on app launch
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            TimerView()
        }
    }

    private func configureAudioSession() {
        do {
            // Configure audio session for playing alongside other audio
            // .playback allows background audio
            // .duckOthers temporarily lowers other audio when we play sounds
            // .mixWithOthers allows our audio to coexist with music
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
