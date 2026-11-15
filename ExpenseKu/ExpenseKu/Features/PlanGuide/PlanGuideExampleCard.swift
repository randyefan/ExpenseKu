//
//  PlanGuideExampleCard.swift
//  ExpenseKu
//
//  A static picture of the November sample, labelled as an example so it never reads
//  as the owner's own plan (plan-guide.md §5, §8.1). Nothing in it is tappable.
//

import SwiftUI

struct PlanGuideExampleCard: View {
    let example: PlanGuideExample

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text(example.title)
                    .font(.dsHeadline).bold()
                    .foregroundStyle(Theme.text)
                Text(example.label)
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)

            ForEach(example.rows.enumerated(), id: \.offset) { _, row in
                PlanGuideExampleRowView(row: row)
            }

            if let summary = example.summary {
                Rectangle().fill(Theme.hairline).frame(height: 1)
                PlanGuideExampleRowView(row: summary, isSummary: true)
            }

            if let actionTitle = example.actionTitle {
                Text(actionTitle)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.surface, in: .capsule)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
