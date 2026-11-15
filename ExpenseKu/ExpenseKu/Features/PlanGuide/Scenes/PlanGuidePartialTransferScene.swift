//
//  PlanGuidePartialTransferScene.swift
//  ExpenseKu
//
//  Jago's transfer sheet until it is recorded, then the checklist it leaves behind
//  (plan-guide-visual.md decision 29).
//

import SwiftData
import SwiftUI

struct PlanGuidePartialTransferScene: View {
    let target: PlanGuideTarget
    let sample: PlanGuideSample

    var body: some View {
        let jago = sample.contents.transfers.first { $0.accountName == sample.jago.name }

        if sample.harian.isFunded {
            VStack(spacing: Metric.cardGap) {
                PlanGuideTransferChecklist(rows: sample.contents.transfers)
                PlanGuideCard {
                    PlanGuideItemRow(item: sample.harian, sample: sample)
                }
            }
        } else if let jago {
            PlanGuideTransferSheetExample(row: jago, liburanChosen: sample.state.liburanChosen,
                                          liburanID: sample.liburan.persistentModelID)
        }
    }
}
