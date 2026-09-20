//
//  PlanTotals.swift
//  ExpenseKu
//
//  The five figures at the head of a plan, and the two annotations under them
//  (PRD §5, §6.1). Pure, so the arithmetic the owner reads is pinned by tests rather
//  than by looking at a screenshot.
//
//  The invariant everything else depends on: **Sisa never subtracts an expense.**
//  Total Cost sums PlanItem.amount — the *planned* figures — so Sisa is stable
//  through a cycle and moves only when the plan is edited (§9.9). Actual spending is
//  the List lens's total. Conflating the two is the feature's cardinal sin (ADR-0005),
//  and it would be a very quiet one: the number would simply drift down all month and
//  look plausible the whole way.
//
//  Because Total Cost is planned-only, real money escapes Sisa in two ways, and each
//  gets its own strip under it rather than a row inside the sum — neither redefines
//  Sisa, and either can show without the other:
//
//    Row · Drift        actuals have run past the plan
//    Row · Over income  the plan itself allocates more than the income
//
//  They are different facts, which is why they are two things and not one strip with
//  swapped copy. A third leak — an expense in no envelope and no Fixed item — is
//  counted by neither, deliberately (§11.3).
//

import Foundation

nonisolated struct PlanTotals: Equatable {
    /// Σ IncomeLine.amount.
    let totalIncome: Decimal
    /// Σ PlanItem.amount over active items, both kinds alike. Planned, never actual.
    let totalCost: Decimal
    /// Σ(actual − planned) over completed Fixed items, plus Σ envelope overspend.
    let drift: Decimal

    /// What the owner is actually looking for. Can go negative; nothing is blocked.
    var sisa: Decimal { totalIncome - totalCost }

    var showsDrift: Bool { drift > 0 }
    var showsOverIncome: Bool { sisa < 0 }

    init(activeItems: [PlanItem], incomeLines: [IncomeLine], envelopes: [EnvelopeProgress]) {
        totalIncome = incomeLines.reduce(Decimal(0)) { $0 + $1.amount }
        totalCost = activeItems.reduce(Decimal(0)) { $0 + $1.amount }

        // The Fixed term is signed on purpose: an item that came in under genuinely
        // offsets one that came in over, which is what "over plan so far" means as a
        // net figure. The envelope term is clamped at zero — see EnvelopeProgress.
        let fixedDrift = activeItems.reduce(Decimal(0)) { running, item in
            guard item.kind == .fixed, let actual = item.linkedExpense else { return running }
            return running + (actual.amount - item.amount)
        }
        let envelopeDrift = envelopes.reduce(Decimal(0)) { $0 + $1.overspend }
        drift = fixedDrift + envelopeDrift
    }

    init(totalIncome: Decimal, totalCost: Decimal, drift: Decimal) {
        self.totalIncome = totalIncome
        self.totalCost = totalCost
        self.drift = drift
    }
}
