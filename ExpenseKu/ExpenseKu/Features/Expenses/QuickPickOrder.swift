//
//  QuickPickOrder.swift
//  ExpenseKu
//
//  The editor's frozen one-tap orders: `QuickPicks` run over the store once, when the
//  form opens (docs/prd/quick-entry-form.md §5). Only expenses the owner logged by hand
//  count: an Auto item posting "Cicilan" every month would otherwise lead the grid.
//

import Foundation
import SwiftData

struct QuickPickOrder {
    var categories: [PersistentIdentifier] = []
    var people: [PersistentIdentifier] = []
    var accounts: [PersistentIdentifier] = []

    init() {}

    init(recent all: [Expense], categories: [Category], people: [Person], accounts: [Account], now: Date) {
        let recent = all.filter { $0.planItem == nil }
        let since = QuickPicks.windowStart(now: now, calendar: .current)
        self.categories = QuickPicks.ranked(
            categories.map { QuickPicks.Candidate(id: $0.persistentModelID, name: $0.name) },
            uses: recent.map { QuickPicks.Use(ids: $0.category.map { [$0.persistentModelID] } ?? [], date: $0.date) },
            since: since
        )
        self.people = QuickPicks.used(
            people.filter { !$0.isMe }.map { QuickPicks.Candidate(id: $0.persistentModelID, name: $0.name) },
            uses: recent.map { QuickPicks.Use(ids: ($0.people ?? []).map(\.persistentModelID), date: $0.date) },
            since: since
        )
        self.accounts = QuickPicks.ranked(
            accounts.map { QuickPicks.Candidate(id: $0.persistentModelID, name: $0.name) },
            uses: recent.map { QuickPicks.Use(ids: $0.account.map { [$0.persistentModelID] } ?? [], date: $0.date) },
            since: since
        )
    }

    static func defaultAccount(latestFirst recent: [Expense]) -> PersistentIdentifier? {
        QuickPicks.defaultAccount(latestFirst: recent.map { (account: $0.account?.persistentModelID, isFromPlan: $0.planItem != nil) })
    }
}

extension Array where Element: PersistentModel {
    /// The models in `ids`' order, skipping any no longer in the store, then the rest in
    /// their own order when `appendingRest` is set.
    func ordered(by ids: [PersistentIdentifier], appendingRest: Bool = false) -> [Element] {
        let byID = Dictionary(map { ($0.persistentModelID, $0) }, uniquingKeysWith: { first, _ in first })
        let listed = ids.compactMap { byID[$0] }
        guard appendingRest else { return listed }
        let listedIDs = Set(ids)
        return listed + filter { !listedIDs.contains($0.persistentModelID) }
    }
}
