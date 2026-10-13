//
//  EnvelopeMoveRequest.swift
//  ExpenseKu
//

import Foundation

/// A pending "Move to envelope…": which expenses, and the plan and cycle whose envelopes
/// are on offer. One expense from a row's menu, or the List lens's selection (§4.6, §4.8).
struct EnvelopeMoveRequest: Identifiable {
    let id = UUID()
    let expenses: [Expense]
    let plan: CyclePlan?
    let cycle: PayCycle
}
