import SwiftUI

/// A view for exporting the app icon - gradient + WORK label + timer
/// To use: Change WorkoutTimerApp.swift to show IconExportView() temporarily
struct IconExportView: View {
    var body: some View {
        ZStack {
            // Orange gradient background (same as work phase)
            LinearGradient(
                colors: [
                    Color(hex: "7c2d12"),
                    Color(hex: "c2410c"),
                    Color(hex: "ea580c"),
                    Color(hex: "9a3412")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // WORK label with icon (like PhaseLabel)
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 14, weight: .semibold))
                    Text("WORK")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .tracking(4)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(.white.opacity(0.15))
                }

                // Timer number
                Text("0:45")
                    .font(.system(size: 160, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    IconExportView()
        .previewLayout(.fixed(width: 1024, height: 1024))
}
