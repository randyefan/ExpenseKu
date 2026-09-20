//
//  ReviewState.swift
//  ExpenseKu
//
//  What the Plan lens's notice says, and what the review sheet behind it lists
//  (PRD §6.1.2, §7.3, ADR-0007).
//
//  Materialisation is lazy — iOS does not run the app in the background — so an Auto
//  expense appears the first time the app is opened after its due day passes. Five
//  days away means five expenses at once on the next launch, and the notice has to
//  read sensibly in that case, which is why the copy is derived from the count rather
//  than written once.
//
//  The notice is tappable (decision 21). Without a route to the amount, the flag
//  could only be dismissed, never acted on — and a failed autodebit or a changed
//  amount (`Cicil ke Kartu Kredit` ran Rp 6.751.000 in February and Rp 4.700.000 in
//  August) would stay invisible. A dismissed notice is the only defence ADR-0007 has,
//  and it accepts that it is a prompt, not a guarantee.
//

import Foundation

nonisolated struct ReviewState: Equatable {
    let lines: [ReviewLine]

    var postedCount: Int { lines.count }
    var isEmpty: Bool { lines.isEmpty }

    /// The notice headline. Plural and singular both have to read naturally, because
    /// one item posting is as common as five.
    var title: String { PlanCopy.counted(postedCount, "Auto item") + " posted" }

    /// The second line. It changes with the burst, because "while you were away" is
    /// a lie when a single item fired this morning.
    var detail: String {
        postedCount > 1
            ? "Written without confirmation while you were away. Check the amounts."
            : "Written without confirmation. Check the amount."
    }

    init(cycleItems: [PlanItem]) {
        lines = cycleItems.compactMap { item in
            guard let expense = item.linkedExpense, expense.needsReview else { return nil }
            return ReviewLine(name: item.name, actual: expense.amount, planned: item.amount)
        }
        .sorted { $0.actual > $1.actual }
    }
}

/// One row of the review sheet (frame I3). Each opens the Expense in the ordinary
/// expense editor, so a wrong amount can be corrected where every other amount is.
nonisolated struct ReviewLine: Identifiable, Equatable {
    let name: String
    let actual: Decimal
    let planned: Decimal

    var id: String { name }

    var matchesPlan: Bool { actual == planned }
}
