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
            Text(appLocalized: .account)
                .textCase(.uppercase)
                .font(.dsCaption).fontWeight(.semibold)
                .tracking(0.5)
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)

            Menu {
                Picker(AppLocalization.string(.account), selection: selectedID) {
                    ForEach(accounts) { account in
                        Label(account.name, systemImage: account.chipSymbol)
                            .tag(Optional(account.persistentModelID))
                    }
                    Label(AppLocalization.string(.none), systemImage: "nosign")
                        .tag(PersistentIdentifier?.none)
                }
                .pickerStyle(.inline)
                Divider()
                Button(AppLocalization.string(.newAccountMenuAction), systemImage: "plus", action: onNewAccount)
            } label: {
                HStack(spacing: 8) {
                    if let selection {
                        AccountIcon(account: selection, size: 28)
                    } else {
                        CategoryIcon(name: AppLocalization.string(.none), systemImage: "nosign", size: 28)
                    }
                    Text(selection?.name ?? AppLocalization.string(.none))
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
            .accessibilityLabel(AppLocalization.string(.account))
            .accessibilityValue(selection?.name ?? AppLocalization.string(.none))
        }
        .padding(.leading, Metric.screenPadding + 4)
        .padding(.trailing, Metric.screenPadding)
    }
}
