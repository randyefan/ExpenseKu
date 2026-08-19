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
//  Both read the same cycle and the same day grouping, so they can never disagree.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    /// How the cycle's expenses are laid out. Session state — the tab opens on
    /// `.list` every launch, and the choice sticks while the app runs.
    enum Lens: Hashable { case list, calendar }

    @Environment(\.modelContext) private var context
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
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
    /// page; there we present editing as a bottom sheet instead. iPad/Mac keep
    /// the detail-pane editing (design.md §1).
    private var editsInSheet: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    var body: some View {
        NavigationSplitView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                // Header + arrows stay even with no expenses at all (home-empty.png);
                // the content area carries the right empty message.
                VStack(spacing: 0) {
                    cycleHeader
                    lensToggle
                    switch lens {
                    case .list: cycleContent
                    case .calendar: calendarContent
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Monthly Start Date", systemImage: "calendar")
                    }
                    .tint(Theme.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Label("Add Expense", systemImage: "plus")
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

    // MARK: - Cycle header (navigator + spending total)

    private var cycleHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    cycle = cycle.previous(payday: payday, calendar: calendar)
                } label: {
                    Image(systemName: "chevron.left").font(.body.weight(.semibold))
                }
                .disabled(!canGoBack)

                Spacer()

                VStack(spacing: 2) {
                    Text(cycle.title(calendar: calendar))
                        .font(.dsHeadline).fontWeight(.bold)
                        .foregroundStyle(Theme.text)
                    Text(cycle.rangeText(calendar: calendar))
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Button {
                    cycle = cycle.next(payday: payday, calendar: calendar)
                } label: {
                    Image(systemName: "chevron.right").font(.body.weight(.semibold))
                }
                .disabled(!canGoForward)
            }

            VStack(spacing: 4) {
                SectionHeaderText("Spending")
                // Spending total only — the domain has no income concept (Q6).
                // Hero total is the one place the coral accent lands on money.
                MoneyText(cycleTotal, font: .dsHero, color: Theme.accent)
            }
        }
        .cardStyle()
        .padding(.horizontal, Metric.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, Metric.cardGap)
    }

    // MARK: - Lens toggle (List / Month)

    private var lensToggle: some View {
        SegmentedToggle(
            selection: $lens,
            segments: [
                .init(.list, title: "List", systemImage: "list.bullet"),
                .init(.calendar, title: "Month", systemImage: "calendar"),
            ]
        )
        .padding(.bottom, Metric.cardGap)
    }

    // MARK: - Calendar content (grid card + the selected day's expenses)

    private var calendarContent: some View {
        // A List (not a ScrollView) so the day's rows keep swipe-to-delete and the
        // same row chrome as the list lens.
        List {
            Section {
                CycleCalendarGrid(
                    calendarGrid: calendarGrid,
                    selection: Binding(
                        get: { resolvedSelectedDay },
                        set: { selectedDay = $0 }
                    ),
                    calendar: calendar
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: 0, leading: Metric.screenPadding,
                    bottom: Metric.cardGap, trailing: Metric.screenPadding
                ))
            }

            if cycleExpenses.isEmpty {
                // Nothing in this cycle at all — the grid stays, the message speaks
                // for the whole cycle rather than for one empty day.
                Section {
                    inlineMessage(
                        expenses.isEmpty ? "No expenses yet" : "No expenses this cycle",
                        detail: expenses.isEmpty
                            ? "Tap + to log your first expense."
                            : "Nothing logged for \(cycle.rangeText(calendar: calendar))."
                    )
                }
            } else if let day = resolvedSelectedDay {
                Section {
                    if let group = selectedDayGroup {
                        ForEach(group.expenses) { expense in
                            Button {
                                selection = expense
                            } label: {
                                ExpenseRow(expense: expense)
                            }
                            .buttonStyle(.plain)
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: 4, leading: Metric.screenPadding,
                                bottom: 4, trailing: Metric.screenPadding
                            ))
                        }
                        .onDelete { delete($0, from: group.expenses) }
                    } else {
                        inlineMessage(
                            "No expenses \(dayPhrase(day))",
                            detail: "Tap + to log one."
                        )
                    }
                } header: {
                    HStack {
                        SectionHeaderText(dayTitle(day))
                        Spacer()
                        // Day total in the same quiet, secondary, monospaced style as
                        // the list lens's day header — never the coral hero accent.
                        Text((selectedDayGroup?.total ?? 0).formattedIDR())
                            .font(.dsCaption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .listStyle(.plain)
        // The grid is tall; without this the stock section gap pushes the day's
        // rows further under the tab bar than they need to be.
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }

    /// A quiet inline message card — the in-list counterpart of `EmptyStateView`,
    /// which is full-bleed and can't sit inside a list row.
    private func inlineMessage(_ title: String, detail: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(Theme.text)
            Text(detail)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: 4, leading: Metric.screenPadding,
            bottom: 4, trailing: Metric.screenPadding
        ))
    }

    // MARK: - Cycle content (day groups, or an inline empty state)

    @ViewBuilder
    private var cycleContent: some View {
        if cycleExpenses.isEmpty {
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
            List {
                ForEach(dayGroups) { group in
                    Section {
                        ForEach(group.expenses) { expense in
                            Button {
                                selection = expense
                            } label: {
                                ExpenseRow(expense: expense)
                            }
                            .buttonStyle(.plain)
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: 4, leading: Metric.screenPadding,
                                bottom: 4, trailing: Metric.screenPadding
                            ))
                        }
                        .onDelete { delete($0, in: group) }
                    } header: {
                        HStack {
                            SectionHeaderText(group.title)
                            Spacer()
                            // Day total, styled to match the header label (Variant A):
                            // quiet, secondary, monospaced — never the coral hero accent.
                            Text(group.total.formattedIDR())
                                .font(.dsCaption)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
        }
    }

    // MARK: - Derived state

    private var cycleExpenses: [Expense] {
        expenses.filter { cycle.contains($0.date) }
    }

    private var cycleTotal: Decimal {
        cycleExpenses.reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// There is data older than the current cycle to page back to.
    private var canGoBack: Bool {
        guard let oldest = expenses.last?.date else { return false }
        return oldest < cycle.start
    }

    /// Forward paging stops at the present cycle — no empty future cycles (Q7).
    private var canGoForward: Bool {
        cycle.end <= Date.now
    }

    private func resetToCurrentCycle() {
        payday = Payday.current
        cycle = PayCycle.containing(.now, payday: payday, calendar: calendar)
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

    /// The selected day's expenses, taken from the same grouping the list lens uses.
    private var selectedDayGroup: ExpenseDayGroup? {
        guard let day = resolvedSelectedDay else { return nil }
        return expenseDayGroups(cycleExpenses, calendar: calendar).first { $0.day == day }
    }

    // MARK: - Day grouping

    private struct DayGroup: Identifiable {
        let id: Date          // start of day
        let title: String
        let expenses: [Expense]
        let total: Decimal
    }

    private var dayGroups: [DayGroup] {
        expenseDayGroups(cycleExpenses, calendar: calendar).map { group in
            DayGroup(
                id: group.day,
                title: dayTitle(group.day),
                expenses: group.expenses,
                total: group.total
            )
        }
    }

    private func dayTitle(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.wide))
    }

    /// The same day, phrased to sit inside a sentence: "No expenses **today**",
    /// "No expenses **on Thu, 6 August**". `dayTitle` alone reads "on Today".
    private func dayPhrase(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "today" }
        if calendar.isDateInYesterday(day) { return "yesterday" }
        return "on \(day.formatted(.dateTime.weekday(.abbreviated).day().month(.wide)))"
    }

    private func delete(_ offsets: IndexSet, in group: DayGroup) {
        delete(offsets, from: group.expenses)
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
