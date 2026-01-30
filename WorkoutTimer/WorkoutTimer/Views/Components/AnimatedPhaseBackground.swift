import SwiftUI

/// Animated background that transitions between phase colors with subtle motion
struct AnimatedPhaseBackground: View {
    let phase: TimerPhase
    let isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                MeshGradientBackground(phase: phase, isRunning: isRunning)
            } else {
                // Fallback for iOS 17
                SimpleAnimatedBackground(phase: phase)
            }
        }
        .accessibilityHidden(true)
    }
}

/// iOS 18+ MeshGradient animated background
@available(iOS 18.0, *)
struct MeshGradientBackground: View {
    let phase: TimerPhase
    let isRunning: Bool

    @State private var animationTime: Double = 0
    @State private var startTime: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: meshPoints(time: animationTime),
            colors: meshColors
        )
        .ignoresSafeArea()
        .animation(AnimationConstants.backgroundMorph, value: phase)
        .task(id: isRunning) {
            // Only animate when timer is running and motion is allowed
            guard isRunning, !reduceMotion else { return }

            if startTime == nil {
                startTime = Date()
            }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16)) // ~60fps
                if let start = startTime {
                    animationTime = Date().timeIntervalSince(start)
                }
            }
        }
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
        let t = Float(time)

        // Mist/cloud-like motion - slow, ambient drift
        let drift: Float = reduceMotion ? 0 : 0.4
        let speed: Float = 0.35

        // Helper for organic motion using multiple sine waves with prime-ratio frequencies
        // This creates non-repeating, natural-looking movement
        func flow(seed: Float) -> Float {
            let a = sin(t * speed * 1.0 + seed) * 0.35
            let b = sin(t * speed * 1.618 + seed * 2.7) * 0.25  // Golden ratio
            let c = sin(t * speed * 2.236 + seed * 0.4) * 0.2   // sqrt(5)
            let d = cos(t * speed * 0.7 + seed * 1.3) * 0.15
            let e = sin(t * speed * 3.14159 + seed * 0.9) * 0.05 // Pi
            return (a + b + c + d + e) * drift
        }

        return [
            // Four corners stay fixed at exact corners
            SIMD2(0.0, 0.0),
            SIMD2(0.5 + flow(seed: 1.0), 0.0),  // Top edge - Y stays at 0
            SIMD2(1.0, 0.0),

            // Middle row - free to move
            SIMD2(0.0, 0.5 + flow(seed: 4.0)),  // Left edge - X stays at 0
            SIMD2(0.5 + flow(seed: 5.0), 0.5 + flow(seed: 6.0)),  // Center - full freedom
            SIMD2(1.0, 0.5 + flow(seed: 8.0)),  // Right edge - X stays at 1

            // Bottom row
            SIMD2(0.0, 1.0),
            SIMD2(0.5 + flow(seed: 9.0), 1.0),  // Bottom edge - Y stays at 1
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
