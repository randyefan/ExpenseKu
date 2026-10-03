//
//  SpendBreakdownRow.swift
//  ExpenseKu
//
//  One row of a drill-in's cross-dimension card: a category's accounts, or an
//  account's categories. Either side of SpendSummary's grouping, in one shape.
//

import Foundation

nonisolated struct SpendBreakdownRow: Identifiable {
    let subject: SpendSubject
    let name: String
    let total: Decimal
    var colorHex: String?
    var symbol: String?

    var id: SpendSubject { subject }

    var resolvedSymbol: String {
        symbol ?? (subject.isCategory ? CategoryIcon.symbol(for: name) : Account.defaultSymbol)
    }

    init(_ spend: CategorySpend) {
        subject = spend.subject
        name = spend.categoryName
        total = spend.total
        colorHex = spend.colorHex
        symbol = spend.symbol
    }

    init(_ spend: AccountSpend) {
        subject = spend.subject
        name = spend.accountName
        total = spend.total
        colorHex = spend.colorHex
        symbol = spend.symbol
    }
}
