//
//  PlanGuideThroughCycleScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideThroughCycleScene: View {
    let sample: PlanGuideSample

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            PlanGuideCard {
                PlanGuideItemRow(item: sample.kos, sample: sample)
                    .planGuideTarget(.kosRow)
                PlanGuideItemRow(item: sample.harian, sample: sample)
                    .planGuideTarget(.harianRow)
            }
            PlanGuideRemainingCard(totals: sample.contents.totals)
        }
    }
}
