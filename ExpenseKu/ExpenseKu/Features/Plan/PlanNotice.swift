//
//  PlanNotice.swift
//  ExpenseKu
//
//  The one line above the plan that says what has changed since the owner last looked:
//  Auto items that posted themselves (E1, G2), the transfers waiting on payday morning
//  (G1), or a plan that has just been copied forward (E5).
//
//  The review variant is tappable, and that is a decision rather than a detail
//  (decision 21). Without a route to the amount the flag could only be dismissed,
//  never acted on — and a failed autodebit or a changed amount would stay invisible.
//  ADR-0007 accepts that this notice is the only defence it has.
//

import SwiftUI

struct PlanNotice: View {
    enum Kind {
        case review
        case payday
        case carriedOver
    }

    let kind: Kind
    let title: String
    let detail: String
    var onTap: (() -> Void)?

    var body: some View {
        content
            .padding(Metric.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .fill(Theme.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: Metric.cardRadius)
                            .fill(Theme.accent.opacity(0.08))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: Metric.cardRadius)
                            .stroke(Theme.hairline, lineWidth: 1)
                    }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let onTap {
            Button(action: onTap) { label.contentShape(.rect) }
                .buttonStyle(.pressableCard)
                .accessibilityHint("Opens the posted expenses")
        } else {
            label
        }
    }

    private var label: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.dsBody.weight(.semibold))
                .foregroundStyle(Theme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dsSubhead).bold()
                    .foregroundStyle(Theme.text)
                Text(detail)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .multilineTextAlignment(.leading)
    }

    private var symbol: String {
        switch kind {
        case .review: "bolt.badge.clock.fill"
        case .payday: "arrow.left.arrow.right"
        case .carriedOver: "arrow.turn.down.right"
        }
    }
}
