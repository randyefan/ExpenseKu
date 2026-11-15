//
//  PlanGuideSceneView.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideSceneView: View {
    let scene: PlanGuideScene
    let target: PlanGuideTarget
    let sample: PlanGuideSample

    var body: some View {
        switch scene {
        case .beforePayday: PlanGuideBeforePaydayScene(sample: sample)
        case .onPayday: PlanGuideOnPaydayScene(sample: sample)
        case .throughTheCycle: PlanGuideThroughCycleScene(sample: sample)
        case .chooseCycle: PlanGuideChooseCycleScene(sample: sample)
        case .reuse: PlanGuideReuseScene(sample: sample)
        case .itemKinds: PlanGuideItemKindsScene(sample: sample)
        case .setAside: PlanGuideSetAsideScene(sample: sample)
        case .rowAndStatus: PlanGuideKosScene(sample: sample)
        case .datesAndAuto:
            PlanGuideKosScene(sample: sample)
                .environment(\.planRowsShowAccount, false)
        case .destinations: PlanGuideDestinationsScene(sample: sample)
        case .partialTransfer: PlanGuidePartialTransferScene(target: target, sample: sample)
        case .envelopeFill: PlanGuideEnvelopeFillScene(target: target, sample: sample)
        case .elsewhere: PlanGuideElsewhereScene(sample: sample)
        case .changeView: PlanGuideChangeViewScene(target: target, sample: sample)
        case .noticesAndClearing: PlanGuideNoticesScene(sample: sample)
        }
    }
}
