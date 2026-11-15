//
//  PlanGuideCaption.swift
//  ExpenseKu
//
//  The active spotlight's caption under ●○○ position dots (plan-guide-visual.md §4.1).
//  VoiceOver hears each new caption as it appears (§4.6).
//

import SwiftUI

struct PlanGuideCaption: View {
    let caption: String
    let position: Int
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(1...max(count, 1), id: \.self) { index in
                    Circle()
                        .fill(index == position ? Theme.accent : Theme.textSecondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)

            Text(caption)
                .font(.dsHeadline).bold()
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .accessibilityLabel(AppLocalization.string(.guideSpotlightOf(position, count, caption)))
        }
        .padding(.horizontal, 4)
        .onChange(of: caption) { _, caption in
            AccessibilityNotification.Announcement(caption).post()
        }
    }
}
