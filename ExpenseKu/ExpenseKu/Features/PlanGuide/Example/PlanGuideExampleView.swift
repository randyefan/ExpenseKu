//
//  PlanGuideExampleView.swift
//  ExpenseKu
//
//  A lesson step's example: the scene drawn from the sample state of the active
//  spotlight, dimmed around the lit part (plan-guide-visual.md §4.2, §4.3). It is inert and
//  reads as one accessibility element; the caption below it says what is lit (§4.6).
//

import SwiftData
import SwiftUI

struct PlanGuideExampleView: View {
    let scene: PlanGuideScene
    let spotlight: PlanGuideSpotlight
    let label: String
    let cache: PlanGuideSampleCache
    let onLocate: (CGRect) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var targets = PlanGuideTargetRegistry()

    var body: some View {
        let sample = cache.sample(spotlight.state)

        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderText(.guideExampleLabel)
                .padding(.horizontal, 4)
            ZStack {
                PlanGuideSceneView(scene: scene, target: spotlight.target, sample: sample)
                    .id(spotlight.state)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            }
            .coordinateSpace(.named(PlanGuideTargetRegistry.space))
            .overlay {
                PlanGuideSpotlightOverlay(target: spotlight.target, registry: targets, onLocate: onLocate)
            }
            .environment(\.planGuideTargets, targets)
            .environment(\.planOrigins, PlanOrigins(plans: [sample.october, sample.november, sample.december],
                                                    payday: PlanGuideSample.payday, calendar: sample.calendar))
            .modelContainer(sample.container)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.settle, value: spotlight)
    }
}
