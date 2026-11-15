//
//  PlanGuideLessonView.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideLessonView: View {
    let title: String
    let step: Int
    let stepCount: Int
    let lesson: PlanGuideLesson
    let spotlight: Int
    let isAtStart: Bool
    let isAtEnd: Bool
    let finishTitle: String
    let cache: PlanGuideSampleCache
    let onClose: () -> Void
    let onTopics: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void
    let onFinish: () -> Void

    @State private var scrollPosition = ScrollPosition()
    @State private var visibleRect = CGRect.zero
    @State private var captionRect = CGRect.zero
    @State private var spotlightRect = CGRect.zero

    private var active: PlanGuideSpotlight { lesson.spotlights[min(spotlight, lesson.spotlights.count) - 1] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(appLocalized: .guideStepOf(step, stepCount, lesson.stepTitle))
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                    Text(lesson.heading)
                        .font(.dsLargeTitle).bold()
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(lesson.lead)
                        .font(.dsBody)
                        .foregroundStyle(Theme.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                PlanGuideExampleView(
                    scene: lesson.scene,
                    spotlight: active,
                    label: AppLocalization.string(.guideExampleOf(lesson.stepTitle)),
                    cache: cache,
                    onLocate: { rect in
                        spotlightRect = rect
                        reveal()
                    }
                )

                PlanGuideCaption(caption: active.caption, position: spotlight, count: lesson.spotlights.count)
                    .onGeometryChange(for: CGRect.self) {
                        $0.frame(in: .named(PlanGuideSpotlightOverlay.contentSpace))
                    } action: { rect in
                        captionRect = rect
                        reveal()
                    }
            }
            .frame(maxWidth: Metric.readableWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Metric.screenPadding)
            .padding(.bottom, 24)
            .coordinateSpace(.named(PlanGuideSpotlightOverlay.contentSpace))
        }
        .scrollIndicators(.hidden)
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: CGRect.self) { $0.visibleRect } action: { _, rect in
            visibleRect = rect
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            PlanGuideLessonHeader(title: title, step: step, stepCount: stepCount, onClose: onClose)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PlanGuideFooter(
                secondaryTitle: AppLocalization.string(isAtStart ? .guideTopics : .guideBack),
                primaryTitle: isAtEnd ? finishTitle : AppLocalization.string(.guideNext),
                onSecondary: isAtStart ? onTopics : onBack,
                onPrimary: isAtEnd ? onFinish : onNext
            )
        }
    }

    private func reveal() {
        guard visibleRect.height > 0, spotlightRect != .zero else { return }
        let together = spotlightRect.union(captionRect)
        let wanted = spotlight > 1 && together.height + 32 <= visibleRect.height ? together : spotlightRect
        guard !visibleRect.contains(wanted) else { return }
        let top = wanted.maxY > visibleRect.maxY && wanted.height + 32 <= visibleRect.height
            ? wanted.maxY + 16 - visibleRect.height
            : wanted.minY - 16
        withAnimation(Motion.settle) { scrollPosition.scrollTo(y: max(0, top)) }
    }
}
