//
//  ReceiptCheckCard.swift
//  ExpenseKu
//
//  One receipt expense on the review sheet: the receipt beside what was saved, then Edit
//  and Looks right (docs/prd/receipt-reading.md §4.8, frame AG7), with who read it
//  (docs/prd/reading-source.md §4.4, frame AI5).
//

import SwiftUI

struct ReceiptCheckCard: View {
    let expense: Expense
    let onImage: () -> Void
    let onEdit: () -> Void
    let onLooksRight: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onImage) {
                    ReceiptThumbnail(data: expense.receiptImage, width: 104, height: 150)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.string(.receiptImage))
                .accessibilityHint(AppLocalization.string(.showsTheReceiptFullScreen))

                VStack(alignment: .leading, spacing: 6) {
                    MoneyText(expense.amount, font: .dsTitle.bold())
                    Text(expense.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute().locale(AppLocalization.locale)))
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                    if let source = expense.receiptSource {
                        ReceiptSourceTag(source: source)
                    }
                    ReceiptFieldRow(label: AppLocalization.string(.account), value: expense.account?.name ?? AppLocalization.string(.none))
                    ReceiptFieldRow(label: AppLocalization.string(.category), value: expense.category?.name ?? AppLocalization.string(.uncategorized))
                    if !expense.note.isEmpty {
                        ReceiptFieldRow(label: AppLocalization.string(.note), value: expense.note)
                    }
                }
            }
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Text(appLocalized: .edit)
                        .font(.dsSubhead).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Theme.surface, in: .capsule)
                }
                Button(action: onLooksRight) {
                    Text(appLocalized: .looksRight)
                        .font(.dsSubhead).fontWeight(.semibold)
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Theme.accent, in: .capsule)
                }
            }
            .buttonStyle(.pressableCard)
        }
        .padding(Metric.cardGap)
        .background {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .fill(Theme.card)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }
}
