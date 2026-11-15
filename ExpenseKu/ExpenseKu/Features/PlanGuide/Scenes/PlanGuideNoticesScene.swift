//
//  PlanGuideNoticesScene.swift
//  ExpenseKu
//
//  The Auto review notice, then December's cycle header with the Plan options menu drawn
//  open (plan-guide-visual.md decision 32): Clear Plan is offered on an upcoming plan.
//

import SwiftUI

struct PlanGuideNoticesScene: View {
    let sample: PlanGuideSample

    var body: some View {
        let review = sample.contents.review
        let december = sample.cycle.next(payday: PlanGuideSample.payday, calendar: sample.calendar)
        let decemberContents = PlanContents(plan: sample.december, cycle: december, cycleExpenses: [],
                                            calendar: sample.calendar)

        VStack(alignment: .trailing, spacing: Metric.cardGap) {
            PlanNotice(kind: .review, title: review.title, detail: review.detail)
                .planGuideTarget(.reviewNotice, radius: Metric.cardRadius)
            CycleHeader(cycle: december, headline: decemberContents.headline, canGoBack: true, canGoForward: true,
                        calendar: sample.calendar, onPrevious: {}, onNext: {})
            PlanGuideMenuPanel(items: [
                .init(title: AppLocalization.string(.planGuide), systemImage: "book"),
                .init(title: AppLocalization.string(.clearPlan), systemImage: "trash", isDestructive: true,
                      target: .clearPlan)
            ])
        }
    }
}
