//
//  Expense.swift
//  ExpenseKu
//
//  A single record of money the owner spent. Amount + when + one Category +
//  zero-or-more People. See CONTEXT.md for the ubiquitous language.
//
//  An Expense may now have been created by a Fixed PlanItem, but it is still only
//  ever money that already left: the plan's own figures live on PlanItem and never
//  reach a spending total (ADR-0005).
//

import Foundation
import SwiftData

@Model
final class Expense {
    // `date` drives every read path: the cycle list's sort, the calendar grouping and
    // all Insights range filters. Writes are rare (one per logged expense) and reads
    // are constant, so the index's write cost pays for itself here.
    #Index<Expense>([\.date])

    // All stored properties are defaulted for CloudKit mirroring (no non-optional,
    // no-default attributes allowed). Money is Decimal, never Double.
    var amount: Decimal = 0
    var date: Date = Date.now
    var note: String = ""

    // Relationships are optional per CloudKit. `category` is required by the UI at
    // entry (see design.md §5); it can only become nil later via category deletion,
    // which the UI renders as "Uncategorized" (ADR-0001). Inverses live on the
    // Category/Person side.
    var category: Category?
    var people: [Person]? = []

    // The payment source this expense was paid from (Cash, a bank, an e-wallet).
    // Optional — unlike category — and "Unassigned" when nil. Deleting an Account
    // nullifies this rather than destroying the expense (ADR-0001). Inverse lives
    // on the Account side.
    var account: Account?

    // The Fixed PlanItem that created this expense, if any. Deleting that item drops
    // the link and leaves the expense as history (PRD §9.4); deleting this expense
    // returns the item to not-done (§9.5), which costs nothing because `isDone` is
    // derived from the link. Inverse lives on the PlanItem side.
    var planItem: PlanItem?

    // Written by an Auto item without confirmation (ADR-0007), and unconfirmed until
    // the owner clears it. The Plan lens's review notice is the only prompt, and the
    // only defence against a failed autodebit being recorded as fact.
    var needsReview: Bool = false

    init(
        amount: Decimal = 0,
        date: Date = .now,
        note: String = "",
        category: Category? = nil,
        people: [Person] = [],
        account: Account? = nil,
        planItem: PlanItem? = nil,
        needsReview: Bool = false
    ) {
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
        self.people = people
        self.account = account
        self.planItem = planItem
        self.needsReview = needsReview
    }
}
