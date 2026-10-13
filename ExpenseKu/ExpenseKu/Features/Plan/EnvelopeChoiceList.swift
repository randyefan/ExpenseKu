//
//  EnvelopeChoiceList.swift
//  ExpenseKu
//
//  The choices the editor's picker and the bulk move share (envelope-assignment.md
//  §4.4, §4.6, §4.10.2): By category, No envelope, then every active envelope of the
//  cycle's plan under ENVELOPES, then each later cycle's under "‹title› · Paid early",
//  each with its saved remainder.
//

import SwiftUI
import SwiftData

struct EnvelopeChoiceList: View {
    let options: EnvelopeOptions
    /// Nil in the bulk move, where the selection may be mixed and nothing is ticked.
    let chosen: EnvelopeChoice?
    let byCategoryDetail: String
    let onPick: (EnvelopeChoice) -> Void

    var body: some View {
        List {
            Section {
                EnvelopeChoiceRow(title: "By category", detail: byCategoryDetail,
                                  symbol: "tag", tint: Theme.textSecondary,
                                  isChosen: chosen == .byCategory) { onPick(.byCategory) }
                EnvelopeChoiceRow(title: "No envelope", detail: EnvelopeOptions.noEnvelopeDetail,
                                  symbol: "nosign", tint: Theme.textSecondary,
                                  isChosen: chosen == .noEnvelope) { onPick(.noEnvelope) }
            }

            ForEach(options.sections) { section in
                Section {
                    ForEach(section.envelopes) { envelope in
                        let choice = EnvelopeChoice.envelope(envelope.persistentModelID)
                        let progress = options.progress(of: envelope)
                        EnvelopeChoiceRow(title: envelope.name.isEmpty ? "Untitled" : envelope.name,
                                          detail: progress?.remainderText ?? "",
                                          detailIsOver: progress?.isOver ?? false,
                                          symbol: "tray", tint: Theme.plan,
                                          isChosen: chosen == choice) { onPick(choice) }
                    }
                } header: {
                    SectionHeaderText(section.isPaidEarly
                                      ? "\(section.cycle.title()) · Paid early"
                                      : "Envelopes")
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }
}
