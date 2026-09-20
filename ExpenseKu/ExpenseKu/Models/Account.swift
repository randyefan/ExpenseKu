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

    // Plan items paid from this account, and the transfer lines that sum them.
    // Neither is read from this side; both exist because CloudKit requires every
    // relationship to carry a declared inverse.
    @Relationship(deleteRule: .nullify, inverse: \PlanItem.account)
    var planItems: [PlanItem]? = []

    @Relationship(deleteRule: .nullify, inverse: \TransferLine.account)
    var transferLines: [TransferLine]? = []

    init(name: String = "", colorHex: String? = nil, iconName: String? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
    }

    /// The default glyph for an account with no explicit icon.
    nonisolated static let defaultSymbol = "creditcard.fill"

    /// The SF Symbol to render: the owner's pick, else the default card glyph.
    var resolvedSymbol: String { iconName ?? Account.defaultSymbol }
}
