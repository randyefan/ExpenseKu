//
//  EnvelopeNoteCard.swift
//  ExpenseKu
//
//  The editor's last card: the Envelope row, when an envelope is on offer, over the note.
//

import SwiftUI

struct EnvelopeNoteCard: View {
    let envelope: EnvelopeField?
    let category: Category?
    @Binding var note: String
    var notesFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 0) {
            if let envelope {
                EnvelopeFormRow(field: envelope, category: category)
                    .padding(.vertical, 14)
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
            }
            HStack {
                TextField(AppLocalization.string(.addANote), text: $note, axis: .vertical)
                    .font(.dsBody)
                    .focused(notesFocused)
                    .accessibilityIdentifier("expenseDescription")
                    .padding(.vertical, 14)
                if !note.isEmpty {
                    Button(AppLocalization.string(.clearDescription), systemImage: "xmark.circle.fill") {
                        note = ""
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
                    .accessibilityIdentifier("clearExpenseDescription")
                }
            }
        }
        .padding(.horizontal, Metric.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .fill(Theme.card)
                .stroke(Theme.hairline, lineWidth: 1)
        }
        .padding(.horizontal, Metric.screenPadding)
    }
}
