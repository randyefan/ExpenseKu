//
//  FilterChoice.swift
//  ExpenseKu
//
//  One tickable value in a filter dimension: an entity by identifier, or the dimension's
//  empty value (Uncategorized, No group, Unassigned, No one).
//

import SwiftData

nonisolated enum FilterChoice: Hashable {
    case entity(PersistentIdentifier)
    case none
}
