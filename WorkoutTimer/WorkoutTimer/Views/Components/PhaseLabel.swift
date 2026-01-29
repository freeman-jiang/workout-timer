import SwiftUI

struct PhaseLabel: View {
    let phase: TimerPhase
    var isWorkoutMode: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var phaseNamespace

    private var displayText: String {
        if phase == .rest && isWorkoutMode {
            return "Next Up"
        }
        return phase.displayText
    }

    private var icon: String? {
        switch phase {
        case .work:
            return "figure.run"
        case .rest:
            return "moon.fill"
        default:
            return nil
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(displayText.uppercased())
                .font(Typography.phase)
                .tracking(4)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassCapsule()
        .contentTransition(.opacity)
        .animation(
            reduceMotion ? nil : AnimationConstants.phaseTransition,
            value: phase
        )
        .accessibilityLabel("Current phase")
        .accessibilityValue(displayText)
    }
}

#Preview {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        VStack(spacing: 20) {
            PhaseLabel(phase: .ready)
            PhaseLabel(phase: .warmup)
            PhaseLabel(phase: .work)
            PhaseLabel(phase: .rest)
            PhaseLabel(phase: .complete)
        }
    }
}
