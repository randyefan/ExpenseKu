//
//  PlanGuideItemKindsScene.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideItemKindsScene: View {
    let sample: PlanGuideSample

    var body: some View {
        PlanGuideCard {
            PlanGuideItemRow(item: sample.kos, sample: sample)
                .planGuideTarget(.kosRow)
            PlanGuideItemRow(item: sample.harian, sample: sample)
                .planGuideTarget(.harianRow)
            PlanGuideItemRow(item: sample.liburan, sample: sample)
                .planGuideTarget(.liburanRow)
        }
    }
}
