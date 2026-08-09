//
//  Typography.swift
//  ExpenseKu — DesignSystem
//
//  Plus Jakarta Sans, registered at runtime from the bundled variable font
//  (DesignSystem/Fonts/PlusJakartaSans.ttf) so no Info.plist UIAppFonts entry
//  is needed. All type flows through `.jakarta(...)`, which is Dynamic-Type
//  aware via `relativeTo:` and falls back to the system font if registration
//  ever fails.
//

import SwiftUI
import CoreText

enum AppFont {
    /// The family name of the bundled variable font, once registered.
    static let family = "Plus Jakarta Sans"

    private static var didRegister = false

    /// Register the bundled font. Call once at app launch. Idempotent.
    static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true
        guard let url = Bundle.main.url(forResource: "PlusJakartaSans", withExtension: "ttf") else {
            return
        }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }
}

extension Font {
    /// Plus Jakarta Sans at `size`, scaling with Dynamic Type relative to `style`.
    /// Apply weight at the call site with `.fontWeight(_:)`.
    static func jakarta(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(AppFont.family, size: size, relativeTo: style)
    }
}

extension Font {
    /// Named roles used across the revamp.
    static let dsLargeTitle = jakarta(28, relativeTo: .largeTitle)
    static let dsTitle      = jakarta(22, relativeTo: .title)
    static let dsHeadline   = jakarta(17, relativeTo: .headline)
    static let dsBody       = jakarta(16, relativeTo: .body)
    static let dsSubhead    = jakarta(14, relativeTo: .subheadline)
    static let dsCaption    = jakarta(12, relativeTo: .caption)
    /// Big hero number (cycle total). Weight/monospacing applied by `MoneyText`.
    static let dsHero       = jakarta(30, relativeTo: .largeTitle)
}
