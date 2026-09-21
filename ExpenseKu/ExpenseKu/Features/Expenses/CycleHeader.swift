//
//  CycleHeader.swift
//  ExpenseKu
//
//  The Expenses tab's header card: ‹ › to page between pay cycles, the cycle's title
//  and date span, and one labelled figure about it.
//
//  The figure is whatever the active lens is about — SPENDING in List and Month, SISA
//  in Plan (PRD §6.2) — and the card keeps its shape across all three. The label
//  always names the number, which is what lets one header serve three lenses without
//  a figure ever silently changing meaning.
//
//  The total is charcoal, not coral: the accent is reserved for actions and selected
//  states, and a figure this large in coral reads as an alarm. The card carries a
//  faint coral wash instead, which marks it as the hero without spending the accent.
//  Paging rolls the figure to its new value so the change is legible.
//

import SwiftUI

struct CycleHeader: View {
    let cycle: PayCycle
    let headline: CycleHeadline
    var split: SpendingSplit? = nil
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
                SectionHeaderText(headline.label)
                MoneyText(headline.amount, font: .dsHero, color: headlineColor, rolls: true)
            }

            if let split, split.fromPlan > 0 {
                SpendingSplitView(split: split)
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

    /// Charcoal for the ordinary case: a figure this large in accent reads as an
    /// alarm, and the accent is reserved for actions and selected states. A plan that
    /// allocates past its income is the one thing worth alarming about (frame I6).
    private var headlineColor: Color {
        switch headline.tint {
        case .neutral: Theme.text
        case .negative: Theme.negative
        }
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

private struct SpendingSplitView: View {
    let split: SpendingSplit

    var body: some View {
        VStack(spacing: 10) {
            SpendingSplitBar(split: split)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    outsideLegend(alignment: .leading)
                    Spacer(minLength: 12)
                    fromPlanLegend(alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: 8) {
                    outsideLegend(alignment: .leading)
                    fromPlanLegend(alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func outsideLegend(alignment: HorizontalAlignment) -> some View {
        SpendingSplitLegend(title: "Outside plan", amount: split.outsidePlan,
                            color: Theme.accent, alignment: alignment)
    }

    private func fromPlanLegend(alignment: HorizontalAlignment) -> some View {
        SpendingSplitLegend(title: "From plan", amount: split.fromPlan,
                            color: Theme.plan, alignment: alignment)
    }
}

private struct SpendingSplitBar: View {
    let split: SpendingSplit

    var body: some View {
        GeometryReader { proxy in
            let hasOutside = split.outsidePlan > 0
            let gap: CGFloat = hasOutside ? 2 : 0
            let outsideWidth = hasOutside
                ? max(4, (proxy.size.width - gap) * split.outsideFraction)
                : 0
            HStack(spacing: gap) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: outsideWidth)
                Rectangle()
                    .fill(Theme.plan)
            }
        }
        .frame(height: 8)
        .clipShape(.capsule)
        .motion(Motion.number, value: split)
        .accessibilityHidden(true)
    }
}

private struct SpendingSplitLegend: View {
    let title: String
    let amount: Decimal
    let color: Color
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.dsCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            MoneyText(amount, font: .dsSubhead, color: Theme.text, rolls: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(amount.formattedIDR())
    }
}

#Preview("Split") {
    CycleHeader(
        cycle: PayCycle.containing(.now, payday: 1),
        headline: .spending(4_570_000),
        split: SpendingSplit(outsidePlan: 55_000, fromPlan: 4_515_000),
        canGoBack: true,
        canGoForward: false,
        calendar: .current,
        onPrevious: {},
        onNext: {}
    )
    .padding(.horizontal, Metric.screenPadding)
    .appBackground()
}

#Preview {
    CycleHeader(
        cycle: PayCycle.containing(.now, payday: 1),
        headline: .spending(220_000),
        canGoBack: true,
        canGoForward: false,
        calendar: .current,
        onPrevious: {},
        onNext: {}
    )
    .padding(.horizontal, Metric.screenPadding)
    .appBackground()
}
