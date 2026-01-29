import SwiftUI

struct TimerDisplay: View {
    let time: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(time)
            .font(Typography.timer)
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText(countsDown: true))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: time)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1)
            .accessibilityLabel("Timer")
            .accessibilityValue("\(time) remaining")
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
            TimerDisplay(time: "0:03")
            TimerDisplay(time: "0:02")
            TimerDisplay(time: "0:01")
        }
    }
}
