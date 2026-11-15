//
//  PlanGuideElsewhereScene.swift
//  ExpenseKu
//
//  Two parts of Harian's detail and December's Liburan: Grab paid on CC Danamon, and a
//  November ticket paid early into December (plan-guide-visual.md decision 30).
//

import SwiftData
import SwiftUI

struct PlanGuideElsewhereScene: View {
    let sample: PlanGuideSample

    var body: some View {
        let paidElsewhere = PaidElsewhere(envelope: sample.harian, expenses: sample.harianExpenses,
                                          calendar: sample.calendar)
        let december = sample.cycle.next(payday: PlanGuideSample.payday, calendar: sample.calendar)
        let ticket = sample.expenses.first { $0.envelope?.persistentModelID == sample.decemberLiburan.persistentModelID }

        VStack(spacing: Metric.cardGap) {
            if let row = paidElsewhere.rows.first {
                PlanGuideCard(header: AppLocalization.string(.paidElsewhere)) {
                    PaidElsewhereRowView(row: row, onOpen: {})
                        .planGuideTarget(.paidElsewhereRow)
                }
            }
            if let ticket {
                PlanGuideCard(header: AppLocalization.string(.paidEarlySectionHeading(december.title(calendar: sample.calendar)))) {
                    ExpenseRow(expense: ticket)
                        .padding(.vertical, 4)
                }
                .padding(4)
                .planGuideTarget(.paidEarlyRow, radius: Metric.cardRadius)
            }
        }
    }
}
