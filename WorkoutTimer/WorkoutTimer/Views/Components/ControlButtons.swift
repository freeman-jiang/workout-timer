import SwiftUI

struct ControlButtons: View {
    let buttonText: String
    let isWorkoutActive: Bool
    let isStartDisabled: Bool
    let onStartPause: () -> Void
    let onReset: () -> Void

    @State private var showingCancelConfirmation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        buttonText: String,
        isWorkoutActive: Bool = false,
        isStartDisabled: Bool = false,
        onStartPause: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self.buttonText = buttonText
        self.isWorkoutActive = isWorkoutActive
        self.isStartDisabled = isStartDisabled
        self.onStartPause = onStartPause
        self.onReset = onReset
    }

    private var buttonIcon: String {
        switch buttonText.lowercased() {
        case "start": return "play.fill"
        case "pause": return "pause.fill"
        case "resume": return "play.fill"
        default: return "play.fill"
        }
    }

    private var resetButtonIcon: String {
        "xmark"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Start/Pause/Resume button
            Button {
                HapticManager.shared.buttonTap()
                onStartPause()
            } label: {
                Label(buttonText, systemImage: buttonIcon)
                    .font(Typography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .glassCapsule(prominent: true)
            }
            .buttonStyle(PrimaryGlassButtonStyle())
            .accessibilityLabel(buttonText)
            .accessibilityHint("Double tap to \(buttonText.lowercased()) the timer")
            .disabled(isStartDisabled)
            .opacity(isStartDisabled ? 0.5 : 1.0)

            // Cancel button - only show when workout is active
            if isWorkoutActive {
                Button {
                    HapticManager.shared.buttonTap()
                    showingCancelConfirmation = true
                } label: {
                    Image(systemName: resetButtonIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 56, height: 56)
                        .glassCircle()
                        .contentShape(Circle())
                }
                .buttonStyle(IconGlassButtonStyle())
                .accessibilityLabel("Cancel")
                .accessibilityHint("Double tap to cancel the workout")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
        .animation(.snappy(duration: 0.25), value: isWorkoutActive)
        .alert("Cancel Workout?", isPresented: $showingCancelConfirmation) {
            Button("Continue Workout", role: .cancel) {}
            Button("Cancel Workout", role: .destructive) {
                HapticManager.shared.warning()
                onReset()
            }
        } message: {
            Text("This will end your current workout. You'll need to start from the beginning.")
        }
    }
}

/// Alternative control buttons layout with larger touch targets
struct ControlButtonsCompact: View {
    let buttonText: String
    let isWorkoutActive: Bool
    let isStartDisabled: Bool
    let onStartPause: () -> Void
    let onReset: () -> Void

    @State private var showingCancelConfirmation = false

    init(
        buttonText: String,
        isWorkoutActive: Bool = false,
        isStartDisabled: Bool = false,
        onStartPause: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self.buttonText = buttonText
        self.isWorkoutActive = isWorkoutActive
        self.isStartDisabled = isStartDisabled
        self.onStartPause = onStartPause
        self.onReset = onReset
    }

    private var buttonIcon: String {
        switch buttonText.lowercased() {
        case "start": return "play.fill"
        case "pause": return "pause.fill"
        case "resume": return "play.fill"
        default: return "play.fill"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Cancel button - only show when workout is active
            if isWorkoutActive {
                Button {
                    HapticManager.shared.buttonTap()
                    showingCancelConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 64, height: 64)
                        .glassCircle()
                        .contentShape(Circle())
                }
                .buttonStyle(IconGlassButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }

            // Main button (larger)
            Button {
                HapticManager.shared.buttonTap()
                onStartPause()
            } label: {
                Image(systemName: buttonIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .glassCircle(prominent: true)
            }
            .buttonStyle(PrimaryGlassButtonStyle())
            .disabled(isStartDisabled)
            .opacity(isStartDisabled ? 0.5 : 1.0)

            // Placeholder for symmetry when cancel button is showing
            if isWorkoutActive {
                Color.clear
                    .frame(width: 64, height: 64)
            }
        }
        .padding(.horizontal, 24)
        .animation(.snappy(duration: 0.25), value: isWorkoutActive)
        .alert("Cancel Workout?", isPresented: $showingCancelConfirmation) {
            Button("Continue Workout", role: .cancel) {}
            Button("Cancel Workout", role: .destructive) {
                HapticManager.shared.warning()
                onReset()
            }
        } message: {
            Text("This will end your current workout. You'll need to start from the beginning.")
        }
    }
}

#Preview("Standard - Ready") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        ControlButtons(
            buttonText: "Start",
            isWorkoutActive: false,
            onStartPause: {},
            onReset: {}
        )
    }
}

#Preview("Standard - Active") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        VStack(spacing: 24) {
            ControlButtons(
                buttonText: "Pause",
                isWorkoutActive: true,
                onStartPause: {},
                onReset: {}
            )
            ControlButtons(
                buttonText: "Resume",
                isWorkoutActive: true,
                onStartPause: {},
                onReset: {}
            )
        }
    }
}

#Preview("Compact - Active") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        ControlButtonsCompact(
            buttonText: "Pause",
            isWorkoutActive: true,
            onStartPause: {},
            onReset: {}
        )
    }
}
