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
