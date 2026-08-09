//
//  ManageAccountsView.swift
//  ExpenseKu
//
//  CRUD for accounts (payment sources). Add/rename route through the de-dup
//  editor (ADR-0002); delete relies on the .nullify rule so referencing expenses
//  become "Unassigned" rather than being destroyed (ADR-0001). Mirrors
//  ManageCategoriesView.
//

import SwiftUI
import SwiftData

struct ManageAccountsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.name) private var accounts: [Account]
    @State private var editor: EditorTarget?

    var body: some View {
        List {
            ForEach(accounts) { account in
                Button(account.name) { editor = EditorTarget(account: account) }
                    .foregroundStyle(.primary)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editor = EditorTarget(account: nil) } label: {
                    Label("Add Account", systemImage: "plus")
                }
            }
        }
        .overlay {
            if accounts.isEmpty {
                ContentUnavailableView("No Accounts", systemImage: "creditcard",
                    description: Text("Add one with the + button."))
            }
        }
        .sheet(item: $editor) { target in
            NavigationStack {
                NameEditorView<Account>(
                    title: target.account == nil ? "New Account" : "Edit Account",
                    editing: target.account,
                    makeNew: { Account() }
                )
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(accounts[index]) }
    }

    struct EditorTarget: Identifiable {
        let id = UUID()
        let account: Account?
    }
}
