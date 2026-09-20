//
//  DormantRow.swift
//  ExpenseKu
//
//  A carried-over item at Rp 0 that has not been used this cycle. Dimmed, with when it
//  was last in use, and one tap to bring it back.
//
//  It keeps the reminder the owner wanted from the spreadsheet without letting it cost
//  a line of the live plan.
//

import SwiftUI

struct DormantRow: View {
    let item: PlanItem
    let payday: Int
    let calendar: Calendar
    let onActivate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 18))
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.isEmpty ? "Untitled" : item.name)
                    .font(.dsBody)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button("Activate", action: onActivate)
                .font(.dsCaption).bold()
                .foregroundStyle(Theme.accentText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.accent.opacity(Theme.tintFillOpacity), in: .capsule)
                .buttonStyle(.pressableCard)
                .accessibilityLabel("Activate \(item.name)")
        }
        .padding(.vertical, 8)
    }

    private var subtitle: String {
        guard let last = item.lastUsedCycleStart else { return item.amount.formattedIDR() }
        let cycle = PayCycle.containing(last, payday: payday, calendar: calendar)
        return "\(item.amount.formattedIDR()) · last used \(cycle.title(calendar: calendar))"
    }
}
