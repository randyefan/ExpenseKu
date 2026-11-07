//
//  AccountMenuRow.swift
//  ExpenseKu
//
//  ACCOUNT in the expense editor (docs/prd/quick-entry-form.md §4.3): a system menu,
//  because the Account is usually already right and needs no room until it is not.
//  Menu rows carry the chip glyph rather than the logo: menus draw their images as
//  monochrome templates, which would flatten a wordmark into a grey block.
//

import SwiftUI
import SwiftData

struct AccountMenuRow: View {
    let accounts: [Account]
    @Binding var selection: Account?
    let onNewAccount: () -> Void

    private var selectedID: Binding<PersistentIdentifier?> {
        Binding(
            get: { selection?.persistentModelID },
            set: { id in selection = accounts.first { $0.persistentModelID == id } }
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("Account")
                .textCase(.uppercase)
                .font(.dsCaption).fontWeight(.semibold)
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)

            Menu {
                Picker("Account", selection: selectedID) {
                    ForEach(accounts) { account in
                        Label(account.name, systemImage: account.chipSymbol)
                            .tag(Optional(account.persistentModelID))
                    }
                    Label("None", systemImage: "nosign")
                        .tag(PersistentIdentifier?.none)
                }
                .pickerStyle(.inline)
                Divider()
                Button("New Account…", systemImage: "plus", action: onNewAccount)
            } label: {
                HStack(spacing: 8) {
                    if let selection {
                        AccountIcon(account: selection, size: 28)
                    } else {
                        CategoryIcon(name: "None", systemImage: "nosign", size: 28)
                    }
                    Text(selection?.name ?? "None")
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(selection == nil ? Theme.textSecondary : Theme.text)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.dsCaption).fontWeight(.semibold)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.leading, 4)
                .padding(.trailing, 14)
                .padding(.vertical, 4)
                .frame(minHeight: 36)
                .background {
                    Capsule().fill(Theme.card).strokeBorder(Theme.hairline, lineWidth: 1)
                }
                .contentShape(.capsule)
            }
            .accessibilityLabel("Account")
            .accessibilityValue(selection?.name ?? "None")
        }
        .padding(.leading, Metric.screenPadding + 4)
        .padding(.trailing, Metric.screenPadding)
    }
}
