//
//  EnvelopePicker.swift
//  ExpenseKu
//
//  The editor's Envelope picker (frames Q2, S1), pushed from the Envelope row. It fetches
//  the expenses of every offered cycle so each envelope can show what it has left; the
//  editor itself has no reason to hold them.
//

import SwiftUI
import SwiftData

struct EnvelopePicker: View {
    @Binding var selection: EnvelopeChoice
    let offer: EnvelopeOffer
    let category: Category?

    @Query private var expenses: [Expense]
    @Environment(\.dismiss) private var dismiss

    init(selection: Binding<EnvelopeChoice>, offer: EnvelopeOffer, category: Category?) {
        _selection = selection
        self.offer = offer
        self.category = category
        let start = offer.cycle.start
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start })
    }

    var body: some View {
        let options = EnvelopeOptions(offer: offer, expenses: expenses)
        EnvelopeChoiceList(options: options,
                           chosen: selection,
                           byCategoryDetail: options.byCategoryDetail(category: category)) { choice in
            selection = choice
            dismiss()
        }
        .navigationTitle("Envelope")
    }
}
