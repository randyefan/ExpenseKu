//
//  QuickPicks.swift
//  ExpenseKu
//
//  Which Categories, People and Accounts the expense editor offers in one tap, and in
//  what order (docs/prd/quick-entry-form.md §4.2–§4.4). Everything is counted over the
//  last 90 days and frozen when the form opens, so nothing moves under the thumb.
//
//  Generic over the identifier so the rules are tested with plain strings; the editor
//  feeds it persistent identifiers.
//

import Foundation

nonisolated enum QuickPicks {
    static let windowDays = 90
    static let tileCount = 7
    static let railPeople = 6

    struct Candidate<ID: Hashable>: Equatable {
        let id: ID
        let name: String
    }

    struct Use<ID: Hashable> {
        let ids: [ID]
        let date: Date
    }

    static func windowStart(now: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -windowDays, to: now) ?? now
    }

    /// Most used first, then by name; unused candidates follow by name.
    static func ranked<ID: Hashable>(_ candidates: [Candidate<ID>], uses: [Use<ID>], since: Date) -> [ID] {
        var counts: [ID: Int] = [:]
        for use in uses where use.date >= since {
            for id in Set(use.ids) { counts[id, default: 0] += 1 }
        }
        return candidates
            .sorted { a, b in
                let ca = counts[a.id, default: 0]
                let cb = counts[b.id, default: 0]
                if ca != cb { return ca > cb }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
            .map(\.id)
    }

    /// Like `ranked`, but only what was used at all.
    static func used<ID: Hashable>(_ candidates: [Candidate<ID>], uses: [Use<ID>], since: Date) -> [ID] {
        let usedIDs = Set(uses.filter { $0.date >= since }.flatMap(\.ids))
        return ranked(candidates, uses: uses, since: since).filter(usedIDs.contains)
    }

    /// The grid's tiles before All…: a Category reached through All… takes the first
    /// tile and the last of the most used drops out.
    static func categoryTiles<ID: Hashable>(ranking: [ID], pulled: ID?) -> [ID] {
        guard let pulled else { return Array(ranking.prefix(tileCount)) }
        return [pulled] + ranking.filter { $0 != pulled }.prefix(tileCount - 1)
    }

    /// Me, then whoever joined through All… or was already tagged, then the most tagged.
    static func peopleRail<ID: Hashable>(me: ID?, ranking: [ID], joined: [ID]) -> [ID] {
        var rail: [ID] = me.map { [$0] } ?? []
        for id in joined where !rail.contains(id) { rail.append(id) }
        var added = 0
        for id in ranking where added < railPeople && !rail.contains(id) {
            rail.append(id)
            added += 1
        }
        return rail
    }

    /// The Account a new expense starts on: that of the latest expense the owner logged
    /// by hand. Expenses an Auto or Fixed plan item wrote are skipped, so an autodebit
    /// from the salary account does not become the default for coffee.
    static func defaultAccount<ID: Hashable>(latestFirst: [(account: ID?, isFromPlan: Bool)]) -> ID? {
        latestFirst.first { !$0.isFromPlan }?.account
    }
}
