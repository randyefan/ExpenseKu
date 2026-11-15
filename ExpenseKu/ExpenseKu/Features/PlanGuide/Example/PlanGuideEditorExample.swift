//
//  PlanGuideEditorExample.swift
//  ExpenseKu
//
//  The expense editor at the moment Harian is chosen as the Envelope (plan-guide-visual.md
//  §4.5, step 5.1 ③): its amount, Category grid and Envelope row, with the editor's own
//  views. The whole ExpenseEditorView needs the receipt reader, the keypad dock and a
//  sheet to live in, so the guide draws the part the caption is about.
//

import SwiftData
import SwiftUI

struct PlanGuideEditorExample: View {
    let sample: PlanGuideSample

    var body: some View {
        let amount: Decimal = 45_000
        let offer = EnvelopeOffer(cycle: sample.cycle, plans: [sample.november], payday: PlanGuideSample.payday,
                                  calendar: sample.calendar, now: sample.today)
        let choice = EnvelopeChoice.envelope(sample.harian.persistentModelID)
        let field = EnvelopeField(choice: .constant(choice),
                                  value: EnvelopeOptions(offer: offer, expenses: []).value(for: choice, category: sample.makan),
                                  offer: offer)
        let categories = (sample.harian.envelopeCategories ?? []).sorted { $0.name < $1.name }

        VStack(spacing: 18) {
            AmountHero(displayExpression: ExpressionEvaluator(amount: amount).displayExpression, amount: amount)
            CategoryGrid(categories: categories, selection: .constant(sample.makan), onShowAll: {})
                .padding(.horizontal, -Metric.screenPadding)
            EnvelopeFormRow(field: field, category: sample.makan)
                .padding(.vertical, 14)
                .padding(.horizontal, Metric.cardPadding)
                .background(Theme.card, in: .rect(cornerRadius: Metric.cardRadius))
                .planGuideTarget(.editorEnvelope, radius: Metric.cardRadius)
        }
        .padding(.vertical, Metric.cardPadding)
        .padding(.horizontal, Metric.cardPadding)
        .background(Theme.surface.opacity(0.5), in: .rect(cornerRadius: Metric.cardRadius + 4))
    }
}
