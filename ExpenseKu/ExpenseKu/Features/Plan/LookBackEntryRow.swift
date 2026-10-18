//
//  LookBackEntryRow.swift
//  ExpenseKu
//
//  "Look back at October" at the plan's foot (look-back.md §4, frame AB1): the add rows'
//  shape, with a chevron because it opens a sheet rather than an editor.
//

import SwiftUI

struct LookBackEntryRow: View {
    let month: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.textSecondary.opacity(0.12))
                .frame(width: Metric.iconSize, height: Metric.iconSize)
                .overlay {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: Metric.iconSize * 0.41, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            Text(LookBackCopy.entryTitle(month))
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(Theme.accent)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.dsCaption).bold()
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
        }
    }
}
