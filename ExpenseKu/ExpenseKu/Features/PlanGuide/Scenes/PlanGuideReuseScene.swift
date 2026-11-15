//
//  PlanGuideReuseScene.swift
//  ExpenseKu
//
//  A November with no plan yet, and Look back's row for October's Harian
//  (plan-guide-visual.md decision 27). The look back compares October with an empty
//  November, which is what the owner meets after Start empty.
//

import SwiftUI

struct PlanGuideReuseScene: View {
    let sample: PlanGuideSample

    var body: some View {
        let october = sample.cycle.previous(payday: PlanGuideSample.payday, calendar: sample.calendar)
        let lookBack = LookBack.of(october, here: CyclePlan(cycleStart: sample.cycle.start),
                                   plans: [sample.october], expenses: [],
                                   payday: PlanGuideSample.payday, calendar: sample.calendar)
        let month = LookBackCopy.month(of: october, calendar: sample.calendar)

        VStack(spacing: Metric.cardGap) {
            PlanEmptyState(copySourceMonth: month, onCopy: {}, onStart: {})
            if let row = lookBack.planRows.first {
                PlanGuideCard {
                    LookBackPlanRowView(row: row, mark: nil,
                                        planMonth: LookBackCopy.month(of: sample.cycle, calendar: sample.calendar),
                                        onAct: {}, onUndo: {})
                }
                .planGuideTarget(.lookBackRow, radius: Metric.cardRadius)
            }
        }
    }
}
