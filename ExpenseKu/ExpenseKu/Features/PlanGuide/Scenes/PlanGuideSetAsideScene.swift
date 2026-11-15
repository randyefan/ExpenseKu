//
//  PlanGuideSetAsideScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideSetAsideScene: View {
    let sample: PlanGuideSample

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            PlanTotalsCard(contents: sample.contents, payday: PlanGuideSample.payday,
                           calendar: sample.calendar, onAction: { _ in })
            PlanGuideCard {
                PlanGuideItemRow(item: sample.liburan, sample: sample)
            }
        }
    }
}
