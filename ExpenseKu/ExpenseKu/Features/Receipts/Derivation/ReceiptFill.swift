//
//  ReceiptFill.swift
//  ExpenseKu
//
//  What a reading changes on the expense form (docs/prd/receipt-reading.md §4.4): only
//  fields still empty or at their default, never one the owner typed or chose. Generic
//  over the identifier so the rules are tested with plain strings; the editor feeds it
//  persistent identifiers.
//

import Foundation

nonisolated struct ReceiptFill<ID: Hashable> {
    struct Form {
        var amountIsEmpty: Bool
        var dateIsUntouched: Bool
        var accountIsDefault: Bool
        var note: String
        var noteIsUntouched = true
        var hasCategory: Bool
        var people: [ID]
        var clock: Date
    }

    struct AccountOption {
        let id: ID
        let brandID: String?
        let uses: Int
    }

    struct NamedOption {
        let id: ID
        let name: String
    }

    enum AccountChange: Equatable {
        case keep
        case set(ID?)
    }

    var expression: String?
    var date: Date?
    var account: AccountChange = .keep
    var note: String?
    var addedPerson: ID?
    var category: ID?

    var fillsAnything: Bool {
        expression != nil || date != nil || account != .keep || note != nil
            || addedPerson != nil || category != nil
    }

    init(reading: ReceiptReading, form: Form, accounts: [AccountOption], people: [NamedOption],
         categories: [NamedOption], calendar: Calendar) {
        if form.amountIsEmpty, let amount = reading.amount {
            expression = Self.expression(amount: amount, fee: reading.fee)
        }
        if form.dateIsUntouched, let date = reading.date?.date(keepingClockOf: form.clock, calendar: calendar) {
            self.date = date
        }
        if form.accountIsDefault, let brandID = reading.bankBrandID {
            let wearing = accounts.filter { $0.brandID == brandID }
            account = .set(wearing.max { $0.uses < $1.uses }?.id)
        }
        if form.noteIsUntouched, form.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            note = reading.expenseDescription ?? reading.counterparty
        }
        if let counterparty = reading.counterparty, let person = Self.person(named: counterparty, in: people),
           !form.people.contains(person) {
            addedPerson = person
        }
        if !form.hasCategory, let name = reading.categoryName {
            category = categories.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }?.id
        }
    }

    static func expression(amount: Decimal, fee: Decimal?) -> String {
        let whole = NSDecimalNumber(decimal: amount).stringValue
        guard let fee, fee > 0 else { return whole }
        return whole + String(CalcOperator.add.rawValue) + NSDecimalNumber(decimal: fee).stringValue
    }

    /// The one Person whose name is the counterparty, or its leading words, ignoring case.
    static func person(named counterparty: String, in people: [NamedOption]) -> ID? {
        let words = Self.words(counterparty)
        let matches = people.filter { person in
            let name = Self.words(person.name)
            return !name.isEmpty && name.count <= words.count && Array(words.prefix(name.count)) == name
        }
        return matches.count == 1 ? matches.first?.id : nil
    }

    private static func words(_ text: String) -> [String] {
        text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }
}
