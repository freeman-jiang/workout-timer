import SwiftUI

struct ControlButtons: View {
    let buttonText: String
    let onStartPause: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Start/Pause/Resume button
            Button {
                HapticManager.shared.buttonTap()
                onStartPause()
            } label: {
                Text(buttonText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

            // Reset button
            Button {
                HapticManager.shared.buttonTap()
                onReset()
            } label: {
                Text("Reset")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 100)
                    .frame(height: 56)
                    .background(.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.phaseWork
            .ignoresSafeArea()
        ControlButtons(
            buttonText: "Start",
            onStartPause: {},
            onReset: {}
        )
    }
}
