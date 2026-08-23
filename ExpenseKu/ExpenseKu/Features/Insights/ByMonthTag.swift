//
//  ByMonthTag.swift
//  ExpenseKu
//
//  The granularity tag on the spend-over-time card. Month is the only granularity the
//  chart currently offers, so this states it rather than offering a choice.
//

import SwiftUI

struct ByMonthTag: View {
    var body: some View {
        Text("By month")
            .font(.dsCaption).fontWeight(.semibold)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Theme.textSecondary.opacity(0.1), in: Capsule())
    }
}
