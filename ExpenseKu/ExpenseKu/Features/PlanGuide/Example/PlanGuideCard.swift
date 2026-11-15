//
//  PlanGuideCard.swift
//  ExpenseKu
//
//  The inset-grouped section the Plan lens draws its rows in, as a plain stack: a List
//  inside the guide's scroll view would scroll on its own and drop the spotlight anchors.
//

import SwiftUI

struct PlanGuideCard<Content: View>: View {
    var header: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let header {
                SectionHeaderText(header)
                    .padding(.horizontal, 4)
            }
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(rows.enumerated(), id: \.element.id) { index, row in
                        if index > 0 {
                            Rectangle().fill(Theme.hairline).frame(height: 1)
                        }
                        row
                    }
                }
            }
            .padding(.horizontal, Metric.cardPadding)
            .background(Theme.card, in: .rect(cornerRadius: Metric.cardRadius))
        }
    }
}
