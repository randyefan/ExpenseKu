//
//  CycleHeader.swift
//  ExpenseKu
//
//  The Expenses tab's header card: ‹ › to page between pay cycles, the cycle's title
//  and date span, and the cycle's spending total. Spending only — the domain has no
//  income concept (Q6).
//
//  The total is charcoal, not coral: the accent is reserved for actions and selected
//  states, and a figure this large in coral reads as an alarm. The card carries a
//  faint coral wash instead, which marks it as the hero without spending the accent.
//  Paging rolls the figure to its new value so the change is legible.
//

import SwiftUI

struct CycleHeader: View {
    let cycle: PayCycle
    let total: Decimal
    let canGoBack: Bool
    let canGoForward: Bool
    let calendar: Calendar
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                CyclePageButton(
                    label: "Previous cycle",
                    systemImage: "chevron.left",
                    enabled: canGoBack,
                    action: onPrevious
                )

                Spacer(minLength: 8)

                VStack(spacing: 2) {
                    Text(cycle.title(calendar: calendar))
                        .font(.dsHeadline).bold()
                        .foregroundStyle(Theme.text)
                        .contentTransition(.numericText())
                    Text(cycle.rangeText(calendar: calendar))
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .motion(Motion.reveal, value: cycle)

                Spacer(minLength: 8)

                CyclePageButton(
                    label: "Next cycle",
                    systemImage: "chevron.right",
                    enabled: canGoForward,
                    action: onNext
                )
            }

            VStack(spacing: 2) {
                SectionHeaderText("Spending")
                MoneyText(total, font: .dsHero, color: Theme.text, rolls: true)
            }
        }
        .padding(Metric.cardPadding)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .fill(Theme.card)
                .overlay {
                    RoundedRectangle(cornerRadius: Metric.cardRadius)
                        .fill(Theme.accent.opacity(0.05))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Metric.cardRadius)
                        .stroke(Theme.hairline, lineWidth: 1)
                }
        }
        .padding(.top, 8)
        .padding(.bottom, Metric.cardGap)
    }
}

private struct CyclePageButton: View {
    let label: String
    let systemImage: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(label, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.dsBody.weight(.semibold))
            .foregroundStyle(enabled ? Theme.accent : Theme.textSecondary.opacity(0.4))
            .frame(width: 44, height: 44)
            .contentShape(.circle)
            .buttonStyle(.pressableCard)
            .disabled(!enabled)
            .motion(Motion.press, value: enabled)
    }
}

#Preview {
    CycleHeader(
        cycle: PayCycle.containing(.now, payday: 1),
        total: 220_000,
        canGoBack: true,
        canGoForward: false,
        calendar: .current,
        onPrevious: {},
        onNext: {}
    )
    .padding(.horizontal, Metric.screenPadding)
    .appBackground()
}
