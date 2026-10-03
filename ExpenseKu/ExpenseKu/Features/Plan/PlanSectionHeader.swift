//
//  PlanSectionHeader.swift
//  ExpenseKu
//
//  The header over one group of a sorted plan (frames M2, M3, M5): a glyph saying
//  which order is showing, then NAME · N ITEMS.
//

import SwiftUI

struct PlanSectionHeader: View {
    let section: PlanSection

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            SectionHeaderText(section.title ?? "")
        }
    }

    private var symbol: String {
        switch section.heading {
        case .account(let account): account?.resolvedSymbol ?? "creditcard"
        case .group(let group): group?.resolvedSymbol ?? "tray"
        case .status(.todo): "circle"
        case .status(.funded): "arrow.down.to.line"
        case .status(.done): "checkmark.circle.fill"
        case nil: "circle"
        }
    }

    private var tint: Color {
        switch section.heading {
        case .account(.some): Theme.textSecondary
        case .group(let group?): Theme.categoryTint(hex: group.colorHex, seed: group.name)
        case .status(.funded): Theme.accentText
        case .status(.done): Theme.positive
        case .status(.todo): Theme.textSecondary
        default: Theme.textSecondary.opacity(0.6)
        }
    }
}
