//
//  PaidElsewhere.swift
//  ExpenseKu
//
//  The PAID ELSEWHERE section of an envelope's detail (docs/prd/paid-elsewhere.md §4):
//  one row per other Account the envelope's expenses were paid from, and how much of it
//  the owner has moved back from the envelope's own Account.
//
//  Travelling is kept in Jago, but the trip's Grab went on CC Danamon. The envelope
//  counts the Grab either way; what nothing said is that its money is still in Jago while
//  the bill lands on the card. The rows say it, per Account.
//
//  It takes the expenses the detail already lists (`EnvelopeDetail.expenses`), so the
//  section can never name an expense the list under it does not. An expense with no
//  Account counts as paid from the envelope's own (§4.2): accounts are optional at
//  entry, and a row for them would be a task that is not real.
//

import Foundation
import SwiftData

nonisolated struct PaidElsewhere {
    let rows: [PaidElsewhereRow]

    init(envelope: PlanItem, expenses: [Expense], calendar: Calendar = .current) {
        guard let home = envelope.account else {
            rows = []
            return
        }
        let homeID = home.persistentModelID
        var byAccount: [PersistentIdentifier: (account: Account, expenses: [Expense])] = [:]
        for expense in expenses {
            guard let account = expense.account, account.persistentModelID != homeID else { continue }
            byAccount[account.persistentModelID, default: (account, [])].expenses.append(expense)
        }
        rows = byAccount.values.map { group in
            PaidElsewhereRow(account: group.account, homeName: home.name,
                             members: group.expenses.map { PaidElsewhereMember(expense: $0, calendar: calendar) })
        }
        .sorted(by: PaidElsewhereRow.precedes)
    }

    var isEmpty: Bool { rows.isEmpty }

    func row(for account: Account) -> PaidElsewhereRow? {
        rows.first { $0.id == account.persistentModelID }
    }

    /// Setting an expense's Account clears its mark when the Account changes (§4.6): the
    /// money it says was moved was moved to the old one.
    static func setAccount(_ account: Account?, on expense: Expense) {
        if expense.account?.persistentModelID != account?.persistentModelID {
            expense.isMovedFromEnvelope = false
        }
        expense.account = account
    }
}
