import SwiftUI

/// Celebratory overlay shown when workout is complete
struct WorkoutCompleteOverlay: View {
    let totalRounds: Int
    let workTime: Int
    let restTime: Int
    let onDismiss: () -> Void

    @State private var animationPhase: AnimationPhase = .initial
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum AnimationPhase {
        case initial
        case expand
        case settle
    }

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(animationPhase != .initial ? 1 : 0)

            // Celebration card
            celebrationCard
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }

    private var cardScale: CGFloat {
        switch animationPhase {
        case .initial: return 0.5
        case .expand: return 1.05
        case .settle: return 1.0
        }
    }

    private var cardOpacity: Double {
        animationPhase == .initial ? 0 : 1
    }

    private var celebrationCard: some View {
        VStack(spacing: 20) {
            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .symbolEffect(.bounce.up.byLayer, value: animationPhase == .settle)

            // Title
            Text("Workout Complete!")
                .font(Typography.celebration)
                .foregroundStyle(.white)

            // Stats
            VStack(spacing: 12) {
                statRow(icon: "repeat", label: "Rounds", value: "\(totalRounds)")
                statRow(icon: "flame.fill", label: "Work", value: formatTime(workTime * totalRounds))
                statRow(icon: "clock", label: "Total", value: formatTime(totalDuration))
            }
            .padding(.vertical, 8)

            // Dismiss button
            Button {
                HapticManager.shared.buttonTap()
                onDismiss()
            } label: {
                Text("Done")
                    .font(Typography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .glassCapsule(prominent: true)
            }
            .buttonStyle(PrimaryGlassButtonStyle())
        }
        .padding(28)
        .glassBackground(cornerRadius: 28)
        .padding(.horizontal, 32)
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 24)

            Text(label)
                .font(Typography.settingLabel)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(Typography.settingValue)
                .foregroundStyle(.white)
        }
    }

    private var totalDuration: Int {
        let work = workTime * totalRounds
        let rest = restTime * totalRounds
        return work + rest
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(minutes) min"
        }
        return "\(minutes):\(String(format: "%02d", secs))"
    }

    private func startAnimation() {
        guard !reduceMotion else {
            animationPhase = .settle
            return
        }

        withAnimation(AnimationConstants.celebratory) {
            animationPhase = .expand
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(AnimationConstants.subtle) {
                animationPhase = .settle
            }
        }
    }
}

// MARK: - Round Complete Badge

/// Brief toast notification shown when a round is completed
struct RoundCompleteBadge: View {
    let roundNumber: Int
    let totalRounds: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.green)

            Text("Round \(roundNumber) of \(totalRounds)")
                .font(Typography.buttonSmall)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassCapsule()
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Previews

#Preview("Workout Complete") {
    ZStack {
        Color.phaseReady
            .ignoresSafeArea()

        WorkoutCompleteOverlay(
            totalRounds: 8,
            workTime: 45,
            restTime: 15,
            onDismiss: {}
        )
    }
}

#Preview("Round Badge") {
    ZStack {
        Color.phaseRest
            .ignoresSafeArea()

        RoundCompleteBadge(roundNumber: 3, totalRounds: 8)
    }
}

