//
//  PlanEmptyStateButton.swift
//  ExpenseKu
//

import SwiftUI

struct PlanEmptyStateButton: View {
    let title: String
    var isPrimary = true
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.dsBody).bold()
            .foregroundStyle(isPrimary ? Theme.onAccent : Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isPrimary ? Theme.accent : Theme.surface, in: .capsule)
            .overlay {
                if !isPrimary {
                    Capsule().stroke(Theme.hairline, lineWidth: 1)
                }
            }
            .buttonStyle(.pressableCard)
            .padding(.horizontal, Metric.cardPadding)
    }
}
