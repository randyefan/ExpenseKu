//
//  AccountGroupState.swift
//  ExpenseKu
//
//  Where a bank's share of the plan stands, read off its items' states
//  (docs/prd/bank-logos.md §5.6.2): "what must BCA cover, and is it there yet?"
//
//  It reads the items, never the transfer line's ✓ Sent: Sent is a fact about the
//  Account, and an item can be Funded without it (CONTEXT.md, Funded).
//

import Foundation

nonisolated enum AccountGroupState: Equatable {
    case nothingIn
    /// The sum of the items still Todo.
    case toGo(Decimal)
    case allIn
    case allPaid

    /// Unassigned can never be Funded, so "nothing in yet" would promise an Account
    /// that does not exist; every Todo item is simply still to go.
    static func of(_ items: [PlanItem], hasAccount: Bool) -> AccountGroupState {
        let states = items.map(PlanItemState.of)
        let todo = zip(items, states).filter { $0.1 == .todo }.reduce(Decimal(0)) { $0 + $1.0.amount }
        if !states.isEmpty, states.allSatisfy({ $0 == .done }) { return .allPaid }
        if states.contains(.todo) {
            let nothingMoved = states.allSatisfy { $0 == .todo }
            return nothingMoved && hasAccount ? .nothingIn : .toGo(todo)
        }
        return states.isEmpty ? .nothingIn : .allIn
    }

    func text(accountName: String) -> String {
        switch self {
        case .nothingIn: "nothing in yet"
        case .toGo(let amount): "\(amount.formattedIDR()) to go"
        case .allIn: PlanCopy.allIn(accountName)
        case .allPaid: "all paid"
        }
    }
}
