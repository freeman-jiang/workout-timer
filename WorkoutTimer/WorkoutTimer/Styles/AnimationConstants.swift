import SwiftUI

/// Animation constants for consistent, delightful motion throughout the app
enum AnimationConstants {
    // MARK: - Interactive Feedback

    /// Standard interactive spring for button presses, toggles
    static let interactive = Animation.spring(duration: 0.3, bounce: 0.3)

    /// Quick interactive feedback for immediate response
    static let interactiveQuick = Animation.spring(duration: 0.15, bounce: 0.3)

    // MARK: - Phase Transitions

    /// Phase change animation (background color, content swap)
    static let phaseTransition = Animation.spring(duration: 0.5, bounce: 0.2)

    /// Background gradient morph
    static let backgroundMorph = Animation.spring(duration: 0.6, bounce: 0.15)

    // MARK: - Subtle Motion

    /// Subtle animation for secondary elements
    static let subtle = Animation.spring(duration: 0.25, bounce: 0.1)

    /// Very subtle for micro-interactions
    static let microInteraction = Animation.spring(duration: 0.2, bounce: 0.1)

    // MARK: - Timer Display

    /// Numeric text transitions (timer digits)
    static let numeric = Animation.spring(duration: 0.2, bounce: 0.15)

    /// Countdown pulse animation
    static let countdownPulse = Animation.spring(duration: 0.3, bounce: 0.4)

    // MARK: - Celebration

    /// Celebratory bounce for completion
    static let celebratory = Animation.spring(duration: 0.6, bounce: 0.5)

    /// Confetti entrance
    static let confettiEntrance = Animation.spring(duration: 0.4, bounce: 0.3)

    /// Badge popup
    static let badgePopup = Animation.spring(duration: 0.35, bounce: 0.4)

    // MARK: - Glass Effects

    /// Glass morphing between states
    static let glassMorph = Animation.spring(duration: 0.4, bounce: 0.2)

    /// Glass container resize
    static let glassResize = Animation.spring(duration: 0.35, bounce: 0.15)

    // MARK: - Appearance/Disappearance

    /// Content appearing (settings card, overlays)
    static let appear = Animation.spring(duration: 0.4, bounce: 0.2)

    /// Content disappearing
    static let disappear = Animation.spring(duration: 0.3, bounce: 0.1)

    // MARK: - Background Animation

    /// Breathing animation cycle duration
    static let breathingDuration: TimeInterval = 4.0

    /// Mesh gradient animation
    static let meshGradient = Animation.easeInOut(duration: 3.0)
}

// MARK: - Reduce Motion Support

extension Animation {
    /// Returns the animation or nil-equivalent if reduce motion is enabled
    static func ifAllowed(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// MARK: - Transition Presets

extension AnyTransition {
    /// Standard scale + opacity for popups
    static let popup = AnyTransition.scale(scale: 0.9).combined(with: .opacity)

    /// Slide up with fade for bottom sheets
    static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)

    /// Badge-style entrance
    static let badge = AnyTransition.scale(scale: 0.5).combined(with: .opacity)
}
