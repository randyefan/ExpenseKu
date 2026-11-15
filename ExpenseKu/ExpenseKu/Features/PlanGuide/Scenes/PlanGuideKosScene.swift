//
//  PlanGuideKosScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideKosScene: View {
    let sample: PlanGuideSample

    var body: some View {
        PlanGuideCard {
            PlanGuideItemRow(item: sample.kos, sample: sample)
        }
    }
}
