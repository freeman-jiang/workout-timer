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
        case confetti
        case settle
    }

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(animationPhase != .initial ? 1 : 0)

            // Confetti
            if animationPhase == .confetti || animationPhase == .settle {
                ConfettiView()
                    .allowsHitTesting(false)
            }

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
        case .confetti: return 1.0
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
        let warmup = 5
        let work = workTime * totalRounds
        let rest = restTime * totalRounds
        return warmup + work + rest
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AnimationConstants.confettiEntrance) {
                animationPhase = .confetti
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(AnimationConstants.subtle) {
                animationPhase = .settle
            }
        }
    }
}

// MARK: - Confetti View

/// High-performance confetti animation using Canvas
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = Date()

    private let colors: [Color] = [
        .green, .blue, .purple, .orange, .yellow, .pink, .cyan
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)

            Canvas { context, size in
                for particle in particles {
                    let progress = elapsed / particle.duration
                    guard progress < 1 else { continue }

                    let x = particle.startX + particle.velocityX * CGFloat(elapsed)
                    let y = particle.startY + particle.velocityY * CGFloat(elapsed) + 0.5 * 400 * CGFloat(elapsed * elapsed)
                    let rotation = particle.rotation + particle.rotationSpeed * CGFloat(elapsed)
                    let opacity = 1 - progress

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .radians(rotation))

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * 0.6
                    )

                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )

                    context.rotate(by: .radians(-rotation))
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width

        particles = (0..<60).map { _ in
            ConfettiParticle(
                startX: CGFloat.random(in: 0...screenWidth),
                startY: -20,
                velocityX: CGFloat.random(in: -100...100),
                velocityY: CGFloat.random(in: 50...150),
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotationSpeed: CGFloat.random(in: -5...5),
                size: CGFloat.random(in: 8...14),
                color: colors.randomElement() ?? .green,
                duration: Double.random(in: 2.5...4.0)
            )
        }
    }
}

struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotation: CGFloat
    let rotationSpeed: CGFloat
    let size: CGFloat
    let color: Color
    let duration: Double
}

// MARK: - Round Complete Badge

/// Brief notification shown when a round is completed
struct RoundCompleteBadge: View {
    let roundNumber: Int
    let totalRounds: Int

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.green)

                Text("Round \(roundNumber) of \(totalRounds)")
                    .font(Typography.buttonSmall)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassCapsule()
            .transition(.badge)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(AnimationConstants.disappear) {
                        isVisible = false
                    }
                }
            }
        }
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

#Preview("Confetti Only") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()

        ConfettiView()
    }
}
