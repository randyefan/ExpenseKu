//
//  ReceiptSourceCard.swift
//  ExpenseKu
//
//  The card above the amount that says who read the receipt: Gemma AI, or OCR with no AI
//  and why (docs/prd/reading-source.md §4.2, frame AI2). Shaped like a receipt banner row;
//  only the no-model card is a button, and it opens Receipt reading.
//

import SwiftUI

struct ReceiptSourceCard: View {
    let source: ReceiptReadingSource
    let modelIsReady: Bool
    let onGetModel: () -> Void

    var body: some View {
        if source.offersDownload(modelIsReady: modelIsReady) {
            Button(action: onGetModel) {
                content(showsChevron: true)
            }
            .buttonStyle(.pressableCard)
            .accessibilityHint("Opens Receipt reading")
        } else {
            content(showsChevron: false)
        }
    }

    private func content(showsChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(source.isAI ? Theme.accent.opacity(Theme.tintFillOpacity) : Theme.surface)
                .frame(width: Metric.rowIconSize, height: Metric.rowIconSize)
                .overlay {
                    Image(systemName: source.systemImage)
                        .font(.dsSubhead.weight(.semibold))
                        .foregroundStyle(source.isAI ? Theme.accent : Theme.text)
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                Text(source.caption(modelIsReady: modelIsReady))
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .fill(Theme.card)
                .stroke(Theme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
