//
//  AccountIcon.swift
//  ExpenseKu — DesignSystem
//
//  An Account's circle: its bank logo when the catalog has one, otherwise the pastel
//  CategoryIcon with the bank glyph or its own symbol (docs/prd/bank-logos.md §5.3).
//  Takes plain values as well as the model, because Insights and the filter sheet
//  draw accounts from derived rows that never hold one.
//

import SwiftUI

struct AccountIcon: View {
    let name: String
    let symbol: String
    let colorHex: String?
    let brandID: String?
    var size: CGFloat = Metric.iconSize
    var logoInset: CGFloat = BankLogoMark.standardInset

    @Environment(BankLogoCatalog.self) private var catalog: BankLogoCatalog?

    var body: some View {
        let catalog = catalog ?? .fallback
        let logo = catalog.logo(for: brandID)
        switch AccountAppearance.mark(brandID: brandID, symbol: symbol, logo: logo) {
        case .logo(let logo):
            BankLogoMark(logo: logo, size: size, inset: logoInset)
        case .symbol(let symbol):
            CategoryIcon(symbol: symbol, tint: catalog.tint(colorHex: colorHex, brandID: brandID, seed: name), size: size)
        }
    }
}

extension AccountIcon {
    init(account: Account, size: CGFloat = Metric.iconSize,
         logoInset: CGFloat = BankLogoMark.standardInset) {
        self.init(name: account.name, symbol: account.resolvedSymbol, colorHex: account.colorHex,
                  brandID: account.brandID, size: size, logoInset: logoInset)
    }
}

extension BankLogoCatalog {
    /// An Account's tint, its brand colour standing in for Auto (§5.4).
    func tint(colorHex: String?, brandID: String?, seed: String) -> Color {
        Theme.categoryTint(hex: AccountAppearance.colorHex(colorHex, logo: logo(for: brandID)), seed: seed)
    }
}

#Preview {
    HStack {
        AccountIcon(name: "BCA Gaji", symbol: "creditcard.fill", colorHex: nil, brandID: "bca")
        AccountIcon(name: "Mandiri Tabungan", symbol: "creditcard.fill", colorHex: nil, brandID: "withdrawn")
        AccountIcon(name: "GoPay", symbol: "wallet.pass.fill", colorHex: nil, brandID: nil)
    }
    .padding()
    .appBackground()
}
