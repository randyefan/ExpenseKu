//
//  ExpenseRowMenu.swift
//  ExpenseKu
//
//  The long-press menu every expense row carries (frame R1): Select (List lens only),
//  Move to envelope… (when the row's own cycle, or a later one on offer, has an envelope),
//  Edit and Delete. A row
//  a Fixed item created is From plan already, so it offers Edit and Delete only.
//

import SwiftUI

struct ExpenseRowMenu: ViewModifier {
    let expense: Expense
    let onEdit: () -> Void

    @Environment(\.expenseRowActions) private var actions
    @Environment(\.planOrigins) private var planOrigins

    func body(content: Content) -> some View {
        content.contextMenu {
            if let startSelecting = actions.startSelecting, ExpenseSelection.isSelectable(expense) {
                Button("Select", systemImage: "checkmark.circle") { startSelecting(expense) }
            }
            if let move = actions.move, let cycle = planOrigins.moveTarget(for: expense, now: .now) {
                Button("Move to envelope…", systemImage: "tray") {
                    move(EnvelopeMoveRequest(expenses: [expense], cycle: cycle))
                }
            }
            Button("Edit", systemImage: "pencil", action: onEdit)
            if let delete = actions.delete {
                Button("Delete", systemImage: "trash", role: .destructive) { delete(expense) }
            }
        }
    }
}

extension View {
    func expenseRowMenu(_ expense: Expense, onEdit: @escaping () -> Void) -> some View {
        modifier(ExpenseRowMenu(expense: expense, onEdit: onEdit))
    }
}
