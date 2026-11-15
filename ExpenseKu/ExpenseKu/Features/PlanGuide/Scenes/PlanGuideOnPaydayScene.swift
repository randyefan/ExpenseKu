//
//  PlanGuideOnPaydayScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideOnPaydayScene: View {
    let sample: PlanGuideSample

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            PlanTotalsCard(contents: sample.contents, payday: PlanGuideSample.payday,
                           calendar: sample.calendar, onAction: { _ in })
            PlanGuideTransferChecklist(rows: sample.contents.transfers)
            TransferRecordButton(title: AppLocalization.string(.movedTo(sample.jago.name)), isEnabled: true, action: {})
                .planGuideTarget(.movedButton, radius: 26)
        }
    }
}
