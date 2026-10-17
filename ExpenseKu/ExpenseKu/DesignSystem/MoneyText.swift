//
//  MoneyText.swift
//  ExpenseKu — DesignSystem
//
//  An amount, bold and monospaced so columns of figures line up.
//
//  A figure never wraps: at accessibility text sizes "Rp 120.000" was breaking
//  across lines mid-number, and a smaller figure reads better than a broken one.
//  The scale-down is for width only: a List row proposes its content less height
//  than it asks for, and the plan totals, drift strip and split chips used to
//  shrink to 0.6 to fit that height with the whole row's width to spare.
//
//  Set `rolls` where the figure answers a question the owner just changed — the
//  cycle total after paging, a filtered sum. The digits then count to the new value
//  instead of cutting. Figures that only ever appear (a row's amount) leave it off:
//  data being read must not move for style.
//

import SwiftUI

struct MoneyText: View {
    let amount: Decimal
    var font: Font = .dsBody
    var color: Color = Theme.text
    var rolls: Bool = false
    var showsPlus: Bool = false

    init(_ amount: Decimal, font: Font = .dsBody, color: Color = Theme.text, rolls: Bool = false,
         showsPlus: Bool = false) {
        self.amount = amount
        self.font = font
        self.color = color
        self.rolls = rolls
        self.showsPlus = showsPlus
    }

    var body: some View {
        Text((showsPlus && amount > 0 ? "+" : "") + amount.formattedIDR())
            .font(font)
            .bold()
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(rolls ? .numericText(value: (amount as NSDecimalNumber).doubleValue) : .identity)
            .motion(Motion.number, value: rolls ? amount : 0)
    }
}

#Preview {
    @Previewable @State var amount: Decimal = 220_000
    VStack(alignment: .trailing, spacing: Metric.cardGap) {
        MoneyText(0)
        MoneyText(25_000)
        MoneyText(1_250_000)
        MoneyText(amount, font: .dsHero, color: Theme.text, rolls: true)
        Button("Roll") { amount = Decimal(Int.random(in: 10_000...9_000_000)) }
    }
    .padding()
    .appBackground()
}
