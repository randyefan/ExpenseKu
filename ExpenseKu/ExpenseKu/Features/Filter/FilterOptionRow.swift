//
//  FilterOptionRow.swift
//  ExpenseKu
//
//  One tickable row of a filter checklist: the entity's own icon or avatar, its name, and
//  the picker's check circle. The empty value wears a dashed circle in a neutral tint.
//

import SwiftUI

struct FilterOptionRow: View {
    let option: FilterOption
    let dimension: FilterDimension
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                icon
                    .accessibilityHidden(true)
                Text(option.name)
                    .font(.dsBody)
                    .foregroundStyle(Theme.text)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? Theme.accent : Theme.textSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Theme.card)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    @ViewBuilder
    private var icon: some View {
        if option.choice == .none {
            CategoryIcon(symbol: "circle.dashed", tint: Theme.textSecondary, size: Metric.rowIconSize)
        } else if dimension == .person {
            PersonAvatar(name: option.name, colorHex: option.colorHex, size: Metric.rowIconSize)
        } else {
            CategoryIcon(name: option.name, systemImage: option.symbol, colorHex: option.colorHex,
                         size: Metric.rowIconSize)
        }
    }
}
