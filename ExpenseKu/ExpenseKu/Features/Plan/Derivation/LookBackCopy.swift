//
//  LookBackCopy.swift
//  ExpenseKu
//
//  The Look back sheet's strings (look-back.md §4–§6). A cycle is named by the month
//  it ends in, as the cycle header names it, so "October" here is the October the
//  owner pages to with ‹.
//

import Foundation

nonisolated enum LookBackCopy {
    static let uncategorized = "Uncategorized"
    static let categoriseFirst = "categorise them first"
    static let dormantHere = "dormant here"
    static let emptyTitle = "Nothing to bring over"
    static let addToEnvelope = "Add to an envelope"

    static func month(of cycle: PayCycle, calendar: Calendar) -> String {
        cycle.lastDay(calendar: calendar).formatted(.dateTime.month(.wide))
    }

    /// The sheet's title: the month alone, with its year once it is not the year of the
    /// plan on screen, so paging back past January never reads as the coming one.
    static func title(of reviewed: PayCycle, onScreen: PayCycle, calendar: Calendar) -> String {
        let last = reviewed.lastDay(calendar: calendar)
        let sameYear = calendar.component(.year, from: last)
            == calendar.component(.year, from: onScreen.lastDay(calendar: calendar))
        return last.formatted(sameYear ? .dateTime.month(.wide) : .dateTime.month(.wide).year())
    }

    static func entryTitle(_ month: String) -> String { "Look back at \(month)" }
    static func lead(planMonth: String) -> String { "What \(planMonth)'s plan doesn't have" }
    static func planSection(_ month: String) -> String { "In \(month)'s plan, not here" }
    static func noPlan(_ month: String) -> String { "\(month) had no plan." }

    static func outsideSection(_ month: String, total: Decimal) -> String {
        "Outside plan in \(month) · \(total.formattedIDR())"
    }

    static func paidEarlyExcluded(_ amount: Decimal) -> String {
        "excluding \(amount.formattedIDR()) paid early"
    }

    static func emptyMessage(_ month: String, planMonth: String) -> String {
        "Nothing in \(month) that \(planMonth)'s plan doesn't have."
    }

    /// "Rp 400.000 · envelope"; a row the reviewed cycle never used, "Rp 0 in October".
    static func amountLine(_ amount: Decimal, isEnvelope: Bool, isUnused: Bool, month: String) -> String {
        if isUnused { return "\(amount.formattedIDR()) in \(month)" }
        return amount.formattedIDR() + (isEnvelope ? " · envelope" : "")
    }

    static func spendLine(_ total: Decimal, count: Int) -> String {
        "\(total.formattedIDR()) · " + PlanCopy.counted(count, "expense")
    }

    static func paid(_ amount: Decimal, month: String) -> String {
        "paid \(amount.formattedIDR()) in \(month)"
    }

    static func claimedHere(_ envelope: String) -> String { "in \(envelope) here" }

    /// "Makan stays in Hidup", "Makan, Kopi stay in Hidup", "Makan stays in Hidup · Kopi in Jajan".
    /// Groups arrive as (envelope, category names), in the order they are read.
    static func staysIn(_ groups: [(envelope: String, categories: [String])]) -> String? {
        guard !groups.isEmpty else { return nil }
        let first = groups[0]
        let verb = first.categories.count == 1 ? "stays" : "stay"
        let lead = "\(first.categories.joined(separator: ", ")) \(verb) in \(first.envelope)"
        let rest = groups.dropFirst().map { "\($0.categories.joined(separator: ", ")) in \($0.envelope)" }
        return ([lead] + rest).joined(separator: " · ")
    }

    /// "Kos uses Sewa here"; "Netflix and 2 more use Hiburan here".
    static func fixedUse(_ names: [String], category: String) -> String? {
        guard let first = names.first else { return nil }
        if names.count == 1 { return "\(first) uses \(category) here" }
        return "\(first) and \(names.count - 1) more use \(category) here"
    }

    static func menuTitle(_ category: String, total: Decimal, month: String) -> String {
        "\(category) · \(total.formattedIDR()) in \(month)"
    }
}
