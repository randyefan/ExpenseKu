//
//  PlanAccountHeader.swift
//  ExpenseKu
//
//  The head of one bank's group when the plan is sorted by Account (docs/prd/bank-logos.md
//  §5.6.2, frame AC1): the plate, the name and count, and what that bank must cover this
//  cycle with how much of it is there. The rows beneath drop their Account chip, so this
//  is the one place the group says which bank it is.
//

import SwiftUI

struct PlanAccountHeader: View {
    let account: Account?
    let items: [PlanItem]

    private var summary: AccountGroupSummary { AccountGroupSummary(items: items, hasAccount: account != nil) }
    private var name: String { account?.name ?? PlanSections.unassignedName }

    var body: some View {
        let summary = summary
        let state = summary.state.text(accountName: name)
        let stateColor = Self.color(of: summary.state)
        HStack(spacing: 10) {
            AccountPlate(style: account.map(AccountPlateStyle.init(account:)))
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(summary.count)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                MoneyText(summary.total, font: .dsBody.bold(), color: Theme.text)
                Text(state)
                    .font(.dsCaption)
                    .fontWeight(stateColor == Theme.textSecondary ? .regular : .semibold)
                    .monospacedDigit()
                    .foregroundStyle(stateColor)
                    .lineLimit(1)
            }
            .layoutPriority(1)
        }
        .padding(.top, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([name, summary.count, summary.total.formattedIDR(), state].joined(separator: ", "))
        .accessibilityAddTraits(.isHeader)
    }

    private static func color(of state: AccountGroupState) -> Color {
        switch state {
        case .allIn: Theme.accentText
        case .allPaid: Theme.positive
        case .nothingIn, .toGo: Theme.textSecondary
        }
    }
}
