//
//  EnvelopeMoveSheet.swift
//  ExpenseKu
//
//  "Move N expenses" (frame Q8): the picker's choices for a selection or for one row's
//  long-press (envelope-assignment.md §4.6, §4.8). Nothing is ticked, because a
//  selection may be mixed, and picking applies at once — moving again is the undo.
//
//  It fetches the plans and the offered cycles' expenses for the remainders, and writes
//  the move itself, so every screen that lists expenses can raise it the same way.
//

import SwiftUI
import SwiftData

struct EnvelopeMoveSheet: View {
    let request: EnvelopeMoveRequest
    let onApplied: () -> Void

    @Query private var expenses: [Expense]
    @Query(sort: \CyclePlan.cycleStart) private var plans: [CyclePlan]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    init(request: EnvelopeMoveRequest, onApplied: @escaping () -> Void = {}) {
        self.request = request
        self.onApplied = onApplied
        let start = request.cycle.start
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start })
    }

    var body: some View {
        let offer = EnvelopeOffer(cycle: request.cycle, plans: plans, payday: Payday.current,
                                  calendar: .current, now: .now)
        let options = EnvelopeOptions(offer: offer, expenses: expenses)
        NavigationStack {
            EnvelopeChoiceList(options: options,
                               chosen: nil,
                               byCategoryDetail: request.expenses.count == 1
                                   ? options.byCategoryDetail(category: request.expenses.first?.category)
                                   : EnvelopeOptions.byCategoryDetailForMany) { choice in
                choice.apply(to: request.expenses, envelopes: options.envelopes)
                try? context.save()
                onApplied()
                dismiss()
            }
            .navigationTitle("Move \(PlanCopy.counted(request.expenses.count, "expense"))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
