//
//  FilterOption.swift
//  ExpenseKu
//
//  One row of a filter checklist: the choice it toggles, the name it shows, and the
//  appearance of the entity behind it.
//

import Foundation

nonisolated struct FilterOption: Hashable, Identifiable {
    let choice: FilterChoice
    let name: String
    var symbol: String? = nil
    var colorHex: String? = nil

    var id: FilterChoice { choice }
}
