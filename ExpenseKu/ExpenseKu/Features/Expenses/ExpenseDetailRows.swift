//
//  ExpenseDetailRows.swift
//  ExpenseKu
//
//  The Date / Category / Account / People rows of the expense editor, shared by the
//  iOS and macOS layouts so the two cannot drift.
//

import SwiftUI

struct ExpenseDetailRows: View {
    @Binding var date: Date
    @Binding var category: Category?
    @Binding var account: Account?
    @Binding var people: [Person]

    private var peopleSummary: String {
        people.isEmpty ? "None" : people.map(\.name).sorted().joined(separator: ", ")
    }

    var body: some View {
        DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
            .font(.dsBody)
            .listRowBackground(Theme.card)

        NavigationLink {
            CategoryPicker(selection: $category)
        } label: {
            LabeledContent("Category") {
                Text(category?.name ?? "Required")
                    .foregroundStyle(category == nil ? Theme.accent : Theme.text)
            }
            .font(.dsBody)
        }
        .listRowBackground(Theme.card)

        NavigationLink {
            AccountPicker(selection: $account)
        } label: {
            LabeledContent("Account") {
                Text(account?.name ?? "None")
                    .foregroundStyle(account == nil ? Theme.textSecondary : Theme.text)
            }
            .font(.dsBody)
        }
        .listRowBackground(Theme.card)

        NavigationLink {
            PeoplePicker(selection: $people)
        } label: {
            LabeledContent("People") {
                Text(peopleSummary)
                    .foregroundStyle(people.isEmpty ? Theme.textSecondary : Theme.text)
                    .lineLimit(1)
            }
            .font(.dsBody)
        }
        .listRowBackground(Theme.card)
    }
}
