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
    let finishTitle: String
    let onClose: () -> Void
    let onTopics: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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

                PlanGuideExampleCard(example: lesson.example)

                ForEach(lesson.takeaways.enumerated(), id: \.offset) { _, takeaway in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(takeaway.heading)
                            .font(.dsHeadline).bold()
                            .foregroundStyle(Theme.text)
                            .accessibilityAddTraits(.isHeader)
                        Text(takeaway.body)
                            .font(.dsBody)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: Metric.readableWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Metric.screenPadding)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            PlanGuideLessonHeader(title: title, step: step, stepCount: stepCount, onClose: onClose)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PlanGuideFooter(
                secondaryTitle: AppLocalization.string(step == 1 ? .guideTopics : .guideBack),
                primaryTitle: step == stepCount ? finishTitle : AppLocalization.string(.guideNext),
                onSecondary: step == 1 ? onTopics : onBack,
                onPrimary: step == stepCount ? onFinish : onNext
            )
        }
    }
}
