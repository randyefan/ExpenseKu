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

    @Query private var expenses: [Expense]
    @State private var range: DateRangeFilter = .thisYear
    @State private var payday: Int = Payday.current
    @State private var path: [Destination] = []

    private var dateRange: ClosedRange<Date>? {
        range.range(payday: payday)
    }

    private var byCategory: [CategorySpend] {
        SpendSummary.byCategory(from: expenses, dateRange: dateRange)
    }

    private var overTime: [PeriodSpend] {
        SpendSummary.overTime(from: expenses, dateRange: dateRange, granularity: .month)
    }

    private var byAccount: [AccountSpend] {
        SpendSummary.byAccount(from: expenses, dateRange: dateRange)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Metric.cardGap) {
                    filterChips

                    if range == .payPeriod {
                        HStack {
                            Label("Payday", systemImage: "calendar")
                                .font(.dsBody)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            PaydayStepper(payday: $payday, accessibilityTitle: "Payday")
                        }
                        .cardStyle()
                        .onChange(of: payday) { _, newValue in Payday.current = newValue }
                    }

                    chartCard("Spend by Category") {
                        if byCategory.isEmpty { emptyChart } else { SpendByCategoryChart(data: byCategory) }
                    }

                    chartCard("Spend by Account") {
                        if byAccount.isEmpty { emptyChart } else { SpendByAccountChart(data: byAccount) }
                    }

                    chartCard("Spend over Time", accessory: AnyView(byMonthTag)) {
                        if overTime.isEmpty { emptyChart } else { SpendOverTimeChart(data: overTime, granularity: .month) }
                    }

                    leaderboardLink
                }
                .padding(Metric.screenPadding)
            }
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
            switch DebugLaunch.startScreen {
            case "leaderboard":
                path = [.leaderboard]
            case "person-detail":
                // Drive Insights → leaderboard → detail for the top-ranked companion,
                // so the pushed screen is screenshot-able with realistic data.
                if let person = PeopleLeaderboard.ranked(from: expenses).first?.person {
                    let route = PersonExpensesRoute(person: person, category: nil,
                                                    account: nil, range: .allTime)
                    path = [.leaderboard, .personExpenses(route)]
                } else {
                    path = [.leaderboard]
                }
            default:
                break
            }
            #endif
        }
    }

    // MARK: - Period filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DateRangeFilter.allCases) { filter in
                    let selected = range == filter
                    Button {
                        range = filter
                    } label: {
                        Text(filter.label)
                            .font(.dsSubhead).fontWeight(.semibold)
                            .foregroundStyle(selected ? .white : Theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(selected ? Theme.accent : Theme.card)
                                    .overlay(Capsule().stroke(Theme.hairline, lineWidth: selected ? 0 : 1))
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Card scaffolding

    private var byMonthTag: some View {
        Text("By month")
            .font(.dsCaption).fontWeight(.semibold)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Theme.textSecondary.opacity(0.1), in: Capsule())
    }

    private func chartCard<Content: View>(
        _ title: String,
        accessory: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderText(title)
                Spacer()
                if let accessory { accessory }
            }
            content()
        }
        .cardStyle()
    }

    private var emptyChart: some View {
        Text("No spending in this period.")
            .font(.dsSubhead)
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private var leaderboardLink: some View {
        NavigationLink(value: Destination.leaderboard) {
            HStack(spacing: 12) {
                CategoryIcon(name: "people", systemImage: "person.2.fill", size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("People leaderboard")
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                    Text("Who you spend with")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.dsSubhead.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
