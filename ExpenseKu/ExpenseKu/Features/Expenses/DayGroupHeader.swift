//
//  DayGroupHeader.swift
//  ExpenseKu
//
//  A day's section header: the day's name on the left, its total on the right. The
//  total stays quiet, secondary and monospaced — the coral hero accent is reserved for
//  the cycle total (Variant A).
//

import SwiftUI

struct DayGroupHeader: View {
    let title: String
    let total: Decimal

    var body: some View {
        HStack {
            SectionHeaderText(title)
            Spacer()
            Text(total.formattedIDR())
                .font(.dsCaption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 4)
    }
}
