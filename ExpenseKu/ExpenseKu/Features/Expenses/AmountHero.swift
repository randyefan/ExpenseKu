//
//  AmountHero.swift
//  ExpenseKu
//
//  The editor's page-top amount: the calculator's working line above the `Rp` result.
//

import SwiftUI

struct AmountHero: View {
    let displayExpression: String
    let amount: Decimal

    var body: some View {
        VStack(spacing: 4) {
            if !displayExpression.isEmpty {
                Text(displayExpression)
                    .font(.dsBody)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Rp")
                    .font(.dsTitle).fontWeight(.semibold)
                    .foregroundStyle(Theme.textSecondary)
                Text(amount.formatted(.number.precision(.fractionLength(0))))
                    .font(.jakarta(48, relativeTo: .largeTitle)).fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(amount > 0 ? Theme.text : Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
