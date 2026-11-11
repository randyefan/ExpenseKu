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
    static func counted(_ count: Int, _ noun: PlanCount) -> String {
        AppLocalization.string(noun.resource(for: count))
    }

    /// The plan list's section header: "PLAN · 14 ITEMS", or G1's
    /// "PLAN · 16 ITEMS · NONE DONE YET" on the morning a cycle opens.
    static func sectionTitle(itemCount: Int, doneCount: Int) -> String {
        let items = AppLocalization.string(.planSection(counted(itemCount, .item)))
        guard itemCount > 0, doneCount == 0 else { return items }
        return AppLocalization.string(.noneDoneYet(items))
    }

    /// E4's line under the item name. L7 names a missing Account, because that is why
    /// this item came straight here with no ◐ in between.
    static func doneSheetSubtitle(planned: Decimal, hasAccount: Bool) -> String {
        AppLocalization.string(hasAccount
               ? .planDoneSubtitle(planned.formattedIDR())
               : .planDoneSubtitleNoAccount(planned.formattedIDR()))
    }

    /// L6's header while the plan is filtered to Funded items: "PLAN · 3 OF 14 ITEMS".
    static func filteredSectionTitle(shown: Int, of total: Int) -> String {
        AppLocalization.string(.planFilteredSection(shown, counted(total, .item)))
    }

    /// "2 items", "1 envelope", "1 item, 1 envelope" (bank-logos.md §5.6.5). A set-aside
    /// line is an item.
    static func itemCount(items: Int, envelopes: Int) -> String {
        switch (items, envelopes) {
        case (_, 0): counted(items, .item)
        case (0, _): counted(envelopes, .envelope)
        default: counted(items, .item) + ", " + counted(envelopes, .envelope)
        }
    }

    static func itemCount(_ planItems: [PlanItem]) -> String {
        let envelopes = planItems.count(where: \.isEnvelope)
        return itemCount(items: planItems.count - envelopes, envelopes: envelopes)
    }

    /// "Due 12, 20"; past three days, "Due 1, 5, 12, …". Days arrive in cycle order.
    static func dueDays(_ days: [Int]) -> String? {
        guard !days.isEmpty else { return nil }
        let shown = days.prefix(3).map(String.init)
        return AppLocalization.string(.planDueDays((shown + (days.count > 3 ? ["…"] : [])).joined(separator: ", ")))
    }

    /// A bank header's state once nothing is left to move (bank-logos.md §5.6.2).
    static func allIn(_ account: String) -> String {
        AppLocalization.string(.allIn(account))
    }

    /// The trailing slot of a Funded row (L1): where the money is waiting.
    static func inAccount(_ account: String) -> String {
        AppLocalization.string(.inAccountCaption(account))
    }

    /// E5's notice, naming where the plan came from and how much arrived. The source
    /// is named by the month its cycle *ended* in, exactly as the cycle header names a
    /// cycle (Q4) — "Copied from September" has to mean the September the owner just
    /// paged away from, not the month its payday fell in.
    static func carriedOver(from sourceCycleStart: Date, payday: Int, items: Int,
                            incomeLines: Int, calendar: Calendar = .current) -> String {
        let source = PayCycle.containing(sourceCycleStart, payday: payday, calendar: calendar)
        return AppLocalization.string(.planCarryOver(source.title(calendar: calendar),
                                               counted(items, .item), counted(incomeLines, .incomeLine)))
    }

    /// The Plan lens with no plan (clear-plan.md §4.4): what an earlier plan offers, or
    /// what starting the first one leads to.
    static func noPlanMessage(copyFrom month: String?) -> String {
        guard let month else {
            return AppLocalization.string(.startOneForThisCycleEveryCycleAfterItCanCopy)
        }
        return AppLocalization.string(.copySPlanAndAdjustItOrStartFromNothing(month))
    }

    /// I4. Un-ticking Done deletes the Expense it created, so the confirmation names
    /// the amount and the date — unlinking without deleting was rejected, because the
    /// orphan would keep counting in its envelope and in every cycle total (§7.3).
    static func untickBody(amount: Decimal, date: Date) -> String {
        AppLocalization.string(.itWasRecordedAsAnExpenseOfOnUnTickingRemoves(amount.formattedIDR(), date.formatted(.dateTime.day().month(.wide).locale(AppLocalization.locale))))
    }

    /// I7. Deleting a plan item leaves its Expense alone (§9.4, ADR-0001 nullify), and
    /// the owner has to be told so before they tap, not after. An envelope's assigned
    /// expenses survive the same way (envelope-assignment.md §4.7).
    static func deleteItemBody(amount: Decimal?, date: Date?, assignedCount: Int = 0,
                               setAsideCount: Int = 0, setAsideMonths: [String] = []) -> String {
        let setAside = setAsideSentence(count: setAsideCount, months: setAsideMonths)
        if assignedCount > 0 {
            let assigned = AppLocalization.string(.planAssignedExpensesKept(assignedCount))
            return [assigned, setAside].compactMap(\.self).joined(separator: " ")
        }
        if let setAside { return setAside }
        guard let amount, let date else {
            return AppLocalization.string(.thePlanItemGoesNothingInYourLedgerChanges)
        }
        return AppLocalization.string(.theExpenseItCreatedOnStaysInYourLedgerOnlyThe(amount.formattedIDR(), date.formatted(.dateTime.day().month(.wide).locale(AppLocalization.locale))))
    }

    /// "2 set-asides in October and November will lose their envelope." (set-aside.md §4.9)
    static func setAsideSentence(count: Int, months: [String]) -> String? {
        guard count > 0 else { return nil }
        let place = months.isEmpty ? "" : AppLocalization.string(.planSetAsideMonths(listed(months)))
        return AppLocalization.string(.planSetAsidesLoseEnvelope(count, place))
    }

    /// "October", "October and November", "October, November and December" — joined by
    /// hand, as `EnvelopeDetail.emptyMessage` does, so the region cannot add a comma.
    private static func listed(_ names: [String]) -> String {
        guard let last = names.last else { return "" }
        return names.count == 1 ? last
            : AppLocalization.string(.listFinalNoComma(names.dropLast().joined(separator: ", "), last))
    }
}
