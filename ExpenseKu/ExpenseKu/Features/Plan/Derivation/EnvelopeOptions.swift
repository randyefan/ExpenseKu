//
//  EnvelopeOptions.swift
//  ExpenseKu
//
//  What the Envelope row and its picker offer for one cycle (envelope-assignment.md
//  §4.3–4.4): the plan's active envelopes by planned amount ↓, each with its saved
//  remainder, and the words for each choice.
//
//  The remainder is the envelope's state as saved. It does not preview the expense
//  being edited, which would need the draft to count before Save.
//

import Foundation
import SwiftData

nonisolated struct EnvelopeOptions {
    let envelopes: [PlanItem]
    private let claims: EnvelopeClaims
    private let progress: [PersistentIdentifier: EnvelopeProgress]

    init(plan: CyclePlan?, cycleExpenses: [Expense]) {
        envelopes = PlanDormancy.split(plan?.items ?? []).active.filter(\.isEnvelope)
        claims = EnvelopeClaims(envelopes: envelopes)
        let all = EnvelopeSpend.progress(envelopes: envelopes, cycleExpenses: cycleExpenses)
        progress = Dictionary(uniqueKeysWithValues: all.map { ($0.itemID, $0) })
    }

    var isEmpty: Bool { envelopes.isEmpty }

    func progress(of envelope: PlanItem) -> EnvelopeProgress? {
        progress[envelope.persistentModelID]
    }

    func value(for choice: EnvelopeChoice, category: Category?) -> EnvelopeRowValue {
        switch choice.kept(among: envelopes) {
        case .noEnvelope:
            return EnvelopeRowValue(name: "No envelope", isChosen: true)
        case .envelope(let id):
            let name = envelopes.first { $0.persistentModelID == id }?.name ?? ""
            return EnvelopeRowValue(name: name, isChosen: true)
        case .byCategory:
            guard let claimant = claims.claimant(of: category) else {
                return EnvelopeRowValue(name: "None", isChosen: false)
            }
            return EnvelopeRowValue(name: claimant.name, suffix: "· by category", isChosen: false)
        }
    }

    func byCategoryDetail(category: Category?) -> String {
        guard let category else { return "Choose a category first" }
        guard let claimant = claims.claimant(of: category) else { return "Outside plan" }
        return "\(category.name) counts in \(claimant.name)"
    }

    static let byCategoryDetailForMany = "Each keeps whatever its Category says"
    static let noEnvelopeDetail = "Outside plan"
}

/// The editor row's value. A by-category value carries its suffix apart from the name,
/// so a long envelope name can truncate without losing it (§4.3).
nonisolated struct EnvelopeRowValue: Equatable {
    let name: String
    var suffix: String? = nil
    let isChosen: Bool
}
