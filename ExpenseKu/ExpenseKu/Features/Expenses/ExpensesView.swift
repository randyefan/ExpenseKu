//
//  ExpensesView.swift
//  ExpenseKu
//
//  The Expenses tab and the app's home surface. The primary lens is the owner's
//  pay cycle (ADR-0004): one cycle at a time, anchored to the Monthly Start Date,
//  paged with < / > and sub-grouped by day. Uses NavigationSplitView so it adapts
//  per device (design.md §1): list + detail-pane editing on iPad/Mac, a collapsed
//  push on iPhone. Add is always a sheet for the fast logging flow (design.md §2).
//
//  Within the cycle the owner picks one of two lenses with the List/Month toggle:
//  the day-grouped list (default) or the calendar grid (see CycleCalendar.swift).
//  Both read the same `CycleContents`, so they can never disagree.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    /// How the cycle's expenses are laid out. Session state — the tab opens on
    /// `.list` every launch, and the choice sticks while the app runs.
    enum Lens: Hashable { case list, calendar }

    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var selection: Expense?
    @State private var showingNew = false
    @State private var showingSettings = false
    @State private var payday: Int = Payday.current
    @State private var cycle: PayCycle = PayCycle.containing(.now, payday: Payday.current)
    @State private var lens: Lens = .list
    /// The day the calendar has selected. Nil (or stale after paging) means
    /// "fall back to the default day" — see `resolvedSelectedDay`.
    @State private var selectedDay: Date?
    #if DEBUG
    /// -startScreen calendar-day: select the cycle's heaviest day so the populated
    /// day-list state is screenshot-able. A flag rather than a computed selection
    /// because the seed may not have landed yet when this view's task runs.
    @State private var debugSelectHeaviest = false
    #endif

    private var calendar: Calendar { .current }

    /// On compact width (iPhone) the split view would push the editor as a full
    /// page; there we present editing as a bottom sheet instead. iPad keeps
    /// the detail-pane editing (design.md §1).
    private var editsInSheet: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        // Derived once per pass and shared by both lenses, rather than each of the
        // header, list, calendar and day sections re-filtering the whole table.
        let contents = CycleContents(cycle: cycle, allExpenses: expenses, calendar: calendar)

        NavigationSplitView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                // Header + arrows stay even with no expenses at all (home-empty.png);
                // the content area carries the right empty message.
                VStack(spacing: 0) {
                    CycleHeader(
                        cycle: cycle,
                        total: contents.total,
                        canGoBack: CyclePaging.canGoBack(from: cycle, oldestExpense: expenses.last?.date),
                        canGoForward: CyclePaging.canGoForward(from: cycle, now: .now),
                        calendar: calendar,
                        onPrevious: { cycle = cycle.previous(payday: payday, calendar: calendar) },
                        onNext: { cycle = cycle.next(payday: payday, calendar: calendar) }
                    )

                    SegmentedToggle(
                        selection: $lens,
                        segments: [
                            .init(.list, title: "List", systemImage: "list.bullet"),
                            .init(.calendar, title: "Month", systemImage: "calendar"),
                        ]
                    )
                    .padding(.bottom, Metric.cardGap)

                    switch lens {
                    case .list:
                        listLens(contents)
                    case .calendar:
                        CycleCalendarLens(
                            calendarGrid: calendarGrid,
                            contents: contents,
                            cycle: cycle,
                            storeIsEmpty: expenses.isEmpty,
                            calendar: calendar,
                            selectedDay: $selectedDay,
                            resolvedDay: resolvedSelectedDay,
                            onSelect: { selection = $0 },
                            onDelete: delete
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Monthly Start Date", systemImage: "calendar") {
                        showingSettings = true
                    }
                    .tint(Theme.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Expense", systemImage: "plus") {
                        showingNew = true
                    }
                    .accentCircleButton()
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    ExpenseEditorView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                TransactionSettingsView(payday: $payday)
            }
            .sheet(item: editsInSheet ? $selection : .constant(nil)) { expense in
                NavigationStack {
                    ExpenseEditorView(editing: expense, onFinish: { selection = nil })
                }
                .presentationDragIndicator(.visible)
            }
            .onAppear { resetToCurrentCycle() }
            .onChange(of: payday) { _, newValue in
                cycle = PayCycle.containing(.now, payday: newValue, calendar: calendar)
            }
            #if DEBUG
            .task {
                switch DebugLaunch.startScreen {
                case "calendar":
                    lens = .calendar
                case "calendar-day":
                    lens = .calendar
                    debugSelectHeaviest = true
                default:
                    break
                }
            }
            #endif
        } detail: {
            if let selection, !editsInSheet {
                ExpenseEditorView(editing: selection, onFinish: { self.selection = nil })
                    .id(selection.persistentModelID)
            } else {
                EmptyStateView(
                    title: "No Expense Selected",
                    systemImage: "sidebar.right",
                    message: "Select an expense to view or edit it."
                )
            }
        }
    }

    // MARK: - List lens (or the empty state that replaces it)

    @ViewBuilder
    private func listLens(_ contents: CycleContents) -> some View {
        if contents.isEmpty {
            if expenses.isEmpty {
                // No expenses anywhere yet — the first-run empty state (home-empty.png).
                EmptyStateView(
                    title: "No expenses yet",
                    systemImage: "doc.text",
                    message: "Tap + to log your first expense."
                )
            } else {
                // Data exists in other cycles; this one is just empty.
                EmptyStateView(
                    title: "No expenses this cycle",
                    systemImage: "calendar",
                    message: "Nothing logged for \(cycle.rangeText(calendar: calendar))."
                )
            }
        } else {
            CycleListLens(
                dayGroups: contents.dayGroups,
                calendar: calendar,
                onSelect: { selection = $0 },
                onDelete: delete
            )
        }
    }

    // MARK: - Calendar state

    private var calendarGrid: CycleCalendar {
        cycleCalendar(for: cycle, expenses: expenses, calendar: calendar)
    }

    /// The day the grid should show as selected. An explicit tap wins, but only
    /// while it still belongs to the visible cycle — so paging with ‹ › re-defaults
    /// without any reset bookkeeping.
    private var resolvedSelectedDay: Date? {
        if let selectedDay, cycle.contains(selectedDay) { return selectedDay }
        #if DEBUG
        if debugSelectHeaviest,
           let heaviest = calendarGrid.cycleDays.filter(\.hasExpenses).max(by: { $0.total < $1.total }) {
            return heaviest.date
        }
        #endif
        return defaultSelectedDay(in: calendarGrid, today: .now, calendar: calendar)
    }

    // MARK: - Actions

    private func resetToCurrentCycle() {
        payday = Payday.current
        cycle = PayCycle.containing(.now, payday: payday, calendar: calendar)
    }

    /// Delete by offset within one day's rows — shared by both lenses, so a swipe
    /// deletes the same expense whichever way the day is being displayed.
    private func delete(_ offsets: IndexSet, from dayExpenses: [Expense]) {
        for index in offsets {
            let expense = dayExpenses[index]
            if expense == selection { selection = nil }
            context.delete(expense)
        }
        // Outside the loop: one transaction for the whole swipe batch.
        try? context.save()
    }
}
