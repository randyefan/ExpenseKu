//
//  PaidElsewhereSection.swift
//  ExpenseKu
//
//  PAID ELSEWHERE, directly under an envelope's card (docs/prd/paid-elsewhere.md §4.3,
//  frame AE1): the one thing on the detail the owner has to act on, so it sits above the
//  expense list rather than under thirty trip rows.
//

import SwiftUI

struct PaidElsewhereSection: View {
    let paidElsewhere: PaidElsewhere
    let onOpen: (PaidElsewhereRow) -> Void

    var body: some View {
        Section {
            ForEach(paidElsewhere.rows) { row in
                PlanListRow {
                    PaidElsewhereRowView(row: row) { onOpen(row) }
                }
            }
        } header: {
            SectionHeaderText(.paidElsewhere)
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
        }
    }
}
