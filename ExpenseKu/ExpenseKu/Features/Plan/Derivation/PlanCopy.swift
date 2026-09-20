//
//  PlanCopy.swift
//  ExpenseKu
//
//  The strings that name money and dates. They live in a tested pure type rather than
//  inline in a `.confirmationDialog`, because every one of them is a promise about
//  what a button is about to do — "the Rp 4.750.000 expense it created on 20 October
//  stays in your ledger" is the difference between an informed tap and a surprise.
//

import Foundation

nonisolated enum PlanCopy {
    /// "1 item" / "14 items".
    ///
    /// The app's `^[\(n) category](inflect: true)` markup is resolved by `Text`, not
    /// by string interpolation, so it stays literal in a plain `String` and would ship
    /// the markup to the screen. These strings are assembled here and tested here, so
    /// they pluralise here. Every user-facing string in the app is hardcoded English.
    static func counted(_ count: Int, _ singular: String, plural: String? = nil) -> String {
        "\(count) " + (count == 1 ? singular : (plural ?? singular + "s"))
    }

    /// The plan list's section header: "PLAN · 14 ITEMS", or G1's
    /// "PLAN · 16 ITEMS · NONE DONE YET" on the morning a cycle opens.
    static func sectionTitle(itemCount: Int, doneCount: Int) -> String {
        let items = "Plan · " + counted(itemCount, "item")
        guard itemCount > 0, doneCount == 0 else { return items }
        return "\(items) · none done yet"
    }

    /// E5's notice, naming where the plan came from and how much arrived. The source
    /// is named by the month its cycle *ended* in, exactly as the cycle header names a
    /// cycle (Q4) — "Copied from September" has to mean the September the owner just
    /// paged away from, not the month its payday fell in.
    static func carriedOver(from sourceCycleStart: Date, payday: Int, items: Int,
                            incomeLines: Int, calendar: Calendar = .current) -> String {
        let source = PayCycle.containing(sourceCycleStart, payday: payday, calendar: calendar)
        return "Copied from \(source.title(calendar: calendar)) — "
            + counted(items, "item") + " and " + counted(incomeLines, "income line") + ". "
            + "Adjust the amounts and watch the Sisa."
    }

    /// I4. Un-ticking Done deletes the Expense it created, so the confirmation names
    /// the amount and the date — unlinking without deleting was rejected, because the
    /// orphan would keep counting in its envelope and in every cycle total (§7.3).
    static func untickBody(amount: Decimal, date: Date) -> String {
        "It was recorded as an expense of \(amount.formattedIDR()) on \(date.formatted(.dateTime.day().month(.wide))). Un-ticking removes it from the ledger."
    }

    /// I7. Deleting a plan item leaves its Expense alone (§9.4, ADR-0001 nullify), and
    /// the owner has to be told so before they tap, not after.
    static func deleteItemBody(amount: Decimal?, date: Date?) -> String {
        guard let amount, let date else {
            return "The plan item goes; nothing in your ledger changes."
        }
        return "The \(amount.formattedIDR()) expense it created on \(date.formatted(.dateTime.day().month(.wide))) stays in your ledger — only the plan item goes."
    }
}
