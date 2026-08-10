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

    /// "RRGGBB" / "#RRGGBB" string → Color, or nil if it can't be parsed.
    init?(hexString: String) {
        guard let rgb = HexColor.rgb(hexString) else { return nil }
        self.init(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1)
    }
}

/// Small sRGB ⇄ hex ⇄ HSB helpers for owner-chosen swatches. Kept dependency-free
/// so the palette can round-trip a stored hex back into an adaptive tint.
enum HexColor {
    /// Parses "RRGGBB" (optionally "#"-prefixed) into 0…1 channels.
    static func rgb(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        return (Double((v >> 16) & 0xFF) / 255,
                Double((v >> 8) & 0xFF) / 255,
                Double(v & 0xFF) / 255)
    }

    /// The hue (0…1) of a hex color, or nil if unparseable.
    static func hue(_ hex: String) -> Double? {
        guard let (r, g, b) = rgb(hex) else { return nil }
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        guard d > 0 else { return 0 }
        var h: Double
        switch mx {
        case r: h = ((g - b) / d).truncatingRemainder(dividingBy: 6)
        case g: h = (b - r) / d + 2
        default: h = (r - g) / d + 4
        }
        h /= 6
        return h < 0 ? h + 1 : h
    }

    /// HSB → "RRGGBB" (used to author the palette swatches from hues).
    static func hexString(hue h: Double, saturation s: Double, brightness v: Double) -> String {
        let i = Int(floor(h * 6)) % 6
        let f = h * 6 - floor(h * 6)
        let p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
        let (r, g, b): (Double, Double, Double)
        switch (i + 6) % 6 {
        case 0: (r, g, b) = (v, t, p)
        case 1: (r, g, b) = (q, v, p)
        case 2: (r, g, b) = (p, v, t)
        case 3: (r, g, b) = (p, q, v)
        case 4: (r, g, b) = (t, p, v)
        default: (r, g, b) = (v, p, q)
        }
        return String(format: "%02X%02X%02X",
                      Int(r * 255 + 0.5), Int(g * 255 + 0.5), Int(b * 255 + 0.5))
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
        return tint(hue: hues[abs(seed.hashValue) % hues.count])
    }

    /// The tint for an entity: its owner-chosen swatch when set (an "RRGGBB" hex),
    /// otherwise the name-derived `categoryTint`. A stored hex is shown verbatim in
    /// light mode and rebuilt as a deep tone from the same hue in dark mode, so the
    /// glyph keeps its contrast in both — matching the auto tints.
    static func categoryTint(hex: String?, seed: String) -> Color {
        guard let hex, let light = Color(hexString: hex), let hue = HexColor.hue(hex) else {
            return categoryTint(seed)
        }
        return adaptive(light: light, dark: Color(hue: hue, saturation: 0.32, brightness: 0.30))
    }

    /// The pastel(light)/deep(dark) adaptive pair for a hue — the shared recipe
    /// behind both the auto tints and the swatch palette.
    static func tint(hue: Double) -> Color {
        adaptive(
            light: Color(hue: hue, saturation: 0.28, brightness: 0.96),
            dark:  Color(hue: hue, saturation: 0.32, brightness: 0.30)
        )
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
