//
//  PlanGuideTopicRow.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideTopicRow: View {
    let material: PlanGuideMaterial
    let status: PlanGuideStatus
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                PlanGuideBadge()
                VStack(alignment: .leading, spacing: 2) {
                    Text(PlanGuideContent.title(of: material))
                        .font(.dsBody).bold()
                        .foregroundStyle(Theme.text)
                    Text(PlanGuideContent.subtitle(of: material))
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                    Text(statusText)
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.accentText)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(Metric.cardPadding)
            .contentShape(.rect)
        }
        .buttonStyle(PressableRowStyle(cornerRadius: Metric.cardRadius))
    }

    private var statusText: String {
        switch status {
        case .notStarted: AppLocalization.string(.guideNotStarted)
        case .inProgress(let step, let count): AppLocalization.string(.guideStepProgress(step, count))
        case .read: AppLocalization.string(.guideRead)
        }
    }
}
