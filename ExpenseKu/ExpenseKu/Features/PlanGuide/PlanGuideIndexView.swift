//
//  PlanGuideIndexView.swift
//  ExpenseKu
//
//  The guide's home (plan-guide.md §4.3, frames AM5 and AM18). Every topic is open from
//  the start; the introduction block's own button only ever continues the introduction.
//

import SwiftUI

struct PlanGuideIndexView: View {
    let progress: PlanGuideProgress
    let onOpen: (PlanGuideMaterial) -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(appLocalized: .guideIndexHeading)
                        .font(.dsLargeTitle).bold()
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(appLocalized: .guideIndexLead)
                        .font(.dsBody)
                        .foregroundStyle(Theme.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                PlanGuideRoutineCard(status: progress.status(of: .introduction)) {
                    onOpen(.introduction)
                }

                PlanGuideTopicGroup(
                    title: AppLocalization.string(.guideBuildYourPlan),
                    topics: PlanGuideMaterial.buildTopics,
                    progress: progress,
                    onOpen: onOpen
                )
                PlanGuideTopicGroup(
                    title: AppLocalization.string(.guideUseYourPlan),
                    topics: PlanGuideMaterial.useTopics,
                    progress: progress,
                    onOpen: onOpen
                )

                Text(appLocalized: .guideIndexFooter)
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: Metric.readableWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Metric.screenPadding)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            PlanGuideTopBar(
                title: AppLocalization.string(.planGuide),
                closeTitle: AppLocalization.string(.guideBackToPlan),
                onClose: onClose
            )
            .background(Theme.bg)
        }
    }
}
