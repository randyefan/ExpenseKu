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
                Button { editor = EditorTarget(account: account) } label: {
                    HStack(spacing: 12) {
                        CategoryIcon(name: account.name, systemImage: "creditcard.fill", size: 36)
                        Text(account.name)
                            .font(.dsBody)
                            .foregroundStyle(Theme.text)
                        Spacer()
                    }
                }
                .listRowBackground(Theme.card)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editor = EditorTarget(account: nil) } label: {
                    Label("Add Account", systemImage: "plus")
                }
                .accentCircleButton()
            }
        }
        .overlay {
            if accounts.isEmpty {
                EmptyStateView(title: "No Accounts", systemImage: "creditcard",
                    message: "Add one with the + button.")
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
