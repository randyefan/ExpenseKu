//
//  AccountPlate.swift
//  ExpenseKu — DesignSystem
//
//  The landscape plate that names an Account in the Plan lens's bank headers and on
//  the Transfer checklist (docs/prd/bank-logos.md §5.6.1). Catalog logos are wide
//  wordmarks centred in a square image, so the plate draws the logo cropped to its ink
//  on white: at 28pt its letters stand about three times taller than in a circle.
//
//  An Account without a logo gets its own symbol on its pastel wash in the same shape,
//  and no Account at all (Unassigned) a grey one, so the names beside them stay in line.
//
//  Hidden from VoiceOver: the Account's name is always read beside it.
//

import SwiftUI

struct AccountPlate: View {
    /// Nil draws Unassigned.
    let style: AccountPlateStyle?

    @ScaledMetric(relativeTo: .body) private var scaledHeight: CGFloat = 28
    @Environment(BankLogoCatalog.self) private var catalog: BankLogoCatalog?

    static let unassignedSymbol = "creditcard"
    /// Past this the plate stops growing: at the accessibility sizes an uncapped 80pt
    /// plate left the name beside it a single letter.
    static let maxHeight: CGFloat = 34

    private var height: CGFloat { min(scaledHeight, Self.maxHeight) }

    var body: some View {
        let catalog = catalog ?? .fallback
        let shape = RoundedRectangle(cornerRadius: height * 8 / 28)
        Group {
            if let style {
                switch AccountAppearance.mark(brandID: style.brandID, symbol: style.symbol,
                                              logo: catalog.logo(for: style.brandID)) {
                case .logo(let logo):
                    catalog.wordmark(for: logo)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.black.opacity(0.45))
                        .padding(.vertical, height * 7 / 28)
                        .padding(.horizontal, height * 8 / 28)
                        .frame(width: width, height: height)
                        .background(.white, in: shape)
                case .symbol(let symbol):
                    let tint = catalog.tint(colorHex: style.colorHex, brandID: style.brandID, seed: style.name)
                    glyph(symbol, tint: tint, wash: tint.opacity(Theme.tintFillOpacity), shape: shape)
                }
            } else {
                glyph(Self.unassignedSymbol, tint: Theme.textSecondary,
                      wash: Theme.textSecondary.opacity(0.12), shape: shape)
            }
        }
        .accessibilityHidden(true)
    }

    private var width: CGFloat { height * 60 / 28 }

    private func glyph(_ symbol: String, tint: Color, wash: Color, shape: RoundedRectangle) -> some View {
        shape
            .fill(wash)
            .frame(width: width, height: height)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: height * 0.46, weight: .semibold))
                    .foregroundStyle(tint)
            }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(BankLogo.snapshot) { logo in
            AccountPlate(style: AccountPlateStyle(name: logo.displayName, symbol: "creditcard.fill",
                                                  colorHex: nil, brandID: logo.id))
        }
        AccountPlate(style: AccountPlateStyle(name: "Cash", symbol: "banknote.fill", colorHex: nil, brandID: nil))
        AccountPlate(style: AccountPlateStyle(name: "BCA Tabungan", symbol: "creditcard.fill",
                                              colorHex: nil, brandID: "withdrawn"))
        AccountPlate(style: nil)
    }
    .padding()
    .appBackground()
}
