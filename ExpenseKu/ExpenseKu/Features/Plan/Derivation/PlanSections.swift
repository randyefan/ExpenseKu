//
//  PlanSections.swift
//  ExpenseKu
//
//  The plan's active items cut into list sections for one `PlanSort`
//  (docs/prd/plan-sort.md §4).
//
//  Amount, Due day and Name are one headerless section. Account, Group and Status are
//  one section per group, and inside a group items run by due day in cycle, because
//  on payday what matters within one bank is what leaves first.
//
//  Account and Group order by planned total, largest first, so the list reads in the
//  same order as the transfer checklist and the share table beneath it. Group goes
//  through `GroupShares.group(of:)` so an Envelope spanning two Groups sits in the same
//  one in both places.
//

import Foundation
import SwiftData

nonisolated struct PlanSection: Identifiable {
    enum Heading {
        case account(Account?)
        case group(CategoryGroup?)
        case status(PlanItemState)
    }

    let id: String
    let heading: Heading?
    let items: [PlanItem]

    var title: String? {
        guard let heading else { return nil }
        let name = switch heading {
        case .account(let account): account?.name ?? PlanSections.unassignedName
        case .group(let group): group?.name ?? GroupShares.ungroupedName
        case .status(.todo): "Todo"
        case .status(.funded): "Funded"
        case .status(.done): "Done"
        }
        return name + " · " + PlanCopy.counted(items.count, "item")
    }
}

nonisolated enum PlanSections {
    static let unassignedName = "Unassigned"

    static func sections(_ items: [PlanItem], by sort: PlanSort,
                         cycle: PayCycle, calendar: Calendar) -> [PlanSection] {
        guard !items.isEmpty else { return [] }
        let byDue = { (group: [PlanItem]) in byDueDay(group, cycle: cycle, calendar: calendar) }

        switch sort {
        case .amount:
            return [flat(PlanDormancy.sorted(items))]
        case .dueDay:
            return [flat(byDue(items))]
        case .name:
            return [flat(byName(items))]
        case .account:
            return grouped(items, key: { $0.account }, id: { "\($0.persistentModelID)" }, name: \.name)
                .map { PlanSection(id: "account-\($0.id)", heading: .account($0.key), items: byDue($0.items)) }
        case .group:
            return grouped(items, key: GroupShares.group(of:), id: \.name, name: \.name)
                .map { PlanSection(id: "group-\($0.id)", heading: .group($0.key), items: byDue($0.items)) }
        case .status:
            let states: [PlanItemState] = [.todo, .funded, .done]
            return states.compactMap { state in
                let members = items.filter { PlanItemState.of($0) == state }
                guard !members.isEmpty else { return nil }
                return PlanSection(id: "status-\(state)", heading: .status(state), items: byDue(members))
            }
        }
    }

    /// Dated items by where the day falls in the cycle, so with payday 25 a Due 28
    /// precedes a Due 1. An item with no due day, or one the cycle cannot reach, follows.
    static func byDueDay(_ items: [PlanItem], cycle: PayCycle, calendar: Calendar) -> [PlanItem] {
        let dates = items.map { item in item.dueDay.flatMap { DueDay.date(day: $0, in: cycle, calendar: calendar) } }
        return zip(items, dates)
            .sorted { a, b in
                switch (a.1, b.1) {
                case let (x?, y?) where x != y: x < y
                case (_?, nil): true
                case (nil, _?): false
                default: PlanDormancy.precedes(a.0, b.0)
                }
            }
            .map(\.0)
    }

    static func byName(_ items: [PlanItem]) -> [PlanItem] {
        items.sorted { a, b in
            switch a.name.localizedStandardCompare(b.name) {
            case .orderedAscending: true
            case .orderedDescending: false
            case .orderedSame: PlanDormancy.precedes(a, b)
            }
        }
    }

    private static func flat(_ items: [PlanItem]) -> PlanSection {
        PlanSection(id: "all", heading: nil, items: items)
    }

    private struct Bucket<Key> {
        let id: String
        let key: Key?
        let name: String
        var items: [PlanItem] = []
        var total: Decimal { items.reduce(0) { $0 + $1.amount } }
    }

    /// Buckets by `key`, largest planned total first, ties on name; the bucket with no
    /// key is the absence of an answer and always goes last.
    private static func grouped<Key>(
        _ items: [PlanItem],
        key: (PlanItem) -> Key?,
        id: (Key) -> String,
        name: (Key) -> String
    ) -> [Bucket<Key>] {
        var buckets: [String: Bucket<Key>] = [:]
        for item in items {
            let k = key(item)
            let bucketID = k.map(id) ?? "none"
            buckets[bucketID, default: Bucket(id: bucketID, key: k, name: k.map(name) ?? "")]
                .items.append(item)
        }
        return buckets.values.sorted { a, b in
            if (a.key == nil) != (b.key == nil) { return b.key == nil }
            if a.total != b.total { return a.total > b.total }
            if a.name != b.name { return a.name < b.name }
            return a.id < b.id
        }
    }
}
