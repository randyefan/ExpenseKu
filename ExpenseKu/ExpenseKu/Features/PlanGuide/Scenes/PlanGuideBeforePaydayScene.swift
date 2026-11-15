//
//  PlanGuideBeforePaydayScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideBeforePaydayScene: View {
    let sample: PlanGuideSample

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            PlanTotalsCard(contents: sample.contents, payday: PlanGuideSample.payday,
                           calendar: sample.calendar, onAction: { _ in })
            PlanGuideCard {
                ForEach(sample.contents.activeItems) { item in
                    PlanGuideItemRow(item: item, sample: sample)
                }
            }
            .planGuideTarget(.planRows, radius: Metric.cardRadius)
        }
    }
}
