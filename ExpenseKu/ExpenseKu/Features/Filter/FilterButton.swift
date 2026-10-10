//
//  FilterButton.swift
//  ExpenseKu
//
//  The toolbar button that opens the Filter sheet (docs/prd/expense-filter.md §4.2). Lit in
//  the accent while a filter is on, with the number of active dimensions as its badge.
//

import SwiftUI

struct FilterButton: View {
    let activeCount: Int
    let action: () -> Void

    var body: some View {
        Button("Filter", systemImage: "line.3.horizontal.decrease", action: action)
            .tint(activeCount > 0 ? Theme.accent : Theme.textSecondary)
            .badge(activeCount)
            .accessibilityValue(activeCount > 0 ? "\(activeCount) on" : "Off")
    }
}
