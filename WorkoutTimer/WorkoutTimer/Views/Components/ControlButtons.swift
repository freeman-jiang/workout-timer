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
                    .animation(nil, value: buttonText) // Disable fade animation on text change
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
                        .glassCircle(prominent: true)
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
            Button("Keep Going", role: .cancel) {}
            Button("Cancel", role: .destructive) {
                HapticManager.shared.warning()
                onReset()
            }
        } message: {
            Text("Your progress will be lost.")
        }
    }
}

#Preview("Ready") {
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

#Preview("Active") {
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
