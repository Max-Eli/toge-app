import SwiftUI

enum Theme {
    // MARK: - Colors
    static let bg = Color(red: 0.035, green: 0.035, blue: 0.043)         // #09090b
    static let card = Color(red: 0.094, green: 0.094, blue: 0.106)       // #18181b
    static let cardHover = Color(red: 0.153, green: 0.153, blue: 0.165)  // #27272a
    static let border = Color(red: 0.153, green: 0.153, blue: 0.165)     // #27272a
    static let accent = Color(red: 0.882, green: 0.114, blue: 0.282)     // #e11d48
    static let accentHover = Color(red: 0.745, green: 0.071, blue: 0.235) // #be123c
    static let accentSoft = Color(red: 0.882, green: 0.114, blue: 0.282).opacity(0.12)
    static let muted = Color(red: 0.631, green: 0.631, blue: 0.667)      // #a1a1aa
    static let foreground = Color(red: 0.98, green: 0.98, blue: 0.98)    // #fafafa
    static let destructive = Color(red: 0.95, green: 0.3, blue: 0.3)
    static let success = Color(red: 0.2, green: 0.8, blue: 0.5)

    // MARK: - Corner Radii
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 20
    static let radiusFull: CGFloat = 100
}

// MARK: - Frosted Glass Modifier
struct FrostedGlass: ViewModifier {
    var cornerRadius: CGFloat = Theme.radiusLg

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func frostedGlass(cornerRadius: CGFloat = Theme.radiusLg) -> some View {
        modifier(FrostedGlass(cornerRadius: cornerRadius))
    }
}
