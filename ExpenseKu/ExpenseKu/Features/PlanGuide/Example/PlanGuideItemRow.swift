//
//  PlanGuideItemRow.swift
//  ExpenseKu
//
//  One plan item drawn by the Plan lens's own row for its kind, with every action a no-op:
//  the example is inert (plan-guide-visual.md §4.2).
//

import SwiftUI

struct PlanGuideItemRow: View {
    let item: PlanItem
    let sample: PlanGuideSample

    var body: some View {
        if item.isSetAside {
            PlanSetAsideRow(item: item, payday: PlanGuideSample.payday, calendar: sample.calendar,
                            onChooseFunding: { _ in }, onSelect: {})
        } else if item.isEnvelope {
            PlanEnvelopeRow(item: item, progress: sample.contents.envelope(for: item),
                            onChooseFunding: { _ in }, onSelect: {}, onAddExpense: {}, onMoveExpenses: {})
        } else {
            PlanFixedRow(item: item, cycle: sample.cycle, today: sample.today, calendar: sample.calendar,
                         onTapCheck: {}, onChooseFunding: { _ in }, onSelect: {})
        }
    }
}
