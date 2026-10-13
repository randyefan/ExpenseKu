//
//  NewExpensePreset.swift
//  ExpenseKu
//

import Foundation

/// An Add Expense sheet waiting to open. The toolbar's ＋ leaves both fields nil; ＋ on
/// an envelope row fills them (envelope-assignment.md §4.5).
struct NewExpensePreset: Identifiable {
    let id = UUID()
    var envelope: PlanItem? = nil
    var date: Date? = nil
}
