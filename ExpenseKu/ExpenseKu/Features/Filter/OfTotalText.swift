//
//  OfTotalText.swift
//  ExpenseKu
//
//  The whole under a filtered SPENDING figure: "of Rp 4.570.000" (docs/prd/expense-filter.md
//  §4.5).
//

import SwiftUI

struct OfTotalText: View {
    let total: Decimal

    var body: some View {
        Text("of \(total.formattedIDR())")
            .font(.dsSubhead).fontWeight(.semibold)
            .foregroundStyle(Theme.textSecondary)
            .contentTransition(.numericText())
    }
}

#Preview {
    OfTotalText(total: 4_570_000)
        .padding()
        .appBackground()
}
