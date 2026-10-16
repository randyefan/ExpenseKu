//
//  ExpensesView+EnvelopeDetail.swift
//  ExpenseKu
//
//  The envelope detail's hand-offs (envelope-detail.md §4.6). Edit, ＋ and every row
//  action close the detail, open their own sheet from here, and bring the detail back
//  when that sheet closes — the owner chose never to stack a sheet on the detail.
//
//  The next sheet waits for the detail's onDismiss: presenting it while the detail is
//  still animating away is dropped by SwiftUI. Coming back waits for the other sheet's
//  onDismiss, and for the delete confirmation when Edit led to one, so a deleted
//  envelope is gone before `EnvelopeDetail.canReopen` is asked.
//

import SwiftUI

extension ExpensesView {
    func leaveEnvelopeDetail(_ envelope: PlanItem, cycle: PayCycle, for action: EnvelopeDetailAction) {
        envelopeDetailVisit = EnvelopeDetailVisit(envelope: envelope, cycle: cycle, pending: action)
        envelopeSheet = nil
    }

    /// The envelope sheet's onDismiss: either the detail has closed with a hand-off
    /// waiting, or a gather or move sheet opened from it has closed.
    func envelopeSheetDismissed() {
        guard var visit = envelopeDetailVisit else { return }
        guard let action = visit.pending else { return returnToEnvelopeDetail() }
        visit.pending = nil
        envelopeDetailVisit = visit
        open(action, for: visit)
    }

    func returnToEnvelopeDetail() {
        guard let visit = envelopeDetailVisit, visit.pending == nil, planConfirmation == nil else { return }
        envelopeDetailVisit = nil
        guard EnvelopeDetail.canReopen(visit.envelope) else { return }
        envelopeSheet = .detail(visit.envelope, visit.cycle)
    }

    private func open(_ action: EnvelopeDetailAction, for visit: EnvelopeDetailVisit) {
        switch action {
        case .edit:
            planSheet = .editPlanItem(visit.envelope)
        case .addExpense:
            newExpense = NewExpensePreset(
                envelope: visit.envelope,
                date: EnvelopeAddDate.date(in: visit.cycle, now: .now, calendar: .current)
            )
        case .moveExpenses:
            envelopeSheet = .gather(visit.envelope, visit.cycle)
        case .move(let request):
            envelopeSheet = .move(request)
        case .openExpense(let expense):
            selection = expense
        }
    }
}
