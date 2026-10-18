//
//  LookBackWrites.swift
//  ExpenseKu
//
//  What a tap in the Look back sheet writes to the plan on screen, and how a second
//  tap takes it back (docs/prd/look-back.md §6).
//
//  A copy is carry-over's copy (PlanCarryOver), one item at a time: the plan, never its
//  progress. It is not marked carried over, so a Rp 0 copy is an ordinary row the owner
//  is about to fill in, not a dormant one. An envelope's categories already claimed here
//  stay where they are; a Category belongs to one envelope per plan, and moving it would
//  silently empty an envelope the owner already sized (§6.3).
//

import Foundation
import SwiftData

@MainActor
enum LookBackWrites {
    static func copy(_ source: PlanItem, into plan: CyclePlan, in context: ModelContext) -> LookBackMark {
        let claimed = EnvelopeSpend.claims(in: plan.items ?? [], excluding: nil)
        let item = PlanItem(
            name: source.name,
            amount: source.amount,
            kind: source.kind,
            dueDay: source.dueDay,
            isAuto: source.isAuto,
            plan: plan,
            category: source.category,
            account: source.account,
            people: source.people ?? [],
            envelopeCategories: (source.envelopeCategories ?? []).filter { claimed[$0.persistentModelID] == nil }
        )
        context.insert(item)
        try? context.save()
        return .copied(item)
    }

    static func wake(_ item: PlanItem, to amount: Decimal, in context: ModelContext) -> LookBackMark {
        item.amount = amount
        try? context.save()
        return .woken(item)
    }

    /// New envelope or New fixed item from an Outside plan Category (§6.2): named after
    /// it, sized at what the reviewed cycle spent there, no Account.
    static func newItem(_ kind: PlanItemKind, for category: Category, amount: Decimal,
                        in plan: CyclePlan, context: ModelContext) -> LookBackMark {
        let isEnvelope = kind == .envelope
        let item = PlanItem(
            name: category.name,
            amount: amount,
            kind: kind,
            plan: plan,
            category: isEnvelope ? nil : category,
            envelopeCategories: isEnvelope ? [category] : []
        )
        context.insert(item)
        try? context.save()
        return isEnvelope ? .newEnvelope(item) : .newFixed(item)
    }

    static func add(_ category: Category, to envelope: PlanItem, in context: ModelContext) -> LookBackMark {
        envelope.envelopeCategories = (envelope.envelopeCategories ?? []) + [category]
        try? context.save()
        return .addedCategory(category, to: envelope)
    }

    static func undo(_ mark: LookBackMark, in context: ModelContext) {
        switch mark {
        case .copied(let item), .newEnvelope(let item), .newFixed(let item):
            context.delete(item)
        case .woken(let item):
            item.amount = 0
        case .addedCategory(let category, let envelope):
            envelope.envelopeCategories = (envelope.envelopeCategories ?? [])
                .filter { $0.persistentModelID != category.persistentModelID }
        }
        try? context.save()
    }
}
