import SwiftUI

struct ControlButtons: View {
    let buttonText: String
    let onStartPause: () -> Void
    let onReset: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var buttonIcon: String {
        switch buttonText.lowercased() {
        case "start": return "play.fill"
        case "pause": return "pause.fill"
        case "resume": return "play.fill"
        default: return "play.fill"
        }
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
                    .symbolEffect(.bounce, value: buttonText)
            }
            .buttonStyle(PrimaryGlassButtonStyle())
            .accessibilityLabel(buttonText)
            .accessibilityHint("Double tap to \(buttonText.lowercased()) the timer")

            // Reset button
            Button {
                HapticManager.shared.buttonTap()
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 56, height: 56)
                    .glassCircle()
            }
            .buttonStyle(IconGlassButtonStyle())
            .accessibilityLabel("Reset")
            .accessibilityHint("Double tap to reset the timer")
        }
        .padding(.horizontal, 24)
    }
}

/// Alternative control buttons layout with larger touch targets
struct ControlButtonsCompact: View {
    let buttonText: String
    let onStartPause: () -> Void
    let onReset: () -> Void

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
            // Reset button
            Button {
                HapticManager.shared.buttonTap()
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 64, height: 64)
                    .glassCircle()
            }
            .buttonStyle(IconGlassButtonStyle())

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
                    .symbolEffect(.bounce, value: buttonText)
            }
            .buttonStyle(PrimaryGlassButtonStyle())

            // Placeholder for symmetry (or future skip button)
            Color.clear
                .frame(width: 64, height: 64)
        }
        .padding(.horizontal, 24)
    }
}

#Preview("Standard") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        VStack(spacing: 24) {
            ControlButtons(
                buttonText: "Start",
                onStartPause: {},
                onReset: {}
            )
            ControlButtons(
                buttonText: "Pause",
                onStartPause: {},
                onReset: {}
            )
            ControlButtons(
                buttonText: "Resume",
                onStartPause: {},
                onReset: {}
            )
        }
    }
}

#Preview("Compact") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        ControlButtonsCompact(
            buttonText: "Pause",
            onStartPause: {},
            onReset: {}
        )
    }
}
