//
//  ReadingReceiptOverlay.swift
//  ExpenseKu
//
//  "Reading receipt…" over the dimmed form, with Cancel, which leaves the form as it was
//  (docs/prd/receipt-reading.md §4.3, frame AG3b).
//

import SwiftUI

struct ReadingReceiptOverlay: View {
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Theme.bg.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Theme.accent)
                    .controlSize(.large)
                Text(appLocalized: .readingReceipt)
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                Button(AppLocalization.string(.cancel), action: onCancel)
                    .font(.dsSubhead.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 36)
                    .background(Theme.surface, in: .capsule)
            }
            .padding(20)
            .frame(maxWidth: 290)
            .background {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .fill(Theme.card)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
        }
        .transition(.opacity)
    }
}
