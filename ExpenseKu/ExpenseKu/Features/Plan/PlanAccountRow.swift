//
//  PlanAccountRow.swift
//  ExpenseKu
//

import SwiftUI

/// The Account row, shared by both kinds: a Fixed item's payer, an Envelope's
/// optional home (L5).
struct PlanAccountRow: View {
    @Binding var account: Account?

    var body: some View {
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
    }
}
