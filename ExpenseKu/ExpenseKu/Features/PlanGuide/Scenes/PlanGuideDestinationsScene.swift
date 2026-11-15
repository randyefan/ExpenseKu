//
//  PlanGuideDestinationsScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideDestinationsScene: View {
    let sample: PlanGuideSample

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            PlanGuideCard {
                ForEach(sample.contents.incomeLines) { line in
                    IncomeRow(line: line, onToggleArrived: {}, onEdit: {})
                        .padding(.vertical, 8)
                        .planGuideTarget(.incomeLine)
                }
            }
            PlanGuideTransferChecklist(rows: sample.contents.transfers)
            PlanGuideCard {
                PlanGuideItemRow(item: sample.kos, sample: sample)
                    .planGuideTarget(.kosRow)
            }
        }
    }
}
