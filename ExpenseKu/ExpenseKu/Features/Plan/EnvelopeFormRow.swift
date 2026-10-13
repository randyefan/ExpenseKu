//
//  EnvelopeFormRow.swift
//  ExpenseKu
//
//  The expense editor's Envelope row (frames Q1, Q3). A by-category value keeps its
//  "· by category" suffix whole and lets the envelope's name truncate instead, since
//  the suffix is what says the row has not been chosen (envelope-assignment.md §4.3).
//

import SwiftUI

struct EnvelopeFormRow: View {
    let field: EnvelopeField
    let category: Category?

    var body: some View {
        NavigationLink {
            EnvelopePicker(selection: field.choice, plan: field.plan, cycle: field.cycle, category: category)
        } label: {
            HStack(spacing: 8) {
                Text("Envelope")
                    .foregroundStyle(Theme.text)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Text(field.value.name)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let suffix = field.value.suffix {
                        Text(suffix)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                .foregroundStyle(field.value.isChosen ? Theme.text : Theme.textSecondary)
            }
            .font(.dsBody)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Envelope")
            .accessibilityValue([field.value.name, field.value.suffix].compactMap { $0 }.joined(separator: " "))
        }
        .listRowBackground(Theme.card)
    }
}
