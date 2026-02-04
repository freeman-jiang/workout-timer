import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var volume: Double = Double(AppSettings.shared.volume)
    @State private var audioManager = AudioManager()
    @State private var isDragging = false
    @State private var previewTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Volume row
                    HStack(spacing: 12) {
                        Image(systemName: volumeIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .glassCircle()
                            .animation(.easeInOut(duration: 0.15), value: volumeIcon)

                        Text("Volume")
                            .font(Typography.settingLabel)
                            .foregroundStyle(.white.opacity(0.85))

                        Slider(value: $volume, in: 0...1, onEditingChanged: { editing in
                            isDragging = editing
                            if editing {
                                // Start preview timer
                                audioManager.playCountdownBeep()
                                previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                    audioManager.playCountdownBeep()
                                }
                            } else {
                                // Stop preview timer
                                previewTimer?.invalidate()
                                previewTimer = nil
                            }
                        })
                            .tint(.white)
                            .onChange(of: volume) { _, newValue in
                                AppSettings.shared.setVolume(Float(newValue))
                            }
                    }
                    .padding(16)
                    .glassBackground(cornerRadius: 16)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .glassCircle()
                    }
                    .buttonStyle(IconGlassButtonStyle())
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var volumeIcon: String {
        if volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}

#Preview {
    SettingsView()
}
