import SwiftUI

struct TimerDisplay: View {
    let time: String

    var body: some View {
        Text(time)
            .font(.system(size: 96, weight: .ultraLight, design: .default))
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
    }
}

#Preview {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        TimerDisplay(time: "0:45")
    }
}
