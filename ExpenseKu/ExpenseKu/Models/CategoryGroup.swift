//
//  CategoryGroup.swift
//  ExpenseKu
//
//  The domain calls this a **Group** (CONTEXT.md): a coarse, owner-defined bucket
//  above Category, naming *what the money is for* rather than what was bought —
//  "Fixed Obligations", "Lovely Support", "Housing & Living". Every string the owner
//  reads says "group"; only the type is named CategoryGroup, because a type called
//  `Group` in this module would shadow `SwiftUI.Group` for the whole app and break
//  every `Group { }` view builder written after it.
//
//  Category and Group are different axes, not two sizes of the same one — "Lovely
//  Support" is a purpose, not a kind of purchase. A Group is never chosen when
//  logging an expense; it is inherited from the Category, and its only reader is the
//  plan's percentage table (PRD §5.3).
//
//  User data, not a fixed enum (PRD §9.10): the six spreadsheet buckets are seed
//  values. So it gets the same Manage section, rename, delete and duplicate-name
//  handling as Category, Person and Account — which conforming to NamedEntity and
//  AppearanceEntity buys outright.
//

import Foundation
import SwiftData

@Model
final class CategoryGroup {
    var name: String = ""
    /// Owner-chosen swatch (an "RRGGBB" hex from `AppearancePalette`). `nil` means
    /// "auto" — the tint is derived from the name.
    var colorHex: String?
    /// Owner-chosen SF Symbol. `nil` means "auto".
    var iconName: String?

    // Deleting a Group leaves its categories intact and simply ungrouped, which drops
    // them out of the percentage table. Never cascade to Category. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Category.group)
    var categories: [Category]? = []

    init(name: String = "", colorHex: String? = nil, iconName: String? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
    }

    nonisolated static let defaultSymbol = "tray.full.fill"

    var resolvedSymbol: String { iconName ?? CategoryGroup.defaultSymbol }
}
