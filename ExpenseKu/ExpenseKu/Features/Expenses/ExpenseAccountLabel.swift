//
//  ExpenseAccountLabel.swift
//  ExpenseKu
//
//  The Account under an expense's amount: its mark, then its name
//  (docs/prd/bank-logos.md §5.5). The name gives way before the note does, so a long
//  Account name truncates at a capped width rather than squeezing the row's middle.
//

import SwiftUI

struct ExpenseAccountLabel: View {
    let account: Account

    @ScaledMetric(relativeTo: .caption) private var markSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var nameWidth: CGFloat = 130

    var body: some View {
        HStack(spacing: 4) {
            AccountIcon(account: account, size: markSize)
                .accessibilityHidden(true)
            Text(account.name)
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: nameWidth, alignment: .trailing)
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: 8) {
        ExpenseAccountLabel(account: Account(name: "GoPay", iconName: "wallet.pass.fill"))
        ExpenseAccountLabel(account: Account(name: "A very long account name for a bank"))
    }
    .padding()
    .appBackground()
}
