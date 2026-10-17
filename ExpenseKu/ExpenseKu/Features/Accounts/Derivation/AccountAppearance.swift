//
//  AccountAppearance.swift
//  ExpenseKu
//
//  How an Account is drawn now that it can wear a bank logo (docs/prd/bank-logos.md
//  §5.3–5.4): its mark, the glyph its small chips carry, and the colour its tint
//  starts from. Resolved on every draw from the catalog as it stands, never stamped
//  on save, so a logo the developer replaces or withdraws reaches every Account
//  that names it.
//

import Foundation

nonisolated enum AccountMark: Hashable {
    case logo(BankLogo)
    case symbol(String)
}

nonisolated enum AccountAppearance {
    static let bankSymbol = "building.columns.fill"

    /// `logo` is the catalog's entry for `brandID`, nil when it has none.
    static func mark(brandID: String?, symbol: String, logo: BankLogo?) -> AccountMark {
        if let logo { return .logo(logo) }
        return .symbol(brandID == nil ? symbol : bankSymbol)
    }

    /// Plan chips and section headers are too small for a logo; a branded Account
    /// still reads as a bank there.
    static func chipSymbol(brandID: String?, symbol: String) -> String {
        brandID == nil ? symbol : bankSymbol
    }

    /// The owner's colour when set; with Auto colour, the logo's brand colour passed
    /// through the palette's pastel recipe; nil hands the tint back to the name.
    static func colorHex(_ colorHex: String?, logo: BankLogo?) -> String? {
        if let colorHex { return colorHex }
        guard let logo, let hue = HexColor.hue(logo.tintHex) else { return nil }
        return AppearancePalette.hex(forHue: hue)
    }
}
