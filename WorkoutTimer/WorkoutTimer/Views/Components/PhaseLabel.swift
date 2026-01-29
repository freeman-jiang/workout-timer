import SwiftUI

struct PhaseLabel: View {
    let phase: TimerPhase

    var body: some View {
        Text(phase.displayText.uppercased())
            .font(.system(size: 14, weight: .medium))
            .tracking(4)
            .foregroundStyle(.white.opacity(0.8))
            .contentTransition(.opacity)
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
