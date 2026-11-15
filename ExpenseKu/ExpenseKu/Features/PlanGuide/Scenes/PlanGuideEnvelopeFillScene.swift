//
//  PlanGuideEnvelopeFillScene.swift
//  ExpenseKu
//
//  Harian's row, its ＋ menu drawn open while ＋ is lit, and the editor in its place while
//  the Envelope row is lit (plan-guide-visual.md decision 23).
//

import SwiftUI

struct PlanGuideEnvelopeFillScene: View {
    let target: PlanGuideTarget
    let sample: PlanGuideSample

    var body: some View {
        if target == .editorEnvelope {
            PlanGuideEditorExample(sample: sample)
        } else {
            VStack(alignment: .trailing, spacing: Metric.cardGap) {
                PlanGuideCard {
                    PlanGuideItemRow(item: sample.harian, sample: sample)
                }
                if target == .envelopeAdd {
                    PlanGuideMenuPanel(items: [
                        .init(title: AppLocalization.string(.newExpense), systemImage: "plus"),
                        .init(title: AppLocalization.string(.moveExpensesHere), systemImage: "checklist")
                    ], isLit: true)
                }
            }
        }
    }
}
