//
//  ExpenseAccountLabel.swift
//  ExpenseKu
//
//  The Account's name under an expense's amount (docs/prd/bank-logos.md §5.5). The
//  row's leading mark already draws the Account, so the name carries no mark of its own.
//  The name gives way before the note does, so a long Account name truncates at a capped
//  width rather than squeezing the row's middle.
//

import SwiftUI

struct ExpenseAccountLabel: View {
    let account: Account

    @ScaledMetric(relativeTo: .caption) private var nameWidth: CGFloat = 130

    var body: some View {
        Text(account.name)
            .font(.dsCaption)
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
            .truncationMode(.tail)
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
