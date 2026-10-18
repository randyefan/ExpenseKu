//
//  LookBackRowID.swift
//  ExpenseKu
//
//  One row of the Look back sheet, stable across re-derivations so an added row can
//  keep its place and its ✓ while the sheet is open (docs/prd/look-back.md §6.5).
//  A category row is keyed by its Category, so the same Category in two reviewed
//  cycles shares an id; marks are therefore kept per reviewed cycle.
//

import Foundation
import SwiftData

nonisolated enum LookBackRowID: Hashable {
    case item(PersistentIdentifier)
    case category(PersistentIdentifier?)
}
