import SwiftUI

enum TimerPhase: String, CaseIterable {
    case ready
    case warmup
    case work
    case rest
    case complete

    var displayText: String {
        switch self {
        case .ready: return "Ready"
        case .warmup: return "Get Ready"
        case .work: return "Work"
        case .rest: return "Rest"
        case .complete: return "Done!"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .ready: return Color.phaseReady
        case .warmup: return Color.phaseWarmup
        case .work: return Color.phaseWork
        case .rest: return Color.phaseRest
        case .complete: return Color.phaseReady
        }
    }
}

extension Color {
    static let phaseReady = Color(hex: "0f172a")
    static let phaseWarmup = Color(hex: "4a1a6b")
    static let phaseWork = Color(hex: "064e3b")
    static let phaseRest = Color(hex: "1e3a5f")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
