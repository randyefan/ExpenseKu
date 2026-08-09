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
            Group {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "creditcard",
                        description: Text("Tap + to log your first expense.")
                    )
                } else {
                    VStack(spacing: 0) {
                        cycleHeader
                        cycleContent
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Label("Add Expense", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Monthly Start Date", systemImage: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    ExpenseEditorView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                settingsSheet
            }
            .onAppear { resetToCurrentCycle() }
        } detail: {
            if let selection {
                ExpenseEditorView(editing: selection, onFinish: { self.selection = nil })
                    .id(selection.persistentModelID)
            } else {
                ContentUnavailableView(
                    "No Expense Selected",
                    systemImage: "sidebar.right",
                    description: Text("Select an expense to view or edit it.")
                )
            }
        }
    }

    // MARK: - Cycle header (navigator + spending total)

    private var cycleHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    cycle = cycle.previous(payday: payday, calendar: calendar)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)

                Spacer()

                VStack(spacing: 2) {
                    Text(cycle.title(calendar: calendar))
                        .font(.headline)
                    Text(cycle.rangeText(calendar: calendar))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    cycle = cycle.next(payday: payday, calendar: calendar)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
            }
            .font(.title3)

            HStack {
                Text("Spending")
                    .foregroundStyle(.secondary)
                Spacer()
                // Spending total only — the domain has no income concept (Q6).
                Text(cycleTotal.formattedIDR())
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Cycle content (day groups, or an inline empty state)

    @ViewBuilder
    private var cycleContent: some View {
        if cycleExpenses.isEmpty {
            ContentUnavailableView(
                "No expenses this cycle",
                systemImage: "calendar",
                description: Text("Nothing logged for \(cycle.rangeText(calendar: calendar)).")
            )
        } else {
            List(selection: $selection) {
                ForEach(dayGroups) { group in
                    Section(group.title) {
                        ForEach(group.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .tag(expense)
                        }
                        .onDelete { delete($0, in: group) }
                    }
                }
            }
        }
    }

    // MARK: - Monthly Start Date

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $payday, in: Payday.range) {
                        LabeledContent("Monthly Start Date", value: "Day \(payday)")
                    }
                    .onChange(of: payday) { _, newValue in
                        Payday.current = newValue
                        cycle = PayCycle.containing(.now, payday: newValue, calendar: calendar)
                    }
                } footer: {
                    Text("The day of the month your spending cycle resets. Shared with the Insights pay-period view.")
                }
            }
            .navigationTitle("Transaction Settings")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingSettings = false }
                }
            }
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
