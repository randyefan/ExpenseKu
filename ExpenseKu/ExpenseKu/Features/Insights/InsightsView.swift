//
//  InsightsView.swift
//  ExpenseKu
//
//  The Insights tab: a SPENDING card with the plan split, spend-by-category,
//  spend-by-account and spend-over-time charts over a shared window, plus a link to
//  the People leaderboard. Breakdown rows drill into SpendEntityView
//  (docs/prd/insights-drill-in.md). Aggregation lives in the pure SpendSummary /
//  PlanOrigins / PeopleLeaderboard layers.
//
//  The window is held with its own `now`, refreshed when the window changes or the tab
//  reappears, so toggling the plan filter does not move the fetch's upper bound and
//  remount the charts.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    enum Destination: Hashable {
        case leaderboard
        case personExpenses(PersonExpensesRoute)
        case spendEntity(SpendEntityRoute)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.calendar) private var calendar

    @Query(sort: \CyclePlan.cycleStart) private var plans: [CyclePlan]
    @Query(Self.oldestExpense) private var oldest: [Expense]
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \CategoryGroup.name) private var groups: [CategoryGroup]
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Person.name) private var people: [Person]

    @State private var window = InsightsWindow(preset: .payPeriod)
    @State private var planFilter: PlanFilter?
    /// Insights' own Category / Group / Account / Person filter; it survives chip and pay
    /// period changes (expense-filter.md §8.2).
    @State private var filter = ExpenseFilter()
    @State private var showingFilter = false
    @State private var payday: Int = Payday.current
    @State private var now = Date.now
    @State private var path: [Destination] = []

    private static var oldestExpense: FetchDescriptor<Expense> {
        var descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date)])
        descriptor.fetchLimit = 1
        return descriptor
    }

    var body: some View {
        let dateRange = window.range(now: now, payday: payday, calendar: calendar)
        let shownCycle = window.payCycle(now: now, payday: payday, calendar: calendar)
        let origins = PlanOrigins(plans: plans, payday: payday, calendar: calendar)
        let catalog = FilterCatalog(categories: categories, groups: groups, accounts: accounts, people: people)
        let activeFilter = catalog.pruning(filter)

        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Metric.cardGap) {
                    PeriodFilterChips(selection: presetBinding, label: InsightsWindow.chipLabel)
                        .padding(.horizontal, -Metric.screenPadding)

                    if window.preset == .payPeriod {
                        PayPeriodMenuRow(
                            cycles: PayPeriodChoices.cycles(oldestExpense: oldest.first?.date, now: now,
                                                            payday: payday, calendar: calendar),
                            selected: shownCycle,
                            onSelect: select
                        )
                        .motionTransition(.rise)
                    }

                    // Re-created whenever the window changes, because @Query fixes its
                    // predicate at init.
                    InsightsCharts(
                        dateRange: dateRange,
                        payday: payday,
                        highlightedCycle: window.preset == .payPeriod
                            ? shownCycle
                            : PayCycle.containing(now, payday: payday, calendar: calendar),
                        origins: origins,
                        filter: activeFilter,
                        planFilter: $planFilter
                    ) { subject in
                        path.append(.spendEntity(SpendEntityRoute(subject: subject, window: window,
                                                                  planFilter: planFilter,
                                                                  filter: activeFilter)))
                    }
                    .id(dateRange)

                    LeaderboardLinkCard()
                        .reveal(5, trigger: dateRange)
                }
                .padding(Metric.screenPadding)
                .readableColumn()
                .motion(Motion.snap, value: window)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if !activeFilter.isEmpty {
                        FilterPill(text: catalog.pillText(for: activeFilter)) { filter = ExpenseFilter() }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if let planFilter {
                        PlanFilterPill(filter: planFilter) { self.planFilter = nil }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 8)
            }
            .motion(Motion.settle, value: planFilter)
            .motion(Motion.settle, value: activeFilter)
            .toolbar {
                if !oldest.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        FilterButton(activeCount: activeFilter.activeCount(planFilter: planFilter)) {
                            showingFilter = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterSheet(filter: $filter, planFilter: $planFilter, catalog: catalog)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.bg)
            .navigationTitle("Insights")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .leaderboard:
                    PeopleLeaderboardView()
                case .personExpenses(let route):
                    PersonExpensesView(route: route)
                case .spendEntity(let route):
                    SpendEntityView(route: route)
                }
            }
        }
        .onAppear(perform: refresh)
        .task {
            #if DEBUG
            applyDebugStartScreen()
            #endif
        }
    }

    /// A new chip clears the plan filter (decision 13); the chosen cycle stays (14).
    private var presetBinding: Binding<DateRangeFilter> {
        Binding(
            get: { window.preset },
            set: { preset in
                guard preset != window.preset else { return }
                now = .now
                planFilter = nil
                window.preset = preset
            }
        )
    }

    private func select(_ cycle: PayCycle) {
        guard window.select(cycle, now: now) else { return }
        now = .now
        planFilter = nil
    }

    /// The payday is set in Expenses; a new one re-anchors every cycle, so the chosen
    /// one returns to the current (D6).
    private func refresh() {
        now = .now
        guard Payday.current != payday else { return }
        payday = Payday.current
        window.cycle = nil
    }

    #if DEBUG
    private func applyDebugStartScreen() {
        switch DebugLaunch.startScreen {
        case "leaderboard":
            path = [.leaderboard]
        case "person-detail":
            // Drive Insights → leaderboard → detail for the top-ranked companion,
            // so the pushed screen is screenshot-able with realistic data.
            let all = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
            if let person = PeopleLeaderboard.ranked(from: all).first?.person {
                let route = PersonExpensesRoute(person: person, category: nil,
                                                account: nil, range: .allTime)
                path = [.leaderboard, .personExpenses(route)]
            } else {
                path = [.leaderboard]
            }
        default:
            break
        }
    }
    #endif
}
