//
//  EnvelopeMoveRequest.swift
//  ExpenseKu
//

import Foundation

/// A pending "Move to envelope…": which expenses, and the cycle they belong to, whose
/// offer the sheet works out. One expense from a row's menu, or the List lens's selection
/// (§4.6, §4.8, §4.10.2).
struct EnvelopeMoveRequest: Identifiable {
    let id = UUID()
    let expenses: [Expense]
    let cycle: PayCycle
}
