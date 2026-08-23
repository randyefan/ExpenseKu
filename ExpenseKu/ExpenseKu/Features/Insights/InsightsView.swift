//
//  InsightsView.swift
//  ExpenseKu
//
//  The Insights tab: spend-by-category, spend-by-account and spend-over-time
//  charts over a shared period filter, plus a link to the People leaderboard.
//  Aggregation lives in the pure SpendSummary / PeopleLeaderboard layers.
//  Warm Cards styling; behaviour unchanged (all five presets + the pay-period
//  stepper, ADR-0003).
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    enum Destination: Hashable {
        case leaderboard
        case personExpenses(PersonExpensesRoute)
    }

    @Environment(\.modelContext) private var context
    @State private var range: DateRangeFilter = .thisYear
    @State private var payday: Int = Payday.current
    @State private var path: [Destination] = []

    var body: some View {
        let dateRange = range.range(payday: payday)

        NavigationStack(path: $path) {
            ScrollView {
                VStack {
                    PeriodFilterChips(selection: $range)

                    if range == .payPeriod {
                        PaydayRow(payday: $payday)
                    }

                    // Re-created whenever the window changes, because @Query fixes its
                    // predicate at init.
                    InsightsCharts(dateRange: dateRange)
                        .id(dateRange)

                    LeaderboardLinkCard()
                }
                .padding(Metric.screenPadding)
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
                }
            }
        }
        .task {
            #if DEBUG
            applyDebugStartScreen()
            #endif
        }
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
