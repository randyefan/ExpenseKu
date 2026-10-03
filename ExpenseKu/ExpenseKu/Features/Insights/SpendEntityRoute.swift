//
//  SpendEntityRoute.swift
//  ExpenseKu
//
//  What an Insights breakdown row hands to its drill-in: the subject, and the window
//  and plan filter that were active when it was tapped (docs/prd/insights-drill-in.md
//  §4.1). Identifiers, not models, for PersonExpensesRoute's reason.
//

import Foundation

struct SpendEntityRoute: Hashable {
    let subject: SpendSubject
    let window: InsightsWindow
    let planFilter: PlanFilter?
}
