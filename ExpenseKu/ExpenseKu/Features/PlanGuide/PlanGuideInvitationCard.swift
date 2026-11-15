//
//  PlanGuideInvitationCard.swift
//  ExpenseKu
//
//  Meet Plan, above a cycle's empty state (plan-guide.md §4.1, frames AM1 and AM19). It
//  never opens anything by itself; the guide starts only from its button.
//

import SwiftUI

struct PlanGuideInvitationCard: View {
    let invitation: PlanGuideInvitation
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                PlanGuideBadge(isProminent: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(appLocalized: .guideMeetPlan)
                        .font(.dsHeadline).bold()
                        .foregroundStyle(Theme.text)
                    Text(appLocalized: .guideMeetPlanMessage)
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)

            Button(AppLocalization.string(invitation == .view ? .guideViewGuide : .guideContinueIntroduction),
                   action: onOpen)
                .font(.dsBody).bold()
                .foregroundStyle(Theme.accentText)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.surface, in: .capsule)
                .buttonStyle(.pressableCard)
        }
        .cardStyle()
    }
}
