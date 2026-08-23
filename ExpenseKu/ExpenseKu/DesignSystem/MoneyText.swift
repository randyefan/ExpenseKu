//
//  MoneyText.swift
//  ExpenseKu — DesignSystem
//
//  An amount, bold and monospaced so columns of figures line up.
//

import SwiftUI

struct MoneyText: View {
    let amount: Decimal
    var font: Font = .dsBody
    var color: Color = Theme.text
    init(_ amount: Decimal, font: Font = .dsBody, color: Color = Theme.text) {
        self.amount = amount; self.font = font; self.color = color
    }
    var body: some View {
        Text(amount.formattedIDR())
            .font(font)
            .bold()
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: Metric.cardGap) {
        MoneyText(0)
        MoneyText(25_000)
        MoneyText(1_250_000)
        MoneyText(999_999_999, font: .dsHero, color: Theme.accent)
    }
    .padding()
    .warmBackground()
}
