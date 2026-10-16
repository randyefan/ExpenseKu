//
//  SetAsidePicker.swift
//  ExpenseKu
//
//  The For picker of a set-aside line (docs/prd/set-aside.md §4.2, frame W4): one
//  section per later cycle, each envelope with its planned amount — what the line is
//  helping to fund, not what is left of it.
//

import SwiftUI
import SwiftData

struct SetAsidePicker: View {
    @Binding var selection: PlanItem?
    let sections: [EnvelopeSection]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.envelopes) { envelope in
                        EnvelopeChoiceRow(title: EnvelopeDetail.displayName(of: envelope),
                                          detail: "\(envelope.amount.formattedIDR()) planned",
                                          symbol: "tray", tint: Theme.plan,
                                          isChosen: selection?.persistentModelID == envelope.persistentModelID) {
                            selection = envelope
                            dismiss()
                        }
                    }
                } header: {
                    SectionHeaderText(section.cycle.title())
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("For")
    }
}
