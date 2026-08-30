//
//  ByPayPeriodTag.swift
//  ExpenseKu
//
//  The granularity tag on the spend-over-time card. Pay period is the only granularity
//  the chart currently offers, so this states it rather than offering a choice. Each
//  bucket is named by the month its cycle ends in, the same convention as the Expenses
//  tab's cycle title (ADR-0004).
//

import SwiftUI

struct ByPayPeriodTag: View {
    var body: some View {
        Text("By pay period")
            .font(.dsCaption).fontWeight(.semibold)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Theme.textSecondary.opacity(0.1), in: Capsule())
    }
}
