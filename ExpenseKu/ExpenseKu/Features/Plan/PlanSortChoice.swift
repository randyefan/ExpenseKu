//
//  PlanSortChoice.swift
//  ExpenseKu
//
//  The order the owner picked, and the cycle they picked it in, so a cycle change that
//  does not go through paging still returns the plan to Amount (docs/prd/plan-sort.md §5).
//

import Foundation

struct PlanSortChoice: Equatable {
    let cycle: PayCycle
    let sort: PlanSort
}
