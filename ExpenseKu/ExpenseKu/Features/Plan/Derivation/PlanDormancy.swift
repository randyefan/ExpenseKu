//
//  PlanDormancy.swift
//  ExpenseKu
//
//  Which plan rows are in use this cycle, which are folded away, and the order they
//  all sit in (PRD §7.2, §9.1).
//
//  Carry-over copies everything, which is what the spreadsheet does too — the owner
//  keeps Rp 0 rows deliberately, as reminders. But they accumulate: 11 dead rows in
//  January, 18 by September. Folding them keeps the reminder and drops the clutter.
//
//  Dormant means amount zero AND never completed. The PRD's §7.2 says "Rp 0 **or**
//  never completed", which cannot be meant literally — a freshly copied row is by
//  definition never completed, so the OR reading folds Cicilan Rumah BNI at
//  Rp 7.706.000 into a collapsed section the instant the owner pages forward. The AND
//  reading is CONTEXT.md's ("amount zero, never completed"), and CONTEXT.md is the
//  ubiquitous language.
//
//  It also requires `carriedOver`, so a Rp 0 row the owner is halfway through typing
//  in F2 stays where they can see it.
//

import Foundation

nonisolated enum PlanDormancy {
    static func isDormant(_ item: PlanItem) -> Bool {
        item.carriedOver && item.amount == 0 && !item.isDone
    }

    /// Active rows first, in display order; dormant rows in their own list for the
    /// "From last cycle" section.
    static func split(_ items: [PlanItem]) -> (active: [PlanItem], dormant: [PlanItem]) {
        (active: sorted(items.filter { !isDormant($0) }),
         dormant: sorted(items.filter(isDormant)))
    }

    /// Amount descending, matching the spreadsheet (§9.1). Name then creation order
    /// break ties, so the list is stable across launches and across devices — an
    /// unstable sort makes a screenshot comparison meaningless.
    static func sorted(_ items: [PlanItem]) -> [PlanItem] {
        items.sorted { a, b in
            if a.amount != b.amount { return a.amount > b.amount }
            if a.name != b.name { return a.name < b.name }
            return a.createdAt < b.createdAt
        }
    }
}
