//
//  ReceiptCheckCard.swift
//  ExpenseKu
//
//  One receipt expense on the review sheet: the receipt beside what was saved, then Edit
//  and Looks right (docs/prd/receipt-reading.md §4.8, frame AG7).
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
                .accessibilityLabel("Receipt image")
                .accessibilityHint("Shows the receipt full screen")

                VStack(alignment: .leading, spacing: 6) {
                    MoneyText(expense.amount, font: .dsTitle.bold())
                    Text(expense.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute()))
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                    ReceiptFieldRow(label: "Account", value: expense.account?.name ?? "None")
                    ReceiptFieldRow(label: "Category", value: expense.category?.name ?? "Uncategorized")
                    if !expense.note.isEmpty {
                        ReceiptFieldRow(label: "Note", value: expense.note)
                    }
                }
            }
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.dsSubhead).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Theme.surface, in: .capsule)
                }
                Button(action: onLooksRight) {
                    Text("Looks right")
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
