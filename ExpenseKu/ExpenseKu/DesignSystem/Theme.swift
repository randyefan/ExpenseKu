//
//  Theme.swift
//  ExpenseKu — DesignSystem
//
//  "Ink & Amber" colour tokens (see .scratch/revamp2/spec.md). A near-black
//  graphite canvas with soft off-white cards and one warm amber accent, replacing
//  the earlier cream/coral "Warm Cards" palette.
//
//  Dark is the designed theme and light is the faithful alternate, so every pair
//  below is authored dark-first. The app is locked to dark (UIUserInterfaceStyle
//  in Info.plist); the light values are kept, unused, for a future light theme.
//
//  Colours adapt at resolve time, so `Theme.bg` etc. can be used as plain statics.
//

import SwiftUI

nonisolated extension Color {
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
nonisolated enum HexColor {
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
    /// The single reserved accent, used for fills: the + button, the active tab,
    /// selected chips, the current period's bar. Identical in both themes so the
    /// brand colour never shifts.
    static let accent = Color(hex: 0xF2A93B)

    /// The accent as *text or a glyph*. Amber on a white card is around 2:1, which
    /// fails contrast, so light mode uses a deepened amber while dark mode keeps
    /// the brand value.
    static let accentText = adaptive(light: 0xA1660A, dark: 0xF2A93B)

    /// What sits on top of an accent fill. Amber is a light colour: ink reads on it
    /// at roughly 9:1 where white manages under 2:1.
    static let onAccent = Color(hex: 0x14161A)

    static let bg             = adaptive(light: 0xF7F6F4, dark: 0x0E0F11)
    static let card           = adaptive(light: 0xFFFFFF, dark: 0x191B1F)
    /// One step above `card`, for a control track or an inset well.
    static let surface        = adaptive(light: 0xF0EEEB, dark: 0x22252A)
    static let hairline       = adaptive(light: 0xE7E4E0, dark: 0x2A2E34)
    static let text           = adaptive(light: 0x16181C, dark: 0xF2F3F5)
    static let textSecondary  = adaptive(light: 0x6E737A, dark: 0x9AA0A8)

    /// Money that has run past where it was meant to: envelope overspend, a plan
    /// that allocates more than it earns, a negative transfer adjustment, and the
    /// destructive confirmations that delete an expense.
    ///
    /// Added for the cycle plan. Until then the app had nothing but the accent, and
    /// the accent is reserved for actions and selected states — a figure in amber
    /// reads as "tap me", not as "this is over". The values are `tint-red` from
    /// design/ExpenseKu.pen; light mode deepens it because the pen value is authored
    /// for ink and manages about 2.4:1 on paper.
    static let negative     = adaptive(light: 0xB23636, dark: 0xE66767)
    /// `negative` at the 18% the design system uses for every tinted fill.
    static var negativeWash: Color { negative.opacity(0.18) }

    /// The counterpart, for an envelope still inside its allowance. Used sparingly —
    /// being on plan is the ordinary case and mostly reads as `textSecondary`.
    static let positive     = adaptive(light: 0x40B236, dark: 0x71E667)

    static let plan         = adaptive(light: 0x5E36B2, dark: 0x9067E6)
    static var planWash: Color { plan.opacity(tintFillOpacity) }

    /// The `bg` token as an adaptive `UIColor`, for UIKit appearance proxies
    /// (e.g. painting nav bars — see `configureBarAppearance()`).
    static let bgUIColor = dynamicUIColor(light: Color(hex: 0xF7F6F4), dark: Color(hex: 0x0E0F11))

    /// Paint navigation bars with `bg` and no hairline shadow, so the bar blends
    /// into the surface on every platform. On a Designed-for-iPad Mac build the
    /// `NavigationSplitView` sidebar bar ignores SwiftUI's `.toolbarBackground`, so
    /// this proxy is the reliable path. Call once at launch (ExpenseKuApp.init).
    static func configureBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bgUIColor
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    /// A muted tint fill for a category icon, derived deterministically from its
    /// name. Adapts to the interface style so the glyph on top keeps its contrast:
    /// a light pastel on paper, a deep saturated tone on ink.
    nonisolated static func categoryTint(_ seed: String) -> Color {
        let hues: [Double] = [0.03, 0.09, 0.13, 0.33, 0.55, 0.72, 0.85]
        return tint(hue: hues[stableIndex(seed, upperBound: hues.count)])
    }

    nonisolated static func stableIndex(_ seed: String, upperBound: Int) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Int(hash % UInt64(upperBound))
    }

    /// The tint for an entity: the hue of its owner-chosen swatch when set (an
    /// "RRGGBB" hex), otherwise the name-derived hue. Only the *hue* is taken from
    /// storage — the saturation and brightness come from `tint(hue:)` — so the
    /// stored pastels written by the older palette still resolve correctly.
    nonisolated static func categoryTint(hex: String?, seed: String) -> Color {
        guard let hex, let hue = HexColor.hue(hex) else {
            return categoryTint(seed)
        }
        return tint(hue: hue)
    }

    /// An entity's identity colour, at full chroma in both themes.
    ///
    /// The earlier cream palette made these a pastel *fill* with a dark glyph on
    /// top. On an ink canvas that recipe goes muddy — a 40%-brightness circle on a
    /// near-black card is just a brown smudge — so a tint is now the chromatic
    /// colour itself, and `CategoryIcon` washes it back to a fill.
    nonisolated static func tint(hue: Double) -> Color {
        adaptive(
            light: Color(hue: hue, saturation: 0.70, brightness: 0.70),
            dark:  Color(hue: hue, saturation: 0.55, brightness: 0.90)
        )
    }

    /// How much of a tint a filled surface (an icon's circle, a chip) takes.
    static let tintFillOpacity: Double = 0.18

    /// What reads *on top of* a solid tint — the one place a glyph sits on the
    /// chromatic colour itself rather than on a wash of it. `tint(hue:)` inverts
    /// between the themes (dark and saturated in light mode, bright in dark mode),
    /// so this has to invert with it: a fixed ink glyph vanishes on a light-mode
    /// swatch, and a fixed white one vanishes on a dark-mode swatch.
    static let onTint = adaptive(light: 0xFFFFFF, dark: 0x14161A)

    nonisolated private static func adaptive(light: UInt, dark: UInt) -> Color {
        adaptive(light: Color(hex: light), dark: Color(hex: dark))
    }

    nonisolated private static func adaptive(light: Color, dark: Color) -> Color {
        Color(uiColor: dynamicUIColor(light: light, dark: dark))
    }

    /// The trait-resolving closure must be `nonisolated`: UIKit resolves dynamic
    /// colours on whichever thread is rendering, and SwiftUI renders off the main
    /// thread once a screen is animating. A main-actor-isolated closure traps there
    /// under Swift 6 (`_swift_task_checkIsolatedSwift`), which is a crash rather than
    /// a warning — the project sets SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, so
    /// this has to be opted out of explicitly.
    nonisolated private static func dynamicUIColor(light: Color, dark: Color) -> UIColor {
        UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}
