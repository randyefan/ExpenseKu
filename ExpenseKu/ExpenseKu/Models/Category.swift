//
//  Category.swift
//  ExpenseKu
//
//  A reusable, owner-defined label for *what kind* of spend an Expense is
//  (e.g. "Makan"). An Expense has exactly one, required at entry.
//
//  A Category also belongs to zero or one Group — a coarser axis answering what the
//  money is *for*, read only by a plan's percentage table (PRD §5.3). The Group is
//  never chosen when logging an expense; it is inherited from here.
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

    /// The coarse bucket this Category rolls up into, chosen in the Category editor.
    /// Optional everywhere; an ungrouped Category simply falls outside the plan's
    /// percentage table. Inverse lives on the Group side.
    var group: CategoryGroup?

    // Fixed plan items that name this Category. Every relationship needs a declared
    // inverse for CloudKit, even one nothing reads — a missing one fails the store at
    // launch, not at compile time (see PlanSchemaTests).
    @Relationship(deleteRule: .nullify, inverse: \PlanItem.category)
    var planItems: [PlanItem]? = []

    // The envelopes that count this Category. At most one per plan, enforced in the
    // picker (PRD §5.2) rather than by a constraint the store cannot carry (ADR-0002).
    // Deleting a Category drops it out of each envelope's set; the envelope survives.
    @Relationship(deleteRule: .nullify, inverse: \PlanItem.envelopeCategories)
    var envelopes: [PlanItem]? = []

    init(name: String = "", colorHex: String? = nil, iconName: String? = nil, group: CategoryGroup? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.group = group
    }

    /// The SF Symbol to render: the owner's pick, else inferred from the name.
    var resolvedSymbol: String { iconName ?? CategoryIcon.symbol(for: name) }
}
