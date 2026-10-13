//
//  EnvelopePicker.swift
//  ExpenseKu
//
//  The editor's Envelope picker (frame Q2), pushed from the Envelope row. It fetches
//  the cycle's own expenses so each envelope can show what it has left; the editor
//  itself has no reason to hold them.
//

import SwiftUI
import SwiftData

struct EnvelopePicker: View {
    @Binding var selection: EnvelopeChoice
    let plan: CyclePlan?
    let category: Category?

    @Query private var cycleExpenses: [Expense]
    @Environment(\.dismiss) private var dismiss

    init(selection: Binding<EnvelopeChoice>, plan: CyclePlan?, cycle: PayCycle, category: Category?) {
        _selection = selection
        self.plan = plan
        self.category = category
        let start = cycle.start
        let end = cycle.end
        _cycleExpenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end })
    }

    var body: some View {
        let options = EnvelopeOptions(plan: plan, cycleExpenses: cycleExpenses)
        EnvelopeChoiceList(options: options,
                           chosen: selection,
                           byCategoryDetail: options.byCategoryDetail(category: category)) { choice in
            selection = choice
            dismiss()
        }
        .navigationTitle("Envelope")
    }
}
