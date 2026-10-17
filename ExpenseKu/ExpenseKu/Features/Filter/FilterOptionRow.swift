//
//  FilterOptionRow.swift
//  ExpenseKu
//
//  One row of a filter checklist: the entity's own icon or avatar, its name, and its mark —
//  an empty circle, the accent check for Only, or nosign in red for Hidden, which also dims
//  the name (docs/prd/expense-filter.md §4.9). The empty value wears a dashed circle.
//

import SwiftUI

struct FilterOptionRow: View {
    let option: FilterOption
    let dimension: FilterDimension
    let mark: FilterMark?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                icon
                    .accessibilityHidden(true)
                Text(option.name)
                    .font(.dsBody)
                    .foregroundStyle(mark == .hidden ? Theme.textSecondary : Theme.text)
                Spacer()
                markImage
                    .font(.title3)
            }
        }
        .listRowBackground(Theme.card)
        .accessibilityAddTraits(mark == .only ? .isSelected : [])
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var markImage: some View {
        switch mark {
        case .only:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
        case .hidden:
            Image(systemName: "nosign").foregroundStyle(Theme.negative)
        case nil:
            Image(systemName: "circle").foregroundStyle(Theme.textSecondary.opacity(0.5))
        }
    }

    private var accessibilityValue: String {
        switch mark {
        case .only: "Only"
        case .hidden: "Hidden"
        case nil: ""
        }
    }

    @ViewBuilder
    private var icon: some View {
        if option.choice == .none {
            CategoryIcon(symbol: "circle.dashed", tint: Theme.textSecondary, size: Metric.rowIconSize)
        } else if dimension == .person {
            PersonAvatar(name: option.name, colorHex: option.colorHex, size: Metric.rowIconSize)
        } else if dimension == .account {
            AccountIcon(name: option.name, symbol: option.symbol ?? Account.defaultSymbol,
                        colorHex: option.colorHex, brandID: option.brandID, size: Metric.rowIconSize)
        } else {
            CategoryIcon(name: option.name, systemImage: option.symbol, colorHex: option.colorHex,
                         size: Metric.rowIconSize)
        }
    }
}
