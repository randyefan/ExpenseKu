//
//  DoneCheck.swift
//  ExpenseKu
//
//  The control that leads every plan row. It sits where an ExpenseRow's category icon
//  would, deliberately: a plan is a checklist and must not read as the ledger
//  (PRD §6.2). Conflating the two is this feature's cardinal sin (ADR-0005).
//
//  Five faces, one at a time — see DoneCheckState. Two of them are inert: an envelope
//  has no transaction to complete, and an Auto item that has not fired yet has nothing
//  to confirm.
//

import SwiftUI

struct DoneCheck: View {
    let state: DoneCheckState
    let itemName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .contentShape(.circle)
        }
        .buttonStyle(.pressableCard)
        .disabled(!state.isActionable)
        .accessibilityLabel(itemName)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isTicked ? [.isButton, .isSelected] : .isButton)
    }

    private var symbol: String {
        switch state {
        case .todo: "circle"
        case .done: "checkmark.circle.fill"
        case .auto: "bolt.circle"
        case .autoPosted: "bolt.circle.fill"
        case .envelope: "tray.fill"
        }
    }

    private var tint: Color {
        switch state {
        case .todo: Theme.textSecondary.opacity(0.6)
        case .done, .auto, .autoPosted: Theme.accent
        case .envelope: Theme.textSecondary.opacity(0.7)
        }
    }

    private var isTicked: Bool {
        state == .done || state == .autoPosted
    }

    /// Spoken by VoiceOver and read by `idb ui describe-all`, which is how the flows
    /// get verified — a control with no value is invisible to both.
    private var accessibilityValue: String {
        switch state {
        case .todo: "Not done"
        case .done: "Done"
        case .auto: "Auto — posts on its due day"
        case .autoPosted: "Auto — posted, needs review"
        case .envelope: "Envelope — fills from your expenses"
        }
    }
}
