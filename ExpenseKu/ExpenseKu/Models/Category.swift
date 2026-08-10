//
//  Category.swift
//  ExpenseKu
//
//  A reusable, owner-defined label for *what kind* of spend an Expense is
//  (e.g. "Makan"). An Expense has exactly one, required at entry.
//

import Foundation
import SwiftData

@Model
final class Category {
    var name: String = ""
    /// Owner-chosen swatch (an "RRGGBB" hex from `AppearancePalette`). `nil` means
    /// "auto" — the tint is derived from the name. See `resolvedTint`.
    var colorHex: String?
    /// Owner-chosen SF Symbol name. `nil` means "auto" — the glyph is inferred from
    /// the name (`CategoryIcon.symbol(for:)`). See `resolvedSymbol`.
    var iconName: String?

    // Deleting a Category nullifies each referencing expense's `category`
    // (rendered as "Uncategorized") — never cascade-delete the expenses. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]? = []

    init(name: String = "", colorHex: String? = nil, iconName: String? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
    }

    /// The SF Symbol to render: the owner's pick, else inferred from the name.
    var resolvedSymbol: String { iconName ?? CategoryIcon.symbol(for: name) }
}
