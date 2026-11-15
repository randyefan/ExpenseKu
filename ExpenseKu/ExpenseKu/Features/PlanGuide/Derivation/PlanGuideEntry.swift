//
//  PlanGuideEntry.swift
//  ExpenseKu
//
//  How the guide was opened, which decides where it starts (plan-guide.md §4.1, §6):
//  the invitation resumes the introduction, the Plan options menu always shows the index.
//

import Foundation

nonisolated enum PlanGuideEntry: String, Identifiable {
    case invitation
    case menu

    var id: Self { self }
}
