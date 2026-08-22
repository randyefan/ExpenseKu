//
//  AccentCircleButton.swift
//  ExpenseKu — DesignSystem
//
//  The circular accent "+" button used in toolbars.
//

import SwiftUI

/// The circular accent "+" button used in toolbars. Rendered with the system's
/// prominent circular button so it stays a true circle inside the toolbar's own
/// button chrome (a custom fixed-size Circle background gets clipped there).
private struct AccentCircleButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        // On Mac (the app ships as "Designed for iPad", so it's still a pure
        // iOS binary — no compile-time `os(macOS)`/`macCatalyst` flag fires) the
        // toolbar strips the prominent button's fill/tint and only a faint glyph
        // shows. Detect that at runtime and draw the coral circle explicitly.
        if runningOnMac {
            content
                .labelStyle(.iconOnly)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Theme.accent, in: Circle())
                .buttonStyle(.plain)
        } else {
            content
                .labelStyle(.iconOnly)
                .font(.body.weight(.bold))
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Theme.accent)
        }
    }

    private var runningOnMac: Bool {
        let info = ProcessInfo.processInfo
        return info.isiOSAppOnMac || info.isMacCatalystApp
    }
}

extension View {
    /// Styles a toolbar `Button` (with a `Label`) as the accent "+" circle.
    func accentCircleButton() -> some View { modifier(AccentCircleButton()) }
}
