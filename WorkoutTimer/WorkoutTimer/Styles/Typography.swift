import SwiftUI

/// Typography system using SF Pro Rounded throughout for cohesive, friendly aesthetic
enum Typography {
    // MARK: - Timer Display

    /// Large timer display - thin weight for modern feel
    static let timer = Font.system(size: 96, weight: .thin, design: .rounded)

    /// Timer display for smaller contexts
    static let timerCompact = Font.system(size: 72, weight: .thin, design: .rounded)

    // MARK: - Phase & Status

    /// Phase label text (WORK, REST, etc.)
    static let phase = Font.system(size: 13, weight: .semibold, design: .rounded)

    /// Current exercise name
    static let exercise = Font.system(size: 22, weight: .semibold, design: .rounded)

    /// Round info text (1/8)
    static let roundInfo = Font.system(size: 17, weight: .regular, design: .rounded)

    // MARK: - Buttons & Controls

    /// Primary button text
    static let button = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Secondary/smaller button text
    static let buttonSmall = Font.system(size: 15, weight: .medium, design: .rounded)

    // MARK: - Settings

    /// Setting row label
    static let settingLabel = Font.system(size: 15, weight: .medium, design: .rounded)

    /// Setting value display
    static let settingValue = Font.system(size: 16, weight: .semibold, design: .rounded)

    /// Tab/segment label
    static let tabLabel = Font.system(size: 15, weight: .medium, design: .rounded)

    // MARK: - Cards & Lists

    /// Card title
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .rounded)

    /// Card subtitle/metadata
    static let cardSubtitle = Font.system(size: 13, weight: .regular, design: .rounded)

    /// List item text
    static let listItem = Font.system(size: 16, weight: .regular, design: .rounded)

    // MARK: - Navigation

    /// Navigation title (when inline)
    static let navTitle = Font.system(size: 17, weight: .semibold, design: .rounded)

    // MARK: - Celebration

    /// Large celebration text
    static let celebration = Font.system(size: 32, weight: .bold, design: .rounded)

    /// Celebration subtitle
    static let celebrationSubtitle = Font.system(size: 18, weight: .medium, design: .rounded)
}
