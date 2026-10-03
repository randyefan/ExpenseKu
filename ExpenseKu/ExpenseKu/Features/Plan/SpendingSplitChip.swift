//
//  SpendingSplitChip.swift
//  ExpenseKu
//
//  One half of the split legend and its filter Button.
//

import SwiftUI

/// One half of the split legend, and the switch that filters the lens to it. Outlined
/// whether lit or not, so lighting one moves nothing (plan-filter.md §4.1).
struct SpendingSplitChip: View {
    let half: PlanFilter
    let amount: Decimal
    let isLit: Bool
    let alignment: HorizontalAlignment
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: alignment, spacing: 3) {
                HStack(spacing: 6) {
                    marker
                    Text(half.title)
                        .font(.dsCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                MoneyText(amount, font: .dsSubhead, color: Theme.text, rolls: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isLit ? half.tint.opacity(Theme.tintFillOpacity) : .clear)
                    .strokeBorder(isLit ? half.tint : Theme.hairline, lineWidth: isLit ? 1.5 : 1)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.pressableCard)
        .motion(Motion.press, value: isLit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(half.title)
        .accessibilityValue(amount.formattedIDR())
        .accessibilityAddTraits(isLit ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var marker: some View {
        if isLit {
            Image(systemName: "checkmark")
                .font(.dsCaption.weight(.bold))
                .imageScale(.small)
                .foregroundStyle(half.tint)
                .frame(width: 8, height: 8)
        } else {
            Circle()
                .fill(half.tint)
                .frame(width: 8, height: 8)
        }
    }
}
