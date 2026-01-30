import SwiftUI

/// A view for exporting the app icon - grey background with orange running man
/// To use: Change WorkoutTimerApp.swift to show IconExportView() temporarily
struct IconExportView: View {
    var body: some View {
        ZStack {
            // Grey background (same as ready phase)
            Color(hex: "171717")
                .ignoresSafeArea()

            // Orange running man with glow
            Image(systemName: "figure.run")
                .font(.system(size: 225, weight: .regular))
                .foregroundStyle(Color(hex: "ea580c"))
                .shadow(color: Color(hex: "ea580c").opacity(0.6), radius: 30)
                .shadow(color: Color(hex: "ea580c").opacity(0.3), radius: 60)
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    IconExportView()
        .previewLayout(.fixed(width: 1024, height: 1024))
}
