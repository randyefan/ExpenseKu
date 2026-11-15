//
//  PlanGuideExampleRowView.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideExampleRowView: View {
    let row: PlanGuideExampleRow
    var isSummary = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    name
                    Spacer(minLength: 0)
                    value
                }
                VStack(alignment: .leading, spacing: 4) {
                    name
                    value
                }
            }
            if let detail = row.detail {
                Text(detail)
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(selectionLabel)
    }

    private var name: some View {
        HStack(spacing: 10) {
            if let selection = row.selection {
                Image(systemName: selection == .selected ? "checkmark.circle" : "circle")
                    .font(.dsHeadline)
                    .foregroundStyle(selection == .selected ? Theme.accentText : Theme.textSecondary)
            }
            Text(row.name)
                .font(.dsBody)
                .bold(row.selection == nil)
                .foregroundStyle(nameStyle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var value: some View {
        Text(row.value)
            .font(.dsBody)
            .bold(isSummary)
            .monospacedDigit()
            .foregroundStyle(valueStyle)
            .lineLimit(1)
    }

    private var nameStyle: Color {
        switch row.selection {
        case .selected: Theme.accentText
        case .unselected: Theme.textSecondary
        case nil: Theme.text
        }
    }

    private var valueStyle: Color {
        if isSummary || row.selection == .selected { return Theme.accentText }
        return row.selection == .unselected ? Theme.textSecondary : Theme.text
    }

    private var selectionLabel: String {
        switch row.selection {
        case .selected: AppLocalization.string(.guideSelected)
        case .unselected: AppLocalization.string(.guideNotSelected)
        case nil: ""
        }
    }
}
