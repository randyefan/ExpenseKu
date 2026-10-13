//
//  ExpenseRowActions.swift
//  ExpenseKu
//
//  What a row's long-press menu can do on the screen showing it (envelope-assignment.md
//  §4.8). Supplied through the environment by each screen that lists expenses, so the
//  rows stay one component; an action left nil drops its menu item.
//

import SwiftUI

struct ExpenseRowActions {
    var startSelecting: ((Expense) -> Void)? = nil
    var move: ((EnvelopeMoveRequest) -> Void)? = nil
    var delete: ((Expense) -> Void)? = nil
}

extension EnvironmentValues {
    @Entry var expenseRowActions = ExpenseRowActions()
}
