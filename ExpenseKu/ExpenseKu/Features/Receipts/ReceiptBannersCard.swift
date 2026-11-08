//
//  ReceiptBannersCard.swift
//  ExpenseKu
//
//  The inbox and review banners in one card, under the lens toggle in every lens, inbox
//  first (docs/prd/receipt-reading.md §4.2, frame AG2). A banner with nothing to count is
//  not drawn, and the card goes with the last one.
//

import SwiftUI

struct ReceiptBannersCard: View {
    let waiting: Int
    let toCheck: Int
    let onInbox: () -> Void
    let onReview: () -> Void

    var body: some View {
        if waiting > 0 || toCheck > 0 {
            VStack(spacing: 0) {
                if waiting > 0 {
                    ReceiptBannerRow(title: "^[\(waiting) receipt](inflect: true) waiting",
                                     caption: "Shared to ExpenseKu on this iPhone",
                                     systemImage: "receipt", isAccent: true, action: onInbox)
                }
                if waiting > 0, toCheck > 0 {
                    Divider().overlay(Theme.hairline).padding(.leading, Metric.rowIconSize + 12)
                }
                if toCheck > 0 {
                    ReceiptBannerRow(title: "\(toCheck) from receipts to check",
                                     caption: "Saved from a receipt, not checked yet",
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
}
