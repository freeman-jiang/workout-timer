import SwiftUI

/// Full-screen celebration shown when workout is complete
struct WorkoutCompleteOverlay: View {
    let totalRounds: Int
    let workTime: Int
    let restTime: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var totalWorkSeconds: Int {
        workTime * totalRounds
    }

    private var totalDuration: Int {
        let work = workTime * totalRounds
        let rest = restTime * totalRounds
        return work + rest
    }

    var body: some View {
        ZStack {
            // Same background as ready state
            Color(hex: "0a0a0a")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(maxHeight: 80)

                // Checkmark icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce.up.byLayer, value: appeared)
                    .padding(.bottom, 12)

                // Title
                Text("Workout Complete")
                    .font(Typography.celebration)
                    .foregroundStyle(.white)
                    .padding(.bottom, 24)

                // Stats badges
                VStack(spacing: 12) {
                    statRow(icon: "repeat", label: "Rounds", value: "\(totalRounds)")
                    statRow(icon: "figure.run", label: "Work", value: formatTime(totalWorkSeconds))
                    statRow(icon: "clock", label: "Total", value: formatTime(totalDuration))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .glassBackground(cornerRadius: 20)
                .padding(.horizontal, 24)

                Spacer()

                // Done button
                Button {
                    HapticManager.shared.buttonTap()
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(Typography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .glassCapsule(prominent: true)
                }
                .buttonStyle(PrimaryGlassButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 28)

            Text(label)
                .font(Typography.settingLabel)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(Typography.settingValue)
                .foregroundStyle(.white)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(minutes) min"
        }
        return "\(minutes):\(String(format: "%02d", secs))"
    }
}

// MARK: - Previews

#Preview("Workout Complete") {
    WorkoutCompleteOverlay(
        totalRounds: 8,
        workTime: 45,
        restTime: 15,
        onDismiss: {}
    )
}
