//
//  DormantHeader.swift
//  ExpenseKu
//
//  The disclosure row over the carried-over items that are not in use this cycle.
//
//  The spreadsheet keeps those rows deliberately — they are reminders ("don't forget
//  Liburan Saving") — but they accumulate: 11 dead rows in January, 18 by September.
//  On a phone that is the whole screen. Folding them keeps the reminder and drops the
//  clutter, which is the one place this should beat the spreadsheet rather than copy
//  it (PRD §7.2).
//

import SwiftUI

struct DormantHeader: View {
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                SectionHeaderText("From last cycle")
                Text("\(count)")
                    .font(.dsCaption).fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.textSecondary.opacity(0.12), in: .capsule)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .motion(Motion.snap, value: isExpanded)
        .accessibilityLabel("From last cycle, \(count) items")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityAddTraits(.isButton)
    }
}
