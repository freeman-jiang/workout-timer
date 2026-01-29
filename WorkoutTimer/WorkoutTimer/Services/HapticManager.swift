import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        // Prepare generators for minimal latency
        prepareAll()
    }

    func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
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

    /// Enhanced celebration haptic sequence for workout complete
    func celebration() {
        // Play a satisfying multi-part haptic sequence
        heavyGenerator.impactOccurred(intensity: 1.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            mediumGenerator.impactOccurred(intensity: 0.8)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            lightGenerator.impactOccurred(intensity: 0.6)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }

        // Re-prepare for next use
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            prepareAll()
        }
    }

    /// Round complete notification
    func roundComplete() {
        rigidGenerator.impactOccurred(intensity: 0.7)
        rigidGenerator.prepare()
    }

    /// Stepper value change
    func stepperTick() {
        lightGenerator.impactOccurred(intensity: 0.5)
        lightGenerator.prepare()
    }

    /// Error or warning feedback
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Success feedback
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Selection changed feedback (for pickers, drag reorder, etc.)
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
}
