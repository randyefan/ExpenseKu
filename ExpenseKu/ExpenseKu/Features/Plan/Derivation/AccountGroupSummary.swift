//
//  AccountGroupSummary.swift
//  ExpenseKu
//
//  The right-hand side of a bank header when the plan is sorted by Account
//  (docs/prd/bank-logos.md §5.6.2). The total is the sum of the rows beneath it, not
//  the transfer line's net figure, so the header always agrees with what it heads.
//

import Foundation

nonisolated struct AccountGroupSummary: Equatable {
    let total: Decimal
    let count: String
    let state: AccountGroupState

    init(items: [PlanItem], hasAccount: Bool) {
        total = items.reduce(0) { $0 + $1.amount }
        count = PlanCopy.itemCount(items)
        state = .of(items, hasAccount: hasAccount)
    }
}
