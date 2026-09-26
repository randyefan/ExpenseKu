//
//  FundedSummary.swift
//  ExpenseKu
//
//  The funded notice: "In the account, not yet paid · 3 items · Rp 10.706.000"
//  (PRD §7.6, frames L1 and L6).
//
//  Fixed items only (decision 30). An Envelope's Funded is its last state — it has
//  nothing left to pay — so counting it would leave the notice up for the whole cycle.
//  The total is the planned figure: nothing has been paid yet, so there is no actual.
//

import Foundation

nonisolated struct FundedSummary {
    let items: [PlanItem]

    init(activeItems: [PlanItem]) {
        items = activeItems.filter { !$0.isEnvelope && PlanItemState.of($0) == .funded }
    }

    var isEmpty: Bool { items.isEmpty }
    var total: Decimal { items.reduce(0) { $0 + $1.amount } }

    var title: String { "In the account, not yet paid" }
    var detail: String { PlanCopy.counted(items.count, "item") + " · " + total.formattedIDR() }
}
