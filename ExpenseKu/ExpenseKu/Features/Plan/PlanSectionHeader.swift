//
//  PlanSectionHeader.swift
//  ExpenseKu
//
//  The header over one group of a sorted plan (frames M3, M5): a glyph saying which
//  order is showing, then NAME · N ITEMS. A group of the Account order is a bank header
//  instead (PlanAccountHeader, bank-logos.md §5.6.2).
//

import SwiftUI

struct PlanSectionHeader: View {
    let section: PlanSection

    var body: some View {
        if case .account(let account) = section.heading {
            PlanAccountHeader(account: account, items: section.items)
        } else {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                SectionHeaderText(section.title ?? "")
            }
        }
    }

    private var symbol: String {
        switch section.heading {
        case .group(let group): group?.resolvedSymbol ?? "tray"
        case .status(.todo): "circle"
        case .status(.funded): "arrow.down.to.line"
        case .status(.done): "checkmark.circle.fill"
        case .account, nil: "circle"
        }
    }

    private var tint: Color {
        switch section.heading {
        case .group(let group?): Theme.categoryTint(hex: group.colorHex, seed: group.name)
        case .status(.funded): Theme.accentText
        case .status(.done): Theme.positive
        case .status(.todo): Theme.textSecondary
        default: Theme.textSecondary.opacity(0.6)
        }
    }
}
