//
//  LookBackDisplay.swift
//  ExpenseKu
//
//  Which rows the open sheet shows (look-back.md §6.5, §8).
//
//  A tap writes to the plan at once, and the plan then has the item — so a fresh
//  derivation would drop the very row the owner just tapped, and with it the ✓ that
//  undoes it. The first derivation of each reviewed cycle is kept for the visit: a marked
//  row stays as it was, every other row follows the live derivation, so a category the
//  owner just put in Hidup elsewhere reads "in Hidup here" rather than offering + twice.
//

import Foundation

nonisolated enum LookBackDisplay {
    static func rows<Row: Identifiable>(snapshot: [Row], live: [Row], marked: Set<LookBackRowID>) -> [Row]
    where Row.ID == LookBackRowID {
        let liveByID = Dictionary(live.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let known = Set(snapshot.map(\.id))
        return snapshot.compactMap { marked.contains($0.id) ? $0 : liveByID[$0.id] }
            + live.filter { !known.contains($0.id) }
    }
}
