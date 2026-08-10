//
//  Theme.swift
//  ExpenseKu — DesignSystem
//
//  "Warm Cards" color tokens (see .scratch/revamp/spec.md). Colors adapt to
//  light/dark at resolve time so `Theme.bg` etc. can be used as plain statics.
//  Cross-platform: UIKit on iOS/iPadOS, AppKit on macOS.
//

import SwiftUI

extension Color {
    /// 0xRRGGBB literal → Color.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum Theme {
    /// The single reserved accent. Same in light + dark.
    static let accent = Color(hex: 0xE8735C)

    static let bg             = adaptive(light: 0xFBF7F3, dark: 0x17130F)
    static let card           = adaptive(light: 0xFFFFFF, dark: 0x211C1A)
    static let hairline       = adaptive(light: 0xEFE8E1, dark: 0x2E2825)
    static let text           = adaptive(light: 0x2A2320, dark: 0xF5F0EC)
    static let textSecondary  = adaptive(light: 0x8A817C, dark: 0xA79E98)

    /// A muted tint fill for a category icon, derived deterministically from its
    /// name. Adapts to the interface style so the glyph on top keeps its contrast:
    /// a light pastel in light mode, a deep muted tone in dark mode.
    static func categoryTint(_ seed: String) -> Color {
        let hues: [Double] = [0.03, 0.09, 0.13, 0.33, 0.55, 0.72, 0.85]
        let hue = hues[abs(seed.hashValue) % hues.count]
        let light = Color(hue: hue, saturation: 0.28, brightness: 0.96)
        let dark  = Color(hue: hue, saturation: 0.32, brightness: 0.30)
        return adaptive(light: light, dark: dark)
    }

    private static func adaptive(light: UInt, dark: UInt) -> Color {
        adaptive(light: Color(hex: light), dark: Color(hex: dark))
    }

    private static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        })
        #else
        return light
        #endif
    }
}
