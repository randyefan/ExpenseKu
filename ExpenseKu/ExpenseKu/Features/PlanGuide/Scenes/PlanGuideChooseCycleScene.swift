//
//  PlanGuideChooseCycleScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideChooseCycleScene: View {
    let sample: PlanGuideSample

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            CycleHeader(cycle: sample.cycle, headline: sample.contents.headline, canGoBack: true, canGoForward: true,
                        calendar: sample.calendar, onPrevious: {}, onNext: {})
                .planGuideTarget(.cycleHeader, radius: Metric.cardRadius)
            PlanTotalsCard(contents: sample.contents, payday: PlanGuideSample.payday,
                           calendar: sample.calendar, onAction: { _ in })
            PlanGuideCard {
                PickerAddRow(title: AppLocalization.string(.addPlanItem))
                    .padding(.vertical, 4)
                    .planGuideTarget(.addPlanItem)
                PickerAddRow(title: AppLocalization.string(.addIncomeLine))
                    .padding(.vertical, 4)
                LookBackEntryRow(month: LookBackCopy.month(of: sample.cycle.previous(payday: PlanGuideSample.payday,
                                                                                      calendar: sample.calendar),
                                                           calendar: sample.calendar))
                    .padding(.vertical, 4)
            }
        }
    }
}
