import SwiftUI

/// Animated background that transitions between phase colors with subtle motion
struct AnimatedPhaseBackground: View {
    let phase: TimerPhase
    let isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradientBackground(phase: phase, isRunning: isRunning)
        } else {
            // Fallback for iOS 17
            SimpleAnimatedBackground(phase: phase)
        }
    }
}

/// iOS 18+ MeshGradient animated background
@available(iOS 18.0, *)
struct MeshGradientBackground: View {
    let phase: TimerPhase
    let isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isRunning || reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate

            MeshGradient(
                width: 3,
                height: 3,
                points: meshPoints(time: elapsed),
                colors: meshColors
            )
            .ignoresSafeArea()
        }
        .animation(AnimationConstants.backgroundMorph, value: phase)
    }

    private var meshColors: [Color] {
        let colors = phase.gradientColors
        // Create 9 colors for 3x3 mesh from 4 base colors
        return [
            colors[0], colors[1], colors[2],
            colors[3], colors[0], colors[1],
            colors[2], colors[3], colors[0]
        ]
    }

    private func meshPoints(time: TimeInterval) -> [SIMD2<Float>] {
        let breathingSpeed: Float = 0.3
        let breathingAmount: Float = 0.02
        let t = Float(time) * breathingSpeed

        // Subtle breathing motion during work phase
        let motion = (phase == .work && isRunning && !reduceMotion) ? breathingAmount : 0

        return [
            // Top row
            SIMD2(0.0, 0.0),
            SIMD2(0.5 + sin(t) * motion, 0.0),
            SIMD2(1.0, 0.0),
            // Middle row
            SIMD2(0.0, 0.5 + cos(t * 1.3) * motion),
            SIMD2(0.5 + sin(t * 0.7) * motion, 0.5 + cos(t * 0.9) * motion),
            SIMD2(1.0, 0.5 + sin(t * 1.1) * motion),
            // Bottom row
            SIMD2(0.0, 1.0),
            SIMD2(0.5 + cos(t * 0.8) * motion, 1.0),
            SIMD2(1.0, 1.0)
        ]
    }
}

/// Simple animated background without mesh (fallback for older devices)
struct SimpleAnimatedBackground: View {
    let phase: TimerPhase

    var body: some View {
        LinearGradient(
            colors: phase.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(AnimationConstants.backgroundMorph, value: phase)
    }
}

#Preview("Work Phase") {
    AnimatedPhaseBackground(phase: .work, isRunning: true)
}

#Preview("Rest Phase") {
    AnimatedPhaseBackground(phase: .rest, isRunning: true)
}

#Preview("Ready Phase") {
    AnimatedPhaseBackground(phase: .ready, isRunning: false)
}
