//
//  IncomeLine.swift
//  ExpenseKu
//
//  One source of money expected in a cycle: a name, an amount, and whether it has
//  arrived. Income lives only inside a plan (decision 6) — it is never an Expense,
//  never reaches Insights, and creates no balance. Its only job is to give Sisa and
//  the Group percentages a denominator.
//
//  Free-typed on purpose: no Category, no Account. "Gaji Fulltime", "THR" and a
//  freelance payment share nothing worth modelling.
//

import Foundation
import SwiftData

@Model
final class IncomeLine {
    var name: String = ""
    var amount: Decimal = 0
    /// The owner has ticked this as received. Reset per cycle by carry-over.
    var hasArrived: Bool = false

    var plan: CyclePlan?

    init(name: String = "", amount: Decimal = 0, hasArrived: Bool = false, plan: CyclePlan? = nil) {
        self.name = name
        self.amount = amount
        self.hasArrived = hasArrived
        self.plan = plan
    }
}
