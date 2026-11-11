//
//  ReceiptBannerRow.swift
//  ExpenseKu
//
//  One row of the receipt banners card: an icon circle, a title, a caption, a chevron,
//  shaped like a Manage row (frame AG2).
//

import SwiftUI

struct ReceiptBannerRow: View {
    let title: String
    let caption: String
    let systemImage: String
    let isAccent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isAccent ? Theme.accent.opacity(Theme.tintFillOpacity) : Theme.surface)
                    .frame(width: Metric.rowIconSize, height: Metric.rowIconSize)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.dsSubhead.weight(.semibold))
                            .foregroundStyle(isAccent ? Theme.accent : Theme.text)
                    }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                    Text(caption)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.pressableRow)
    }
}
