//
//  TransferRecordButton.swift
//  ExpenseKu
//
//  "Moved to BCA": records the chosen items as Funded and closes the sheet
//  (partial-transfer.md §6.3). Drawn as the editors' save pill, disabled with nothing
//  chosen.
//

import SwiftUI

struct TransferRecordButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.dsHeadline).bold()
                .foregroundStyle(isEnabled ? Theme.onAccent : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background {
                    Capsule()
                        .fill(isEnabled ? Theme.accent : Theme.surface)
                }
        }
        .buttonStyle(.pressableCard)
        .disabled(!isEnabled)
    }
}
