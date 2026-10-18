//
//  LookBack.swift
//  ExpenseKu
//
//  What an earlier cycle had that the plan on screen does not (docs/prd/look-back.md).
//
//  Carry-over copies the previous plan once, the moment the new one is opened. Anything
//  that happens to the earlier plan afterwards — an item added in mid-October, after
//  November was already copied — and anything the owner spent outside it never reaches
//  the new plan. This is the one place both become visible again.
//
//  "Already here" is the same normalised name *and* the same kind, in any state:
//  "Hiburan" as a Fixed item is not the "Hiburan" envelope (§5.1, decision 3). A match
//  that is dormant here is still listed, with Wake, because a dormant row is exactly the
//  one the earlier cycle may have gone on to use.
//
//  Outside plan is judged by the reviewed cycle's *own* plan, through the same
//  EnvelopeClaims the List lens split reads, so the two can never disagree about what
//  was unplanned. Paid early is left out — that money is already in a later envelope —
//  and its total is reported so the section still reconciles with the List lens (§5.2).
//

import Foundation
import SwiftData

nonisolated struct LookBack {
    let reviewed: PayCycle
    let hadPlan: Bool
    let planRows: [LookBackPlanRow]
    let categoryRows: [LookBackCategoryRow]
    let outsideTotal: Decimal
    let paidEarlyTotal: Decimal

    var isEmpty: Bool { planRows.isEmpty && categoryRows.isEmpty }

    init(reviewed: PayCycle, reviewedPlan: CyclePlan?, reviewedExpenses: [Expense],
         claims: EnvelopeClaims, here: CyclePlan, calendar: Calendar) {
        self.reviewed = reviewed
        hadPlan = reviewedPlan != nil
        let month = LookBackCopy.month(of: reviewed, calendar: calendar)
        let hereItems = (here.items ?? []).filter { !$0.isSetAside }
        let claimedHere = EnvelopeSpend.claims(in: hereItems, excluding: nil)

        planRows = Self.planRows(sources: reviewedPlan?.items ?? [], here: hereItems,
                                 claimedHere: claimedHere, month: month)

        var outside: [Expense] = []
        var paidEarly: Decimal = 0
        for expense in reviewedExpenses where expense.planItem == nil && claims.envelope(for: expense) == nil {
            if claims.paidEarlyTarget(of: expense) != nil {
                paidEarly += expense.amount
            } else {
                outside.append(expense)
            }
        }
        paidEarlyTotal = paidEarly
        outsideTotal = outside.reduce(0) { $0 + $1.amount }
        categoryRows = Self.categoryRows(outside, here: hereItems, claimedHere: claimedHere)
    }

    /// The reviewed cycle's plan and its Outside plan spending, read from everything the
    /// Expenses tab already holds.
    static func of(_ reviewed: PayCycle, here: CyclePlan, plans: [CyclePlan], expenses: [Expense],
                   payday: Int, calendar: Calendar) -> LookBack {
        let origins = PlanOrigins(plans: plans, payday: payday, calendar: calendar)
        return LookBack(
            reviewed: reviewed,
            reviewedPlan: PlanLookup.plan(for: reviewed, in: plans),
            reviewedExpenses: expenses.filter { reviewed.contains($0.date) },
            claims: origins.claims(for: reviewed),
            here: here,
            calendar: calendar
        )
    }

    /// `›` stops at the cycle just before the one on screen (§7).
    static func canGoForward(from reviewed: PayCycle, onScreen: PayCycle) -> Bool {
        reviewed.end < onScreen.start
    }

    // MARK: - Plan items

    private struct Key: Hashable {
        let name: String
        let kind: PlanItemKind

        init(_ item: PlanItem) {
            name = NameKey.normalized(item.name)
            kind = item.kind
        }
    }

    private static func planRows(sources: [PlanItem], here: [PlanItem],
                                 claimedHere: [PersistentIdentifier: String], month: String) -> [LookBackPlanRow] {
        var hereByKey: [Key: PlanItem] = [:]
        for item in PlanDormancy.sorted(here) where hereByKey[Key(item)] == nil {
            hereByKey[Key(item)] = item
        }

        var used: [LookBackPlanRow] = []
        var unused: [LookBackPlanRow] = []
        for source in PlanDormancy.sorted(sources.filter { !$0.isSetAside }) {
            let isUnused = source.amount == 0 && !source.isDone
            let amountLine = LookBackCopy.amountLine(source.amount, isEnvelope: source.isEnvelope,
                                                     isUnused: isUnused, month: month)
            guard let match = hereByKey[Key(source)] else {
                let row = LookBackPlanRow(source: source, action: .add, isUnused: isUnused, amountLine: amountLine,
                                          caption: caption(of: source, claimedHere: claimedHere, month: month))
                if isUnused { unused.append(row) } else { used.append(row) }
                continue
            }
            // Waking gives the row this amount; at Rp 0 it would stay dormant and say nothing.
            guard !isUnused, source.amount > 0, PlanDormancy.isDormant(match) else { continue }
            used.append(LookBackPlanRow(source: source, action: .wake(match), isUnused: false,
                                        amountLine: amountLine, caption: LookBackCopy.dormantHere))
        }
        unused.sort { ($0.source.name, $0.source.createdAt) < ($1.source.name, $1.source.createdAt) }
        return used + unused
    }

    private static func caption(of source: PlanItem, claimedHere: [PersistentIdentifier: String],
                                month: String) -> String? {
        if source.isEnvelope {
            return LookBackCopy.staysIn(skipped(source, claimedHere: claimedHere))
        }
        guard let paid = source.linkedExpense?.amount, paid != source.amount else { return nil }
        return LookBackCopy.paid(paid, month: month)
    }

    /// The envelope's categories already claimed here, grouped by the envelope holding
    /// each, in the order those envelopes are first met (§6.3).
    static func skipped(_ envelope: PlanItem,
                        claimedHere: [PersistentIdentifier: String]) -> [(envelope: String, categories: [String])] {
        var groups: [(envelope: String, categories: [String])] = []
        let categories = (envelope.envelopeCategories ?? []).sorted { $0.name < $1.name }
        for category in categories {
            guard let holder = claimedHere[category.persistentModelID] else { continue }
            if let index = groups.firstIndex(where: { $0.envelope == holder }) {
                groups[index].categories.append(category.name)
            } else {
                groups.append((holder, [category.name]))
            }
        }
        return groups
    }

    // MARK: - Outside plan

    private static func categoryRows(_ outside: [Expense], here: [PlanItem],
                                     claimedHere: [PersistentIdentifier: String]) -> [LookBackCategoryRow] {
        let byCategory = Dictionary(grouping: outside) { $0.category?.persistentModelID }
        let fixedHere = PlanDormancy.sorted(here.filter { $0.kind == .fixed })
        let rows = byCategory.values.map { expenses -> LookBackCategoryRow in
            let category = expenses[0].category
            let status: LookBackCategoryRow.Status
            if let category {
                if let envelope = claimedHere[category.persistentModelID] {
                    status = .claimed(envelope: envelope)
                } else {
                    let users = fixedHere.filter { $0.category?.persistentModelID == category.persistentModelID }
                    status = .open(fixedUse: LookBackCopy.fixedUse(users.map(\.name), category: category.name))
                }
            } else {
                status = .uncategorized
            }
            return LookBackCategoryRow(category: category, total: expenses.reduce(0) { $0 + $1.amount },
                                       count: expenses.count, status: status)
        }
        return rows.sorted { $0.total != $1.total ? $0.total > $1.total : $0.name < $1.name }
    }
}
