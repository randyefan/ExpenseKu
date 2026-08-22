//
//  EmptyStateView.swift
//  ExpenseKu — DesignSystem
//
//  The full-bleed empty state: a soft badge, a title and a line of guidance.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    @ScaledMetric(relativeTo: .largeTitle) private var badgeSize: CGFloat = 96

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            ZStack {
                Circle()
                    .fill(Theme.textSecondary.opacity(0.12))
                    .frame(width: badgeSize, height: badgeSize)
                Image(systemName: systemImage)
                    .font(.system(size: badgeSize * (40 / 96), weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.bottom, 4)
            Text(title)
                .font(.dsTitle).bold()
                .foregroundStyle(Theme.text)
            Text(message)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metric.screenPadding)
        .warmBackground()
    }
}

#Preview("Default") {
    EmptyStateView(title: "No expenses yet", systemImage: "doc.text",
                   message: "Tap + to log your first expense.")
}

#Preview("Aksesibilitas XXL") {
    EmptyStateView(title: "No expenses yet", systemImage: "doc.text",
                   message: "Tap + to log your first expense.")
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Gelap") {
    EmptyStateView(title: "No Categories", systemImage: "folder",
                   message: "Add one with the + button.")
        .preferredColorScheme(.dark)
}
