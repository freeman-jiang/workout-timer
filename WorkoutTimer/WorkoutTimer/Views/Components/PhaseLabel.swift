import SwiftUI

struct PhaseLabel: View {
    let phase: TimerPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var phaseNamespace

    var body: some View {
        Text(phase.displayText.uppercased())
            .font(Typography.phase)
            .tracking(4)
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
            .accessibilityValue(phase.displayText)
    }
}

/// Alternative phase label with icon
struct PhaseLabelWithIcon: View {
    let phase: TimerPhase

    private var iconName: String {
        switch phase {
        case .ready: return "figure.stand"
        case .warmup: return "flame"
        case .work: return "bolt.fill"
        case .rest: return "pause.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .symbolEffect(.bounce, value: phase)

            Text(phase.displayText.uppercased())
                .font(Typography.phase)
                .tracking(3)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassCapsule()
        .contentTransition(.symbolEffect(.replace))
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

            Divider()
                .background(.white)
                .padding(.vertical)

            PhaseLabelWithIcon(phase: .ready)
            PhaseLabelWithIcon(phase: .warmup)
            PhaseLabelWithIcon(phase: .work)
            PhaseLabelWithIcon(phase: .rest)
            PhaseLabelWithIcon(phase: .complete)
        }
    }
}
