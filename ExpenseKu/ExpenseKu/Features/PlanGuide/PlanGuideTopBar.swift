//
//  PlanGuideTopBar.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideTopBar: View {
    let title: String
    let closeTitle: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.dsHeadline).bold()
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button(closeTitle, action: onClose)
                .font(.dsSubhead)
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .frame(minWidth: 64, minHeight: 44)
                .background(Theme.surface, in: .capsule)
                .buttonStyle(.pressableCard)
        }
        .padding(.horizontal, Metric.screenPadding)
        .frame(minHeight: 64)
    }
}
