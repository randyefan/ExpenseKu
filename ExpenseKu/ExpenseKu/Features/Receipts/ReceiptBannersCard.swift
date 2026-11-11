//
//  ReceiptBannersCard.swift
//  ExpenseKu
//
//  The inbox and review banners in one card, under the lens toggle in every lens, inbox
//  first (docs/prd/receipt-reading.md §4.2, frame AG2; the inbox caption follows §4.11,
//  frames AG10 and AG11). A banner with nothing to count is
//  not drawn, and the card goes with the last one.
//

import SwiftUI

struct ReceiptBannersCard: View {
    let waiting: Int
    let inboxCaption: ReceiptInboxCaption
    let toCheck: Int
    let onInbox: () -> Void
    let onReview: () -> Void

    var body: some View {
        if waiting > 0 || toCheck > 0 {
            VStack(spacing: 0) {
                if waiting > 0 {
                    ReceiptBannerRow(title: AppLocalization.string(.receiptWaiting(waiting)),
                                     caption: inboxCaptionText,
                                     systemImage: "receipt", isAccent: true, action: onInbox)
                }
                if waiting > 0, toCheck > 0 {
                    Divider().overlay(Theme.hairline).padding(.leading, Metric.rowIconSize + 12)
                }
                if toCheck > 0 {
                    ReceiptBannerRow(title: AppLocalization.string(.fromReceiptsToCheck(String(toCheck))),
                                     caption: AppLocalization.string(.savedFromAReceiptNotCheckedYet),
                                     systemImage: "list.clipboard", isAccent: false, action: onReview)
                }
            }
            .padding(.horizontal, Metric.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .fill(Theme.card)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            }
            .padding(.bottom, Metric.cardGap)
        }
    }

    private var inboxCaptionText: String {
        switch inboxCaption {
        case .shared: AppLocalization.string(.sharedToExpenseKuOnThisIPhone)
        case .reading(let progress): AppLocalization.string(.readingOf(String(progress.position), String(progress.total)))
        case .ready: AppLocalization.string(.readyToCheck)
        }
    }
}
