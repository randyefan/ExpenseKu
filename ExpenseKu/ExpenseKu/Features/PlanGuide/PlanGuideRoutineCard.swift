//
//  PlanGuideRoutineCard.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideRoutineCard: View {
    let status: PlanGuideStatus
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                PlanGuideBadge(isProminent: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(appLocalized: .guideRoutineTitle)
                        .font(.dsHeadline).bold()
                        .foregroundStyle(Theme.text)
                    Text(caption)
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)

            Button(actionTitle, action: onOpen)
                .font(.dsSubhead).bold()
                .foregroundStyle(Theme.accentText)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.surface, in: .capsule)
                .buttonStyle(.pressableCard)
        }
        .cardStyle()
    }

    private var caption: String {
        switch status {
        case .notStarted: AppLocalization.string(.guideRoutineNotStartedCaption)
        case .inProgress(let step, let count): AppLocalization.string(.guideRoutineStepCaption(step, count))
        case .read: AppLocalization.string(.guideRoutineReadCaption)
        }
    }

    private var actionTitle: String {
        switch status {
        case .notStarted: AppLocalization.string(.guideStartIntroduction)
        case .inProgress: AppLocalization.string(.guideContinueIntroduction)
        case .read: AppLocalization.string(.guideReadIntroductionAgain)
        }
    }
}
