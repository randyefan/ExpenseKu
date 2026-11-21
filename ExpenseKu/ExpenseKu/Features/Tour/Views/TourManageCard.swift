//
//  TourManageCard.swift
//  ExpenseKu
//
//  Manage's way back into the tour until it is finished (welcome-tour.md §4.9, AO21).
//

import SwiftUI

struct TourManageCard: View {
    let done: Set<TourChapter>
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            WalletMascot(pose: .waving, size: 64)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(appLocalized: .tourName)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.text)
                Text(appLocalized: .tourChaptersDone(done.count))
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                TourProgressSegments(fills: TourChapter.allCases.map { done.contains($0) ? 1 : 0 },
                                     track: Theme.surface)
            }
            Button(AppLocalization.string(.tourOpen), action: onOpen)
                .buttonStyle(.tour(.primary, fillsWidth: false, height: 44))
        }
        .padding(Metric.cardPadding)
        .background(Theme.card, in: .rect(cornerRadius: Metric.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Metric.cardRadius).stroke(Theme.accent.opacity(0.6), lineWidth: 1.5))
    }
}
