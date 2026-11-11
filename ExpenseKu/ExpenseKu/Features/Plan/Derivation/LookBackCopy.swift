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
    static var uncategorized: String { AppLocalization.string(.uncategorized) }
    static var categoriseFirst: String { AppLocalization.string(.categoriseThemFirst) }
    static var dormantHere: String { AppLocalization.string(.dormantHere) }
    static var emptyTitle: String { AppLocalization.string(.nothingToBringOver) }
    static var addToEnvelope: String { AppLocalization.string(.addToAnEnvelope) }

    static func month(of cycle: PayCycle, calendar: Calendar) -> String {
        cycle.lastDay(calendar: calendar).formatted(.dateTime.month(.wide).locale(AppLocalization.locale))
    }

    /// The sheet's title: the month alone, with its year once it is not the year of the
    /// plan on screen, so paging back past January never reads as the coming one.
    static func title(of reviewed: PayCycle, onScreen: PayCycle, calendar: Calendar) -> String {
        let last = reviewed.lastDay(calendar: calendar)
        let sameYear = calendar.component(.year, from: last)
            == calendar.component(.year, from: onScreen.lastDay(calendar: calendar))
        let format = sameYear ? Date.FormatStyle.dateTime.month(.wide) : .dateTime.month(.wide).year()
        return last.formatted(format.locale(AppLocalization.locale))
    }

    static func entryTitle(_ month: String) -> String { AppLocalization.string(.lookBackAt(month)) }
    static func lead(planMonth: String) -> String { AppLocalization.string(.whatSPlanDoesnTHave(planMonth)) }
    static func planSection(_ month: String) -> String { AppLocalization.string(.inSPlanNotHere(month)) }
    static func noPlan(_ month: String) -> String { AppLocalization.string(.hadNoPlan(month)) }

    static func outsideSection(_ month: String, total: Decimal) -> String {
        AppLocalization.string(.outsidePlanIn(month, total.formattedIDR()))
    }

    static func paidEarlyExcluded(_ amount: Decimal) -> String {
        AppLocalization.string(.excludingPaidEarly(amount.formattedIDR()))
    }

    static func emptyMessage(_ month: String, planMonth: String) -> String {
        AppLocalization.string(.nothingInThatSPlanDoesnTHave(month, planMonth))
    }

    /// "Rp 400.000 · envelope"; a row the reviewed cycle never used, "Rp 0 in October".
    static func amountLine(_ amount: Decimal, isEnvelope: Bool, isUnused: Bool, month: String) -> String {
        if isUnused { return AppLocalization.string(.amountInMonth(amount.formattedIDR(), month)) }
        return amount.formattedIDR() + (isEnvelope ? AppLocalization.string(.envelope) : "")
    }

    static func spendLine(_ total: Decimal, count: Int) -> String {
        "\(total.formattedIDR()) · " + PlanCopy.counted(count, .expense)
    }

    static func paid(_ amount: Decimal, month: String) -> String {
        AppLocalization.string(.paidIn(amount.formattedIDR(), month))
    }

    static func claimedHere(_ envelope: String) -> String { AppLocalization.string(.inHere(envelope)) }

    /// "Makan stays in Hidup", "Makan, Kopi stay in Hidup", "Makan stays in Hidup · Kopi in Jajan".
    /// Groups arrive as (envelope, category names), in the order they are read.
    static func staysIn(_ groups: [(envelope: String, categories: [String])]) -> String? {
        guard !groups.isEmpty else { return nil }
        let first = groups[0]
        let categories = first.categories.joined(separator: ", ")
        let lead = AppLocalization.string(first.categories.count == 1
                          ? .lookBackCategoriesStay(categories, first.envelope)
                          : .lookBackCategoriesStayPlural(categories, first.envelope))
        let rest = groups.dropFirst().map { AppLocalization.string(.amountInMonth($0.categories.joined(separator: ", "), $0.envelope)) }
        return ([lead] + rest).joined(separator: " · ")
    }

    /// "Kos uses Sewa here"; "Netflix and 2 more use Hiburan here".
    static func fixedUse(_ names: [String], category: String) -> String? {
        guard let first = names.first else { return nil }
        if names.count == 1 { return AppLocalization.string(.usesHere(first, category)) }
        return AppLocalization.string(.andMoreUseHere(first, String(names.count - 1), category))
    }

    static func menuTitle(_ category: String, total: Decimal, month: String) -> String {
        AppLocalization.string(.categoryAmountInMonth(category, total.formattedIDR(), month))
    }
}
