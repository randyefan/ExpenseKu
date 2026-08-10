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
            Section {
                Button {
                    selection = nil
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        CategoryIcon(name: "None", systemImage: "nosign", size: 36)
                        Text("None")
                            .font(.dsBody)
                            .foregroundStyle(Theme.text)
                        Spacer()
                        if selection == nil {
                            Image(systemName: "checkmark")
                                .font(.dsBody.weight(.bold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .listRowBackground(Theme.card)

                ForEach(accounts) { account in
                    Button {
                        selection = account
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            CategoryIcon(account: account, size: 36)
                            Text(account.name)
                                .font(.dsBody)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            if isSelected(account) {
                                Image(systemName: "checkmark")
                                    .font(.dsBody.weight(.bold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                    .listRowBackground(Theme.card)
                }
            }
            Section {
                Button { showingNew = true } label: {
                    PickerAddRow(title: "New Account")
                }
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Account")
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                AppearanceEntityEditor<Account>(title: "New Account", makeNew: { Account() }) { created in
                    selection = created
                }
            }
        }
    }

    private func isSelected(_ account: Account) -> Bool {
        selection?.persistentModelID == account.persistentModelID
    }
}
