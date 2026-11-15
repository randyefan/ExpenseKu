//
//  PlanGuideTopicGroup.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideTopicGroup: View {
    let title: String
    let topics: [PlanGuideMaterial]
    let progress: PlanGuideProgress
    let onOpen: (PlanGuideMaterial) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.dsSubhead).bold()
                .foregroundStyle(Theme.textSecondary)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(topics.enumerated(), id: \.element) { index, topic in
                    if index > 0 {
                        Rectangle().fill(Theme.hairline).frame(height: 1)
                            .padding(.leading, Metric.cardPadding)
                    }
                    PlanGuideTopicRow(material: topic, status: progress.status(of: topic)) {
                        onOpen(topic)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .fill(Theme.card)
                    .stroke(Theme.hairline, lineWidth: 1)
            }
        }
    }
}
