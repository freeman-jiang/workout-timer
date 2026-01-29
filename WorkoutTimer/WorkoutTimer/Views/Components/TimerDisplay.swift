import SwiftUI

struct TimerDisplay: View {
    let time: String
    var isCountingDown: Bool = false
    var secondsRemaining: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPulsing: Bool {
        isCountingDown && secondsRemaining <= 3 && secondsRemaining >= 1
    }

    var body: some View {
        Text(time)
            .font(Typography.timer)
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : AnimationConstants.numeric, value: time)
            // Shadow layer for floating depth effect
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1)
            // Pulse animation on last 3 seconds
            .scaleEffect(isPulsing && !reduceMotion ? pulseScale : 1.0)
            .animation(
                isPulsing && !reduceMotion
                    ? AnimationConstants.countdownPulse.repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .accessibilityLabel("Timer")
            .accessibilityValue("\(time) remaining")
    }

    private var pulseScale: CGFloat {
        // Scale up slightly more as we get closer to zero
        switch secondsRemaining {
        case 1: return 1.08
        case 2: return 1.05
        case 3: return 1.03
        default: return 1.0
        }
    }
}

/// Countdown overlay that shows expanding rings during final seconds
struct CountdownPulseOverlay: View {
    let secondsRemaining: Int
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.6

    private var shouldShow: Bool {
        isActive && secondsRemaining <= 3 && secondsRemaining >= 1
    }

    var body: some View {
        ZStack {
            if shouldShow && !reduceMotion {
                // Expanding ring
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundStyle(.white.opacity(ringOpacity))
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringScale)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8)) {
                            ringScale = 2.0
                            ringOpacity = 0
                        }
                    }
                    .id(secondsRemaining) // Reset animation on each second
            }
        }
    }
}

#Preview("Normal") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        TimerDisplay(time: "0:45")
    }
}

#Preview("Countdown") {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        VStack {
            TimerDisplay(time: "0:03", isCountingDown: true, secondsRemaining: 3)
            TimerDisplay(time: "0:02", isCountingDown: true, secondsRemaining: 2)
            TimerDisplay(time: "0:01", isCountingDown: true, secondsRemaining: 1)
        }
    }
}
