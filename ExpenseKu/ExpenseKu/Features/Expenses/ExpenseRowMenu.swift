//
//  ExpenseRowMenu.swift
//  ExpenseKu
//
//  The long-press menu every expense row carries (frame R1): Select (List lens only),
//  Move to envelope… (when the row's own cycle, or a later one on offer, has an envelope),
//  Mark as checked (a receipt expense not yet checked, docs/prd/receipt-reading.md §4.7),
//  Edit and Delete. A row a Fixed item created is From plan already, so it offers Edit
//  and Delete only.
//

import SwiftData
import SwiftUI

struct ExpenseRowMenu: ViewModifier {
    let expense: Expense
    let onEdit: () -> Void

    @Environment(\.expenseRowActions) private var actions
    @Environment(\.planOrigins) private var planOrigins
    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.contextMenu {
            if let startSelecting = actions.startSelecting, ExpenseSelection.isSelectable(expense) {
                Button(AppLocalization.string(.select), systemImage: "checkmark.circle") { startSelecting(expense) }
            }
            if let move = actions.move, let cycle = planOrigins.moveTarget(for: expense, now: .now) {
                Button(AppLocalization.string(.moveToEnvelope), systemImage: "tray") {
                    move(EnvelopeMoveRequest(expenses: [expense], cycle: cycle))
                }
            }
            if expense.isReceiptToCheck {
                Button(AppLocalization.string(.markAsChecked), systemImage: "checkmark.seal") {
                    expense.markReceiptChecked()
                    try? context.save()
                }
            }
            Button(AppLocalization.string(.edit), systemImage: "pencil", action: onEdit)
            if let delete = actions.delete {
                Button(AppLocalization.string(.delete), systemImage: "trash", role: .destructive) { delete(expense) }
            }
        }
    }
}

extension View {
    func expenseRowMenu(_ expense: Expense, onEdit: @escaping () -> Void) -> some View {
        modifier(ExpenseRowMenu(expense: expense, onEdit: onEdit))
    }
}
