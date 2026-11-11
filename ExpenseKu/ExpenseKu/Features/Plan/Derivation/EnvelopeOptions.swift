//
//  EnvelopeOptions.swift
//  ExpenseKu
//
//  What the Envelope row and its picker offer for one cycle (envelope-assignment.md
//  §4.3–4.4, §4.10.2): the sections `EnvelopeOffer` chose, each envelope with its saved
//  remainder, and the words for each choice.
//
//  The remainder is the envelope's state as saved. It does not preview the expense
//  being edited, which would need the draft to count before Save. A later cycle's
//  remainder counts what was already paid early into it.
//

import Foundation
import SwiftData

nonisolated struct EnvelopeOptions {
    let offer: EnvelopeOffer
    private let claims: EnvelopeClaims
    private let progress: [PersistentIdentifier: EnvelopeProgress]

    /// `expenses` must hold every expense of the offered cycles; others are ignored.
    init(offer: EnvelopeOffer, expenses: [Expense]) {
        self.offer = offer
        claims = EnvelopeClaims(envelopes: offer.sections.first { !$0.isPaidEarly }?.envelopes ?? [],
                                cycle: offer.cycle)
        var progress: [PersistentIdentifier: EnvelopeProgress] = [:]
        for section in offer.sections {
            let cycleExpenses = expenses.filter { section.cycle.contains($0.date) }
            for item in EnvelopeSpend.progress(envelopes: section.envelopes, cycleExpenses: cycleExpenses,
                                               cycle: section.cycle) {
                progress[item.itemID] = item
            }
        }
        self.progress = progress
    }

    var sections: [EnvelopeSection] { offer.sections }
    var envelopes: [PlanItem] { offer.envelopes }
    var isEmpty: Bool { offer.isEmpty }

    func progress(of envelope: PlanItem) -> EnvelopeProgress? {
        progress[envelope.persistentModelID]
    }

    func value(for choice: EnvelopeChoice, category: Category?) -> EnvelopeRowValue {
        switch choice.kept(among: envelopes) {
        case .noEnvelope:
            return EnvelopeRowValue(name: AppLocalization.string(.noEnvelope), isChosen: true)
        case .envelope(let id):
            let name = envelopes.first { $0.persistentModelID == id }?.name ?? ""
            let suffix = offer.section(of: id)?.label.map { "· \($0.short)" }
            return EnvelopeRowValue(name: name, suffix: suffix, isChosen: true)
        case .byCategory:
            guard let claimant = claims.claimant(of: category) else {
                return EnvelopeRowValue(name: AppLocalization.string(.none), isChosen: false)
            }
            return EnvelopeRowValue(name: claimant.name, suffix: AppLocalization.string(.byCategory), isChosen: false)
        }
    }

    func byCategoryDetail(category: Category?) -> String {
        guard let category else { return AppLocalization.string(.chooseACategoryFirst) }
        guard let claimant = claims.claimant(of: category) else { return AppLocalization.string(.outsidePlan) }
        return AppLocalization.string(.countsIn(category.name, claimant.name))
    }

    static var byCategoryDetailForMany: String { AppLocalization.string(.eachKeepsWhateverItsCategorySays) }
    static var noEnvelopeDetail: String { AppLocalization.string(.outsidePlan) }
}

/// The editor row's value. A suffix — "· by category", or a paid-early "· Nov" — sits
/// apart from the name, so a long envelope name can truncate without losing it (§4.3).
nonisolated struct EnvelopeRowValue: Equatable {
    let name: String
    var suffix: String? = nil
    let isChosen: Bool
}
