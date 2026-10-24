//
//  TransferLine.swift
//  ExpenseKu
//
//  One row of the payday checklist (PRD §7.5): an Account and the owner's manual
//  adjustment to it. How much of the line is in is read off its items
//  (partial-transfer.md §5.1), so the old `hasTransferred` flag is only ever read
//  once, by PlanMaintenance, and cleared.
//
//  It deliberately does NOT store the account's total — that is Σ of the plan's items
//  paid from the account, derived in TransferSummary. Storing it would give the same
//  number two homes and let them disagree the moment an item's account changes.
//
//  Created lazily, on the first adjustment. An account without one has nothing to
//  remember, so no row exists for it and the checklist left-joins.
//
//  The adjustment covers cases like "ke Superbank −Rp 700.000": money already sitting
//  in the account, so transfer less. It is a number inside one plan — the app never
//  claims to know a balance, and could not, since money moves without passing through
//  it (CONTEXT.md: an Account is a label, not a ledger).
//

import Foundation
import SwiftData

@Model
final class TransferLine {
    var account: Account?
    /// Signed. Negative means "transfer less than the plan says".
    var adjustment: Decimal = 0
    /// A Sent tick from before partial-transfer.md; PlanMaintenance converts and clears it.
    var hasTransferred: Bool = false

    var plan: CyclePlan?

    init(account: Account? = nil, adjustment: Decimal = 0,
         hasTransferred: Bool = false, plan: CyclePlan? = nil) {
        self.account = account
        self.adjustment = adjustment
        self.hasTransferred = hasTransferred
        self.plan = plan
    }
}
