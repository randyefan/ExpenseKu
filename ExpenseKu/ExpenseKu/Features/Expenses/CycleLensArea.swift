//
//  CycleLensArea.swift
//  ExpenseKu
//
//  The Expenses tab's content area below the header: whichever lens is selected, or
//  the empty state that stands in for it.
//
//  One child with one composite identity, and the transition is chosen by the
//  caller from *what* changed. An earlier version declared `.opacity` on each lens
//  branch and the page transition on the container; a child that declares its own
//  transition wins when the whole subtree is replaced, so paging silently
//  cross-faded instead of travelling. Only one transition may be declared on this
//  path.
//

import SwiftUI

/// What the last change to the Expenses content area was, which decides how that
/// content is replaced. A standalone type rather than a member of the generic
/// `CycleLensArea`, so state can name it without pinning down a header type.
enum CycleContentChange {
    /// The owner paged to another cycle: the content travels the way the arrow
    /// pointed.
    case page(Edge)
    /// The owner switched lens. Lenses are peers, so they cross-fade.
    case lens

    var transition: AnyTransition {
        switch self {
        case .page(let edge): .page(towards: edge)
        case .lens: .opacity
        }
    }
}

struct CycleLensArea<Header: View>: View {
    let contents: CycleContents
    let cycle: PayCycle
    let calendarGrid: CycleCalendar
    let calendar: Calendar
    let lens: ExpensesView.Lens
    let change: CycleContentChange
    let storeIsEmpty: Bool
    @Binding var selectedDay: Date?
    let resolvedDay: Date?
    let onSelect: (Expense) -> Void
    let onDelete: (IndexSet, [Expense]) -> Void
    /// The cycle header and lens toggle, handed to whichever lens is showing so
    /// they scroll with its content instead of being pinned above it.
    @ViewBuilder let header: Header

    var body: some View {
        Group {
            switch lens {
            case .list:
                if contents.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            header
                            CycleEmptyState(
                                storeIsEmpty: storeIsEmpty,
                                cycle: cycle,
                                calendar: calendar
                            )
                        }
                        .padding(.horizontal, Metric.screenPadding)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    CycleListLens(
                        dayGroups: contents.dayGroups,
                        calendar: calendar,
                        revealTrigger: AnyHashable(cycle),
                        onSelect: onSelect,
                        onDelete: onDelete,
                        header: { header }
                    )
                }
            case .calendar:
                CycleCalendarLens(
                    calendarGrid: calendarGrid,
                    contents: contents,
                    cycle: cycle,
                    storeIsEmpty: storeIsEmpty,
                    calendar: calendar,
                    selectedDay: $selectedDay,
                    resolvedDay: resolvedDay,
                    onSelect: onSelect,
                    onDelete: onDelete,
                    header: { header }
                )
            }
        }
        .id(LensKey(cycle: cycle, lens: lens))
        .motionTransition(change.transition)
    }
}

private struct LensKey: Hashable {
    let cycle: PayCycle
    let lens: ExpensesView.Lens
}

/// The two ways a cycle can show nothing: the store is empty everywhere, or this
/// cycle in particular is.
struct CycleEmptyState: View {
    let storeIsEmpty: Bool
    let cycle: PayCycle
    let calendar: Calendar

    var body: some View {
        if storeIsEmpty {
            EmptyStateView(
                title: "No expenses yet",
                systemImage: "doc.text",
                message: "Tap + to log your first expense."
            )
        } else {
            EmptyStateView(
                title: "No expenses this cycle",
                systemImage: "calendar",
                message: "Nothing logged for \(cycle.rangeText(calendar: calendar))."
            )
        }
    }
}
