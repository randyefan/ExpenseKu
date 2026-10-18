//
//  ExpenseRowLead.swift
//  ExpenseKu
//
//  What leads an expense row (docs/prd/bank-logos.md §5.5, flow Z): the Account's mark
//  with the category riding on it as a badge, or the category icon alone. The Account
//  leads whenever there is one, logo or not, so the leading column always reads as
//  Accounts; an Unassigned expense has nothing to lead with but its category.
//
//  A list where every row shares one Account turns the lead off: the logo would repeat
//  down the whole column what the screen's header already says.
//

import Foundation

nonisolated enum ExpenseRowLead: Equatable {
    case account
    case category

    static func resolve(hasAccount: Bool, accountsLead: Bool) -> ExpenseRowLead {
        hasAccount && accountsLead ? .account : .category
    }

    var showsBadge: Bool { self == .account }

    var showsAccountName: Bool { self == .account }

    /// An Insights drill-in lists one Account's expenses when its subject, or the
    /// dimension it is narrowed to, is an Account.
    static func accountsLead(subject: SpendSubject, narrowing: SpendSubject?) -> Bool {
        !isAccount(subject) && !(narrowing.map(isAccount) ?? false)
    }

    private static func isAccount(_ subject: SpendSubject) -> Bool {
        !subject.isCategory
    }
}
