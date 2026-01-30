import SwiftUI

/// A view for exporting the app icon - just gradient + timer number
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

            // Timer number - matches app typography
            Text("0:45")
                .font(.system(size: 120, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    IconExportView()
}
