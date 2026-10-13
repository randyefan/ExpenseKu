//
//  EnvelopeDetailAction.swift
//  ExpenseKu
//
//  What an envelope's detail asks ExpensesView to open. Each one closes the detail first
//  and reopens it afterwards (envelope-detail.md §4.6), so two sheets are never stacked —
//  the detail only reports, and the view that owns every sheet sequences them.
//

import Foundation

enum EnvelopeDetailAction {
    case edit
    case addExpense
    case moveExpenses
    case openExpense(Expense)
    case move(EnvelopeMoveRequest)
}
