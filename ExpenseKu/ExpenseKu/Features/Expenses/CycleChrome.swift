//
//  CycleChrome.swift
//  ExpenseKu
//
//  The Expenses tab's header block: the cycle pager and total, then the List/Month
//  toggle. Handed to whichever lens is showing so it scrolls with that lens's
//  content — pinned above the list it overflowed and clipped at accessibility
//  text sizes, where the cycle title wraps to two lines.
//

import SwiftUI

struct CycleChrome: View {
    let cycle: PayCycle
    let total: Decimal
    let canGoBack: Bool
    let canGoForward: Bool
    let calendar: Calendar
    @Binding var lens: ExpensesView.Lens
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CycleHeader(
                cycle: cycle,
                total: total,
                canGoBack: canGoBack,
                canGoForward: canGoForward,
                calendar: calendar,
                onPrevious: onPrevious,
                onNext: onNext
            )

            SegmentedToggle(
                selection: $lens,
                segments: [
                    .init(.list, title: "List", systemImage: "list.bullet"),
                    .init(.calendar, title: "Month", systemImage: "calendar"),
                ]
            )
            .padding(.bottom, Metric.cardGap)
        }
    }
}
