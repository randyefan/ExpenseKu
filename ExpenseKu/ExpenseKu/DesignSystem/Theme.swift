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

    /// A muted pastel fill for a category icon, derived deterministically from its name.
    static func categoryTint(_ seed: String) -> Color {
        let hues: [Double] = [0.03, 0.09, 0.13, 0.33, 0.55, 0.72, 0.85]
        let idx = abs(seed.hashValue) % hues.count
        return Color(hue: hues[idx], saturation: 0.28, brightness: 0.96)
    }

    private static func adaptive(light: UInt, dark: UInt) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(Color(hex: isDark ? dark : light))
        })
        #else
        return Color(hex: light)
        #endif
    }
}
