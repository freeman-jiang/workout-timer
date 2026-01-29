import SwiftUI

/// Typography system using SF Pro Rounded throughout for cohesive, friendly aesthetic.
/// Uses Dynamic Type semantic styles for accessibility scaling where appropriate.
enum Typography {
    // MARK: - Timer Display

    /// Large timer display - fixed size hero element (does not scale with Dynamic Type)
    static let timer = Font.system(size: 120, weight: .thin, design: .rounded)

    /// Timer display for smaller contexts - fixed size
    static let timerCompact = Font.system(size: 72, weight: .thin, design: .rounded)

    // MARK: - Phase & Status

    /// Phase label text (WORK, REST, etc.) - scales with Dynamic Type
    static var phase: Font {
        .system(.caption, design: .rounded, weight: .semibold)
    }

    /// Current exercise name - scales with Dynamic Type
    static var exercise: Font {
        .system(.title, design: .rounded, weight: .semibold)
    }

    /// Round info text (1/8) - scales with Dynamic Type
    static var roundInfo: Font {
        .system(.title, design: .rounded, weight: .regular)
    }

    // MARK: - Buttons & Controls

    /// Primary button text - scales with Dynamic Type
    static var button: Font {
        .system(.body, design: .rounded, weight: .semibold)
    }

    /// Secondary/smaller button text - scales with Dynamic Type
    static var buttonSmall: Font {
        .system(.subheadline, design: .rounded, weight: .medium)
    }

    // MARK: - Settings

    /// Setting row label - scales with Dynamic Type
    static var settingLabel: Font {
        .system(.subheadline, design: .rounded, weight: .medium)
    }

    /// Setting value display - scales with Dynamic Type
    static var settingValue: Font {
        .system(.callout, design: .rounded, weight: .semibold)
    }

    /// Tab/segment label - scales with Dynamic Type
    static var tabLabel: Font {
        .system(.subheadline, design: .rounded, weight: .medium)
    }

    // MARK: - Cards & Lists

    /// Card title - scales with Dynamic Type
    static var cardTitle: Font {
        .system(.headline, design: .rounded, weight: .semibold)
    }

    /// Card subtitle/metadata - scales with Dynamic Type
    static var cardSubtitle: Font {
        .system(.caption, design: .rounded, weight: .regular)
    }

    /// List item text - scales with Dynamic Type
    static var listItem: Font {
        .system(.callout, design: .rounded, weight: .regular)
    }

    // MARK: - Navigation

    /// Navigation title (when inline) - scales with Dynamic Type
    static var navTitle: Font {
        .system(.body, design: .rounded, weight: .semibold)
    }

    // MARK: - Celebration

    /// Large celebration text - scales with Dynamic Type
    static var celebration: Font {
        .system(.largeTitle, design: .rounded, weight: .bold)
    }

    /// Celebration subtitle - scales with Dynamic Type
    static var celebrationSubtitle: Font {
        .system(.headline, design: .rounded, weight: .medium)
    }
}
