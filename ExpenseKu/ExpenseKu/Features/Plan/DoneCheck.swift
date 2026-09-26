//
//  DoneCheck.swift
//  ExpenseKu
//
//  The control that leads every plan row. It sits where an ExpenseRow's category icon
//  would, deliberately: a plan is a checklist and must not read as the ledger
//  (PRD §6.2). Conflating the two is this feature's cardinal sin (ADR-0005).
//
//  One face at a time — see DoneCheckState — and one behaviour, from DoneCheckTap:
//  a Button when tapping opens a sheet, a Menu when it changes Funded (§7.6), inert
//  when there is nothing to do. The Menu keeps its order fixed: iOS otherwise reverses
//  a menu that opens upward, and L2 draws "Moved to …" above "Paid…" either way.
//

import SwiftUI

struct DoneCheck: View {
    let state: DoneCheckState
    let tap: DoneCheckTap
    let itemName: String
    var accountName: String?
    let onTap: () -> Void
    let onChoose: (FundMenuEntry) -> Void

    var body: some View {
        control
            .accessibilityLabel(itemName)
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(isTicked ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var control: some View {
        switch tap {
        case .menu(let entries):
            Menu {
                ForEach(entries, id: \.self) { entry in
                    Button { onChoose(entry) } label: {
                        Text(entry.title)
                        Text(entry.subtitle)
                        Image(systemName: entry.systemImage)
                    }
                }
            } label: {
                face
            }
            .menuOrder(.fixed)
            .buttonStyle(.pressableCard)
        case .confirmDone, .untick:
            Button(action: onTap) { face }
                .buttonStyle(.pressableCard)
        case .none:
            Button(action: {}) { face }
                .buttonStyle(.pressableCard)
                .disabled(true)
        }
    }

    private var face: some View {
        DoneCheckFace(state: state)
            .frame(width: 30, height: 30)
            .contentShape(.circle)
    }

    private var isTicked: Bool {
        state == .done || state == .autoPosted
    }

    /// Spoken by VoiceOver and read by `idb ui describe-all`, which is how the flows
    /// get verified — a control with no value is invisible to both.
    private var accessibilityValue: String {
        let account = accountName ?? "the account"
        return switch state {
        case .todo: "Not done"
        case .funded: "In \(account), not paid yet"
        case .done: "Done"
        case .auto: "Auto — posts on its due day"
        case .autoFunded: "Auto — covered in \(account)"
        case .autoPosted: "Auto — posted, needs review"
        case .envelope: "Envelope — fills from your expenses"
        case .envelopeFunded: "Envelope — moved to \(account)"
        }
    }
}
