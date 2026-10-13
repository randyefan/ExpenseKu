//
//  SelectionMark.swift
//  ExpenseKu
//

import SwiftUI

/// A row's check circle in Select mode. `unavailable` is a row a Fixed item created:
/// dimmed and uncheckable, its circle's space kept so the rows still line up.
enum SelectionMark {
    case on
    case off
    case unavailable

    static func of(_ expense: Expense, in selection: ExpenseSelection) -> SelectionMark {
        guard ExpenseSelection.isSelectable(expense) else { return .unavailable }
        return selection.contains(expense) ? .on : .off
    }
}

struct SelectionCircle: View {
    let mark: SelectionMark

    var body: some View {
        ZStack {
            switch mark {
            case .on:
                Circle().fill(Theme.accent)
                Image(systemName: "checkmark")
                    .font(.dsCaption.weight(.bold))
                    .foregroundStyle(Theme.onAccent)
            case .off:
                Circle().strokeBorder(Theme.textSecondary, lineWidth: 1.5)
            case .unavailable:
                Color.clear
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}
