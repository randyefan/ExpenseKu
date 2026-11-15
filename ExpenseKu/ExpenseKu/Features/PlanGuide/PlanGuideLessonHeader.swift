//
//  PlanGuideLessonHeader.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideLessonHeader: View {
    let title: String
    let step: Int
    let stepCount: Int
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            PlanGuideTopBar(title: title, closeTitle: AppLocalization.string(.close), onClose: onClose)
            HStack(spacing: 8) {
                ForEach(1...stepCount, id: \.self) { segment in
                    Capsule()
                        .fill(segment <= step ? Theme.accent : Theme.hairline)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, Metric.screenPadding)
            .padding(.bottom, 16)
            .accessibilityHidden(true)
        }
        .background(Theme.bg)
    }
}
