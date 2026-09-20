//
//  TransferLine.swift
//  ExpenseKu
//
//  One row of the payday checklist (PRD §7.5): an Account, the owner's manual
//  adjustment to it, and whether the transfer has been made.
//
//  It deliberately does NOT store the account's total — that is Σ of the plan's items
//  paid from the account, derived in TransferSummary. Storing it would give the same
//  number two homes and let them disagree the moment an item's account changes.
//
//  Created lazily, on the first tick or adjustment. An account with neither has
//  nothing to remember, so no row exists for it and the checklist left-joins.
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
