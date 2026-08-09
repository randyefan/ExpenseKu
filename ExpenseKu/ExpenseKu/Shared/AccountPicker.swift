//
//  AccountPicker.swift
//  ExpenseKu
//
//  Single-select account picker for the expense editor. Pick from existing
//  accounts or create one inline through the de-dup editor. Unlike Category, an
//  account is optional, so this offers an explicit "None" (Unassigned) choice.
//  Cloned from CategoryPicker.
//

import SwiftUI
import SwiftData

struct AccountPicker: View {
    @Binding var selection: Account?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.name) private var accounts: [Account]
    @State private var showingNew = false

    var body: some View {
        List {
            Button {
                selection = nil
                dismiss()
            } label: {
                HStack {
                    Text("None")
                    Spacer()
                    if selection == nil {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
            .foregroundStyle(.primary)

            ForEach(accounts) { account in
                Button {
                    selection = account
                    dismiss()
                } label: {
                    HStack {
                        Text(account.name)
                        Spacer()
                        if isSelected(account) {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            Button {
                showingNew = true
            } label: {
                Label("New Account", systemImage: "plus")
            }
        }
        .navigationTitle("Account")
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                NameEditorView<Account>(title: "New Account", makeNew: { Account() }) { created in
                    selection = created
                }
            }
        }
    }

    private func isSelected(_ account: Account) -> Bool {
        selection?.persistentModelID == account.persistentModelID
    }
}
