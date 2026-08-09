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

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var selection: Expense?
    @State private var showingNew = false
    @State private var showingSettings = false
    @State private var payday: Int = Payday.current
    @State private var cycle: PayCycle = PayCycle.containing(.now, payday: Payday.current)

    private var calendar: Calendar { .current }

    var body: some View {
        NavigationSplitView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                // Header + arrows stay even with no expenses at all (home-empty.png);
                // the content area carries the right empty message.
                VStack(spacing: 0) {
                    cycleHeader
                    cycleContent
                }
            }
            .navigationTitle("Expenses")
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
                    .buttonStyle(AccentCircleButtonStyle())
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
            .onAppear { resetToCurrentCycle() }
            .onChange(of: payday) { _, newValue in
                cycle = PayCycle.containing(.now, payday: newValue, calendar: calendar)
            }
        } detail: {
            if let selection {
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
            List(selection: $selection) {
                ForEach(dayGroups) { group in
                    Section {
                        ForEach(group.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .tag(expense)
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
                        SectionHeaderText(group.title)
                            .padding(.leading, 4)
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

    // MARK: - Day grouping

    private struct DayGroup: Identifiable {
        let id: Date          // start of day
        let title: String
        let expenses: [Expense]
    }

    private var dayGroups: [DayGroup] {
        let grouped = Dictionary(grouping: cycleExpenses) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { day in
            DayGroup(
                id: day,
                title: dayTitle(day),
                expenses: (grouped[day] ?? []).sorted { $0.date > $1.date }
            )
        }
    }

    private func dayTitle(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.wide))
    }

    private func delete(_ offsets: IndexSet, in group: DayGroup) {
        for index in offsets {
            let expense = group.expenses[index]
            if expense == selection { selection = nil }
            context.delete(expense)
        }
    }
}
