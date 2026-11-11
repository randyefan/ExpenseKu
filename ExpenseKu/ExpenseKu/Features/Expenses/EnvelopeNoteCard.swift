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
            TextField(AppLocalization.string(.addANote), text: $note, axis: .vertical)
                .font(.dsBody)
                .focused(notesFocused)
                .padding(.vertical, 14)
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
