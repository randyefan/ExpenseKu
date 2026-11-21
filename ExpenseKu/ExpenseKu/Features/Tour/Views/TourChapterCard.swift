//
//  TourChapterCard.swift
//  ExpenseKu
//
//  Between chapters (welcome-tour.md §4.2, AO10): a recap under a coin shower; a tap
//  anywhere continues.
//

import SwiftUI

struct TourChapterCard: View {
    let session: TourSession
    let chapter: TourChapter

    var body: some View {
        Button(action: session.continueFromCard) {
            card
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .sensoryFeedback(.success, trigger: chapter)
    }

    private var card: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            TourCoinShower().ignoresSafeArea()
            VStack(spacing: 14) {
                WalletMascot(pose: .happy, size: 110)
                    .padding(.top, -70)
                Text(appLocalized: .tourChapterDone(chapter.rawValue))
                    .font(.dsCaption).bold()
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.accentText)
                Text(appLocalized: chapter.title)
                    .font(.dsLargeTitle).bold()
                    .foregroundStyle(Theme.text)
                Text(appLocalized: chapter.recap)
                    .font(.dsBody)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                TourProgressSegments(fills: TourChapter.allCases.map(session.fill(of:)), track: Theme.surface)
                    .padding(.vertical, 4)
                if let next = chapter.next {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appLocalized: .tourNextChapter(next.rawValue))
                                .font(.dsCaption).bold()
                                .textCase(.uppercase)
                                .foregroundStyle(Theme.textSecondary)
                            Text(appLocalized: next.title)
                                .font(.dsHeadline).bold()
                                .foregroundStyle(Theme.text)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.dsSubhead).bold()
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(14)
                    .background(Theme.surface, in: .rect(cornerRadius: Metric.rowRadius))
                }
            }
            .padding(22)
            .background(Theme.card, in: .rect(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.hairline))
            .frame(maxWidth: 360)
            .padding(.horizontal, 20)

            VStack {
                Spacer()
                Text(appLocalized: .tourTapToContinue)
                    .font(.dsSubhead).bold()
                    .foregroundStyle(Theme.text)
                    .padding(.bottom, 40)
            }
        }
        .contentShape(.rect)
    }
}
