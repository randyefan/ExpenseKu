//
//  SpendEntityView.swift
//  ExpenseKu
//
//  The drill-in behind an Insights breakdown row (Flow K, option A; Flow O): which
//  expenses make up a category's or an account's total. Pushed seeded with the page's
//  window and plan filter, then free to re-scope, narrow to the other dimension, and
//  filter by plan on its own (docs/prd/insights-drill-in.md).
//
//  The fetch is unbounded for PersonExpensesView's reason: a window the owner can
//  change here cannot also bound a `@Query`, so it is sliced in memory, and a new
//  window rolls the figures instead of remounting the screen.
//

import SwiftUI
import SwiftData

struct SpendEntityView: View {
    let route: SpendEntityRoute

    @Environment(\.modelContext) private var context
    @Environment(\.calendar) private var calendar

    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \CyclePlan.cycleStart) private var plans: [CyclePlan]

    @State private var window: InsightsWindow
    @State private var planFilter: PlanFilter?
    @State private var narrowing: SpendSubject?
    @State private var now = Date.now
    @State private var editing: Expense?
    @State private var growth = ChartGrowth()

    init(route: SpendEntityRoute) {
        self.route = route
        _window = State(initialValue: route.window)
        _planFilter = State(initialValue: route.planFilter)
    }

    var body: some View {
        let payday = Payday.current
        let identity = SpendEntityIdentity.resolve(route.subject, in: context)
        let origins = PlanOrigins(plans: plans, payday: payday, calendar: calendar)
        let detail = SpendEntityDetail(
            expenses: expenses,
            subject: route.subject,
            narrowing: narrowing,
            dateRange: window.range(now: now, payday: payday, calendar: calendar),
            planFilter: planFilter,
            origins: origins
        )

        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                if let identity {
                    content(identity: identity, detail: detail, payday: payday)
                } else {
                    EmptyStateView(
                        title: route.subject.isCategory ? "Category Removed" : "Account Removed",
                        systemImage: route.subject.isCategory ? "tag.slash" : "creditcard.trianglebadge.exclamationmark",
                        message: route.subject.isCategory
                            ? "This category was deleted, so there is nothing left to show here."
                            : "This account was deleted, so there is nothing left to show here."
                    )
                    .frame(minHeight: 320)
                }
            }
            .padding(.vertical, Metric.screenPadding)
            .motion(Motion.settle, value: detail.listed.count)
        }
        .safeAreaInset(edge: .bottom) {
            if let planFilter {
                PlanFilterPill(filter: planFilter) { self.planFilter = nil }
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .motion(Motion.settle, value: planFilter)
        .environment(\.planOrigins, origins)
        .background(Theme.bg)
        .navigationTitle(identity?.name ?? (route.subject.isCategory ? "Category" : "Account"))
        .navigationBarTitleDisplayMode(.inline)
        .growsOnAppear(growth, trigger: window)
        .sensoryFeedback(.selection, trigger: window)
        .sensoryFeedback(.selection, trigger: planFilter)
        .sheet(item: $editing) { expense in
            NavigationStack {
                ExpenseEditorView(editing: expense, onFinish: { editing = nil })
            }
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func content(identity: SpendEntityIdentity, detail: SpendEntityDetail, payday: Int) -> some View {
        let windowLabel = window.label(now: now, payday: payday, calendar: calendar)
        let focus = narrowing.flatMap { SpendEntityIdentity.resolve($0, in: context) }

        SpendEntityHeader(
            identity: identity,
            total: detail.total,
            count: detail.listed.count,
            windowLabel: windowLabel,
            share: detail.share,
            planFilter: planFilter,
            growth: growth.factor
        )
        .padding(.horizontal, Metric.screenPadding)
        .reveal(0)

        PeriodFilterChips(selection: presetBinding, label: InsightsWindow.chipLabel)
            .reveal(1)

        if window.preset == .payPeriod {
            PayPeriodMenuRow(
                cycles: PayPeriodChoices.cycles(oldestExpense: expenses.last?.date, now: now,
                                                payday: payday, calendar: calendar),
                selected: window.payCycle(now: now, payday: payday, calendar: calendar),
                onSelect: select
            )
            .padding(.horizontal, Metric.screenPadding)
            .motionTransition(.rise)
        }

        if PlanFilter.showsLegend(for: detail.split, filter: planFilter) {
            SpendSplitCard(subjectName: identity.name, split: detail.split, filter: planFilter) { half in
                planFilter = PlanFilter.tapping(half, on: planFilter)
            }
            .padding(.horizontal, Metric.screenPadding)
            .reveal(2)
        }

        if let focus {
            HStack(spacing: 8) {
                Text("Narrowed to")
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                FocusChip(title: focus.name, systemImage: focus.symbol,
                          tint: Theme.categoryTint(hex: focus.colorHex, seed: focus.name)) {
                    narrowing = nil
                }
            }
            .padding(.horizontal, Metric.screenPadding)
            .motionTransition(.rise)
        }

        if !detail.breakdown.isEmpty {
            SpendBreakdownCard(
                title: "\(identity.name) by \(route.subject.isCategory ? "account" : "category")",
                rows: detail.breakdown,
                narrowing: narrowing
            ) { subject in
                narrowing = narrowing == subject ? nil : subject
            }
            .padding(.horizontal, Metric.screenPadding)
            .reveal(3)
        }

        if detail.listed.isEmpty {
            EmptyStateView(
                title: SpendEntityDetail.emptyTitle(planFilter: planFilter),
                systemImage: identity.symbol,
                message: SpendEntityDetail.emptyMessage(
                    name: [identity.name, focus?.name].compactMap { $0 }.joined(separator: " · "),
                    planFilter: planFilter,
                    windowPhrase: window.phrase(now: now, payday: payday, calendar: calendar)
                )
            )
            .frame(minHeight: 260)
            .motionTransition(.rise)
        } else {
            ForEach(expenseDayGroups(detail.listed, calendar: calendar).enumerated(), id: \.element.id) { index, group in
                PersonDayCard(group: group, calendar: calendar) { expense in
                    editing = expense
                }
                .padding(.horizontal, Metric.screenPadding)
                .reveal(index + 4, trigger: window)
            }
        }
    }

    /// A new chip clears the plan filter (decision 13) and the narrowing stays (D5).
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
        guard window.select(cycle) else { return }
        now = .now
        planFilter = nil
    }
}
