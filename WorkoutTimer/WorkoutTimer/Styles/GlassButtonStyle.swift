import SwiftUI

/// Modern button style with spring animation for press feedback
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.15, bounce: 0.3), value: configuration.isPressed)
    }
}

/// Button style with more pronounced press effect for primary actions
struct PrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.35), value: configuration.isPressed)
    }
}

/// Button style for icon-only buttons (reset, etc.)
struct IconGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.15, bounce: 0.4), value: configuration.isPressed)
    }
}

// MARK: - Glass Effect View Modifiers

extension View {
    /// Applies glass effect with material background
    /// Note: When iOS 26 ships, this can be updated to use `.glassEffect()`
    @ViewBuilder
    func glassBackground(
        cornerRadius: CGFloat = 16,
        prominent: Bool = false
    ) -> some View {
        self.background(
            prominent ? .regularMaterial : .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: cornerRadius)
        )
    }

    /// Applies interactive glass effect for buttons
    @ViewBuilder
    func interactiveGlassBackground(cornerRadius: CGFloat = 16) -> some View {
        self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Applies a capsule-shaped glass background
    @ViewBuilder
    func glassCapsule(prominent: Bool = false) -> some View {
        self.background(
            prominent ? .regularMaterial : .ultraThinMaterial,
            in: Capsule()
        )
    }

    /// Applies a circular glass background
    @ViewBuilder
    func glassCircle(prominent: Bool = false) -> some View {
        self.background(
            prominent ? .regularMaterial : .ultraThinMaterial,
            in: Circle()
        )
    }

    /// Soft inner shadow effect for depth
    func softInnerShadow(radius: CGFloat = 4) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Custom Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .glassBackground(cornerRadius: cornerRadius)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Legacy ScaleButtonStyle (kept for compatibility)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.15, bounce: 0.3), value: configuration.isPressed)
    }
}
