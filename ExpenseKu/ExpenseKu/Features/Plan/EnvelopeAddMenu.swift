//
//  EnvelopeAddMenu.swift
//  ExpenseKu
//
//  The violet ＋ beside an envelope's bar (envelope-assignment.md §4.5): a new expense
//  already assigned there, or Move expenses here… for ones already logged. It wears the
//  plan's violet so it does not read as the toolbar's ＋, which logs an ordinary expense.
//  The envelope row and the envelope's detail card both carry it, level with their bar.
//

import SwiftUI

struct EnvelopeAddMenu: View {
    let name: String
    let onAddExpense: () -> Void
    let onMoveExpenses: () -> Void

    static let size: CGFloat = 30

    var body: some View {
        Menu {
            Button(action: onAddExpense) {
                Label("New expense", systemImage: "plus")
                Text("Logged straight into \(name)")
            }
            Button(action: onMoveExpenses) {
                Label("Move expenses here…", systemImage: "checklist")
                Text("Pick from this cycle's expenses")
            }
        } label: {
            Image(systemName: "plus")
                .font(.dsCaption.weight(.bold))
                .foregroundStyle(Theme.plan)
                .frame(width: Self.size, height: Self.size)
                .background(Theme.planWash, in: .circle)
                .contentShape(.circle)
        }
        .accessibilityLabel("Add to \(name)")
    }
}
