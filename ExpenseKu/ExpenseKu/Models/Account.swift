//
//  Account.swift
//  ExpenseKu
//
//  A reusable, owner-defined payment source an Expense was paid from — Cash, a
//  bank, an e-wallet. A label only: no balance, income, or transfers. Optional on
//  an Expense ("Unassigned" when absent). Mirrors Category/Person. See CONTEXT.md.
//

import Foundation
import SwiftData

@Model
final class Account {
    var name: String = ""
    /// Owner-chosen swatch (an "RRGGBB" hex from `AppearancePalette`). `nil` means
    /// "auto" — the tint is derived from the name.
    var colorHex: String?
    /// Owner-chosen SF Symbol name. `nil` means "auto" — the default card glyph.
    var iconName: String?

    // Deleting an Account nullifies each referencing expense's `account`
    // (rendered as "Unassigned") — never cascade-delete the expenses. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Expense.account)
    var expenses: [Expense]? = []

    init(name: String = "", colorHex: String? = nil, iconName: String? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
    }

    /// The default glyph for an account with no explicit icon.
    static let defaultSymbol = "creditcard.fill"

    /// The SF Symbol to render: the owner's pick, else the default card glyph.
    var resolvedSymbol: String { iconName ?? Account.defaultSymbol }
}
