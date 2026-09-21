//
//  PersonExpensesView.swift
//  ExpenseKu
//
//  The drill-down behind a People-leaderboard row: "which expenses make up my total
//  with this person." Pushed onto the Insights nav stack, seeded with the filters
//  that were active when the row was tapped — and then free to re-scope, because the
//  question "how much with them lately?" is asked here, not back on the leaderboard.
//
//  Display-only; aggregation lives in the pure PeopleLeaderboard layer. Attribution
//  is unchanged: the full amount is credited to each companion, so an unfiltered
//  total still mirrors the row exactly.
//

import SwiftUI
import SwiftData

struct PersonExpensesView: View {
    let route: PersonExpensesRoute

    @Environment(\.modelContext) private var context
    @Environment(\.calendar) private var calendar

    /// Unbounded on purpose. `@Query` fixes its predicate at init, so a window the
    /// owner can change on this screen cannot also bound the fetch; the window is
    /// sliced in memory instead. Arriving from an All-time leaderboard already cost
    /// this much, and in exchange changing the window needs no remount — the total
    /// rolls to its new value rather than blinking.
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \CyclePlan.cycleStart) private var plans: [CyclePlan]

    @State private var range: DateRangeFilter
    @State private var editing: Expense?
    @State private var growth = ChartGrowth()

    init(route: PersonExpensesRoute) {
        self.route = route
        _range = State(initialValue: route.range)
    }

    var body: some View {
        let person = route.person(in: context)
        let category = route.category(in: context)
        let account = route.account(in: context)
        let dateRange = range.range(payday: Payday.current)
        let listed = person.map {
            PeopleLeaderboard.expenses(
                for: $0,
                from: expenses,
                category: category,
                account: account,
                dateRange: dateRange
            )
        } ?? []
        let total = listed.reduce(Decimal(0)) { $0 + $1.amount }
        let windowTotal = PeopleLeaderboard.total(
            from: expenses, category: category, account: account, dateRange: dateRange
        )
        let filterSummary = Self.filterSummary(category: category, account: account)

        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                if let person {
                    PersonSpendHeader(
                        name: person.name,
                        colorHex: person.colorHex,
                        total: total,
                        count: listed.count,
                        rangeLabel: range.label,
                        share: Self.share(of: total, in: windowTotal),
                        growth: growth.factor
                    )
                    .padding(.horizontal, Metric.screenPadding)
                    .reveal(0)

                    PeriodFilterChips(selection: $range)
                        .reveal(1)

                    if let filterSummary {
                        Text("Also filtered by \(filterSummary)")
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, Metric.screenPadding + 2)
                            .reveal(2)
                    }

                    if listed.isEmpty {
                        EmptyStateView(
                            title: "Nothing in This Window",
                            systemImage: "person.2.slash",
                            message: Self.emptyMessage(
                                name: person.name,
                                filterSummary: filterSummary,
                                range: range
                            )
                        )
                        .frame(minHeight: 300)
                        .motionTransition(.rise)
                    } else {
                        ForEach(Array(expenseDayGroups(listed, calendar: calendar).enumerated()),
                                id: \.element.id) { index, group in
                            PersonDayCard(group: group, calendar: calendar) { expense in
                                editing = expense
                            }
                            .padding(.horizontal, Metric.screenPadding)
                            .reveal(index + 3, trigger: range)
                        }

                        Text("Each shared expense credits \(person.name) the full amount.")
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Metric.screenPadding)
                            .padding(.top, 4)
                    }
                } else {
                    EmptyStateView(
                        title: "Person Removed",
                        systemImage: "person.slash",
                        message: "This person was deleted, so there is nothing left to show here."
                    )
                    .frame(minHeight: 320)
                }
            }
            .padding(.vertical, Metric.screenPadding)
            .motion(Motion.settle, value: listed.count)
        }
        .environment(\.planOrigins, PlanOrigins(plans: plans, payday: Payday.current, calendar: calendar))
        .background(Theme.bg)
        .navigationTitle(person?.name ?? "Person")
        .navigationBarTitleDisplayMode(.inline)
        .growsOnAppear(growth, trigger: range)
        .sensoryFeedback(.selection, trigger: range)
        .sheet(item: $editing) { expense in
            NavigationStack {
                ExpenseEditorView(editing: expense, onFinish: { editing = nil })
            }
            .presentationDragIndicator(.visible)
        }
    }

    /// This companion's slice of the window, or nil when nothing was spent in it —
    /// a share of zero is undefined, not 0%.
    static func share(of total: Decimal, in windowTotal: Decimal) -> Double? {
        guard windowTotal > 0 else { return nil }
        return (total as NSDecimalNumber).doubleValue / (windowTotal as NSDecimalNumber).doubleValue
    }

    /// "Food · Cash" when narrowed, nil when neither category nor account is set.
    static func filterSummary(category: Category?, account: Account?) -> String? {
        let parts = [category?.name, account?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func emptyMessage(name: String, filterSummary: String?, range: DateRangeFilter) -> String {
        if let filterSummary {
            return "\(name) has no expenses matching \(filterSummary) \(range.phrase)."
        }
        return "\(name) has no expenses \(range.phrase)."
    }
}
