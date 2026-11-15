//
//  PlanGuideFooter.swift
//  ExpenseKu
//
//  Pinned above the home indicator so the only way forward never needs a scroll to
//  reach (plan-guide.md §4.6).
//

import SwiftUI

struct PlanGuideFooter: View {
    let secondaryTitle: String
    let primaryTitle: String
    let onSecondary: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(appLocalized: .guideDisclaimer)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button(secondaryTitle, action: onSecondary)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 88, minHeight: 52)
                    .background(Theme.surface, in: .capsule)
                    .buttonStyle(.pressableCard)
                Button(primaryTitle, action: onPrimary)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.accent, in: .capsule)
                    .buttonStyle(.pressableCard)
            }
        }
        .padding(.horizontal, Metric.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.bg)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}
