import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)

    private init() {
        // Prepare generators for minimal latency
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
    }

    func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
    }

    /// Light haptic for countdown beeps (3, 2, 1)
    func countdownBeep() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// Medium haptic for phase transitions
    func phaseTransition() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// Heavy haptic for workout complete
    func workoutComplete() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    /// Soft haptic for button presses
    func buttonTap() {
        softGenerator.impactOccurred()
        softGenerator.prepare()
    }
}
