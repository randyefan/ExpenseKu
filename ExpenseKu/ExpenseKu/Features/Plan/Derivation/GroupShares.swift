//
//  GroupShares.swift
//  ExpenseKu
//
//  The plan's allocation check: each Group's planned total as a share of Total Income
//  (PRD §6.1.5). Planned figures only — actual spend by Group is not shown here
//  (decision 16), and percentages are display-only, never stored (§9.8).
//
//  A Fixed item has one Category and therefore one Group. An **Envelope's category
//  set can span two Groups**, which §5 does not address: it says only "Σ PlanItem
//  .amount per Group". Splitting the money would invent a division the owner never
//  made, so an envelope attributes wholly to the Group most of its categories belong
//  to, ties broken on group name. Deterministic, never splits an amount, and §5.2's
//  own worked example — five rows sharing Housing & Living — satisfies it trivially.
//
//  An item whose Category has no Group, or no Category at all, falls into an
//  "Ungrouped" row, mirroring how a deleted Category renders as "Uncategorized".
//

import Foundation

nonisolated enum GroupShares {
    static let ungroupedName = "Ungrouped"

    static func rows(activeItems: [PlanItem], totalIncome: Decimal) -> [GroupShare] {
        var planned: [String: Decimal] = [:]
        var appearance: [String: (colorHex: String?, symbol: String?)] = [:]

        for item in activeItems {
            let group = self.group(of: item)
            let key = group?.name ?? ungroupedName
            planned[key, default: 0] += item.amount
            if let group, appearance[key] == nil {
                appearance[key] = (group.colorHex, group.resolvedSymbol)
            }
        }

        return planned.map { name, amount in
            GroupShare(
                groupName: name,
                colorHex: appearance[name]?.colorHex,
                symbol: appearance[name]?.symbol,
                planned: amount,
                share: totalIncome > 0 ? (amount / totalIncome).doubleValue : 0
            )
        }
        .sorted { a, b in
            // Ungrouped last whatever it holds: it is the absence of an answer, not
            // one of the six buckets.
            if (a.groupName == ungroupedName) != (b.groupName == ungroupedName) {
                return b.groupName == ungroupedName
            }
            if a.planned != b.planned { return a.planned > b.planned }
            return a.groupName < b.groupName
        }
    }

    /// The Group an item rolls up into. A Fixed item inherits its Category's; an
    /// Envelope takes the one most of its categories share — see the file header.
    static func group(of item: PlanItem) -> CategoryGroup? {
        guard item.isEnvelope else { return item.category?.group }

        var tally: [String: (group: CategoryGroup, count: Int)] = [:]
        for category in item.envelopeCategories ?? [] {
            guard let group = category.group else { continue }
            let existing = tally[group.name]
            tally[group.name] = (group, (existing?.count ?? 0) + 1)
        }
        return tally.values
            .sorted { a, b in
                if a.count != b.count { return a.count > b.count }
                return a.group.name < b.group.name
            }
            .first?.group
    }
}

nonisolated struct GroupShare: Identifiable, Equatable {
    let groupName: String
    let colorHex: String?
    let symbol: String?
    let planned: Decimal
    /// `planned ÷ totalIncome`, 0 when there is no income. Display-only.
    let share: Double

    var id: String { groupName }

    static func == (a: GroupShare, b: GroupShare) -> Bool {
        a.groupName == b.groupName && a.planned == b.planned && a.share == b.share
    }
}
