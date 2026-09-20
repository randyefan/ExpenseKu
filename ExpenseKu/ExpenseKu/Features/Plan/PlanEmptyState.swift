//
//  PlanEmptyState.swift
//  ExpenseKu
//
//  The Plan lens with no plan at all (frame I5). Only reachable for the owner's first
//  cycle, because every later one arrives already populated by carry-over (PRD §7.2) —
//  which is what the message says, so the button does not look like a chore they will
//  be repeating every month.
//

import SwiftUI

struct PlanEmptyState: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            EmptyStateView(
                title: "No plan yet",
                systemImage: "list.clipboard",
                message: "Start one for this cycle, then every cycle after it is copied forward automatically."
            )

            Button("Start this cycle's plan", action: onStart)
                .font(.dsBody).bold()
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent, in: .capsule)
                .buttonStyle(.pressableCard)
                .padding(.horizontal, Metric.cardPadding)
        }
    }
}
