//
//  PlanAccountChip.swift
//  ExpenseKu
//
//  A plan chip naming an Account (docs/prd/bank-logos.md §5.6.3). A bank keeps the grey
//  chip, but its glyph becomes a small white plate with the cropped wordmark; the name
//  follows it so two Accounts at one bank never look alike. An Account without a logo,
//  or with one withdrawn, is the plain PlanChip it always was.
//
//  A row whose chips do not fit on one line drops the name before anything else gives
//  way, so the row asks for `showsName: false` through a ViewThatFits.
//

import SwiftUI

extension EnvironmentValues {
    /// Off inside a bank group of the Account order, whose header names the Account
    /// once (§5.6.2).
    @Entry var planRowsShowAccount = true
}

struct PlanAccountChip: View {
    let account: Account
    var showsName = true

    @ScaledMetric(relativeTo: .caption) private var plateHeight: CGFloat = 15
    @Environment(BankLogoCatalog.self) private var catalog: BankLogoCatalog?

    var body: some View {
        let catalog = catalog ?? .fallback
        if let logo = catalog.logo(for: account.brandID) {
            HStack(spacing: 5) {
                catalog.wordmark(for: logo)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.black.opacity(0.45))
                    .frame(height: plateHeight * 9 / 15)
                    .padding(.horizontal, plateHeight * 4 / 15)
                    .frame(height: plateHeight)
                    .background(.white, in: .rect(cornerRadius: plateHeight * 4 / 15))
                if showsName {
                    Text(account.name)
                        .font(.dsCaption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, showsName ? 8 : 4)
            .padding(.vertical, 4)
            .background(Theme.textSecondary.opacity(0.12), in: .capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(account.name)
        } else {
            PlanChip(kind: .account, text: account.name, symbol: account.chipSymbol)
        }
    }
}

#Preview {
    let bca = Account(name: "BCA")
    bca.brandID = "bca"
    let superbank = Account(name: "Superbank")
    superbank.brandID = "superbank"
    return VStack(alignment: .leading, spacing: 8) {
        PlanAccountChip(account: bca)
        PlanAccountChip(account: bca, showsName: false)
        PlanAccountChip(account: superbank)
        PlanAccountChip(account: Account(name: "Cash", iconName: "banknote.fill"))
    }
    .padding()
    .appBackground()
}
