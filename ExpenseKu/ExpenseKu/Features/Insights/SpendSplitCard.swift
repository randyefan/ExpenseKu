//
//  SpendSplitCard.swift
//  ExpenseKu
//
//  A drill-in's plan split, in a card of its own under the period chips (the owner's
//  choice over folding it into the header): the subject's Outside plan / From plan in
//  the window, and the chips that filter the screen (docs/prd/insights-drill-in.md §6.3).
//

import SwiftUI

struct SpendSplitCard: View {
    let subjectName: String
    let split: SpendingSplit
    let filter: PlanFilter?
    let onTap: (PlanFilter) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderText("\(subjectName) by plan")
            SpendingSplitView(split: split, filter: filter, onTap: onTap)
        }
        .cardStyle()
    }
}
