//
//  LookBackSheet.swift
//  ExpenseKu
//
//  What an earlier cycle had that the plan on screen does not, each addable in one tap
//  (docs/prd/look-back.md, frames AB2–AB6).
//
//  The marks and the first derivation of each page live here, in the sheet's own state,
//  and die with it: reopening lists only what is still missing (§8). The sheet is modal,
//  so the plan behind it cannot page while they are alive.
//

import SwiftUI
import SwiftData

struct LookBackSheet: View {
    let plan: CyclePlan
    let onScreen: PayCycle
    let plans: [CyclePlan]
    let expenses: [Expense]
    let payday: Int
    let calendar: Calendar
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var reviewed: PayCycle
    @State private var snapshots: [Date: LookBack] = [:]
    @State private var marks: [Date: [LookBackRowID: LookBackMark]] = [:]

    init(plan: CyclePlan, onScreen: PayCycle, plans: [CyclePlan], expenses: [Expense],
         payday: Int, calendar: Calendar, onFinish: @escaping () -> Void) {
        self.plan = plan
        self.onScreen = onScreen
        self.plans = plans
        self.expenses = expenses
        self.payday = payday
        self.calendar = calendar
        self.onFinish = onFinish
        _reviewed = State(initialValue: onScreen.previous(payday: payday, calendar: calendar))
    }

    var body: some View {
        let live = LookBack.of(reviewed, here: plan, plans: plans, expenses: expenses,
                               payday: payday, calendar: calendar)
        let snapshot = snapshots[reviewed.start] ?? live
        let pageMarks = marks[reviewed.start] ?? [:]
        let marked = Set(pageMarks.keys)
        let planRows = LookBackDisplay.rows(snapshot: snapshot.planRows, live: live.planRows, marked: marked)
        let categoryRows = LookBackDisplay.rows(snapshot: snapshot.categoryRows, live: live.categoryRows,
                                                marked: marked)
        let month = LookBackCopy.month(of: reviewed, calendar: calendar)
        let planMonth = LookBackCopy.month(of: onScreen, calendar: calendar)

        NavigationStack {
            List {
                Section {
                    Text(LookBackCopy.lead(planMonth: planMonth))
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                }

                if planRows.isEmpty && categoryRows.isEmpty {
                    Section {
                        EmptyStateView(
                            title: LookBackCopy.emptyTitle,
                            systemImage: "checkmark.circle",
                            message: LookBackCopy.emptyMessage(month, planMonth: planMonth)
                        )
                        .padding(.top, 48)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    planSection(planRows, hadPlan: live.hadPlan, marks: pageMarks, month: month, planMonth: planMonth)
                    if !categoryRows.isEmpty {
                        outsideSection(categoryRows, live: live, marks: pageMarks, month: month, planMonth: planMonth)
                    }
                }
            }
            .cycleLensList()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { pager }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.string(.done), action: onFinish).tint(Theme.accentText)
                }
            }
            .task(id: reviewed) {
                if snapshots[reviewed.start] == nil { snapshots[reviewed.start] = live }
            }
        }
    }

    private var pager: some View {
        HStack(spacing: 10) {
            Button(AppLocalization.string(.previousCycle), systemImage: "chevron.left") { page(to: reviewed.previous(payday: payday, calendar: calendar)) }
                .disabled(!CyclePaging.canGoBack(from: reviewed, oldestExpense: expenses.map(\.date).min(),
                                                 oldestPlanStart: PlanLookup.oldestStart(in: plans)))
            Text(LookBackCopy.title(of: reviewed, onScreen: onScreen, calendar: calendar))
                .font(.dsHeadline)
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
            Button(AppLocalization.string(.nextCycle), systemImage: "chevron.right") { page(to: reviewed.next(payday: payday, calendar: calendar)) }
                .disabled(!LookBack.canGoForward(from: reviewed, onScreen: onScreen))
        }
        .labelStyle(.iconOnly)
        .tint(Theme.text)
    }

    @ViewBuilder
    private func planSection(_ rows: [LookBackPlanRow], hadPlan: Bool, marks: [LookBackRowID: LookBackMark],
                             month: String, planMonth: String) -> some View {
        if !hadPlan {
            Section {
                Text(LookBackCopy.noPlan(month))
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
                    .listRowBackground(Theme.card)
            } header: {
                sectionHeader(LookBackCopy.planSection(month))
            }
        } else if !rows.isEmpty {
            Section {
                ForEach(rows) { row in
                    PlanListRow {
                        LookBackPlanRowView(
                            row: row,
                            mark: marks[row.id],
                            planMonth: planMonth,
                            onAct: { act(on: row) },
                            onUndo: { undo(row.id) }
                        )
                    }
                }
            } header: {
                sectionHeader(LookBackCopy.planSection(month))
            }
        }
    }

    private func outsideSection(_ rows: [LookBackCategoryRow], live: LookBack, marks: [LookBackRowID: LookBackMark],
                                month: String, planMonth: String) -> some View {
        Section {
            ForEach(rows) { row in
                PlanListRow {
                    LookBackCategoryRowView(
                        row: row,
                        mark: marks[row.id],
                        month: month,
                        planMonth: planMonth,
                        envelopes: EnvelopeOffer.activeEnvelopes(of: plan),
                        onNew: { kind in planCategory(row, as: kind) },
                        onAddTo: { envelope in add(row, to: envelope) },
                        onUndo: { undo(row.id) }
                    )
                }
            }
        } header: {
            VStack(alignment: .leading, spacing: 2) {
                sectionHeader(LookBackCopy.outsideSection(month, total: live.outsideTotal))
                if live.paidEarlyTotal > 0 {
                    Text(LookBackCopy.paidEarlyExcluded(live.paidEarlyTotal))
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        SectionHeaderText(title)
    }

    // MARK: - Writes

    private func page(to cycle: PayCycle) {
        withAnimation(Motion.snap) { reviewed = cycle }
    }

    private func act(on row: LookBackPlanRow) {
        switch row.action {
        case .add:
            record(LookBackWrites.copy(row.source, into: plan, in: context), for: row.id)
        case .wake(let dormant):
            record(LookBackWrites.wake(dormant, to: row.source.amount, in: context), for: row.id)
        }
    }

    private func planCategory(_ row: LookBackCategoryRow, as kind: PlanItemKind) {
        guard let category = row.category else { return }
        record(LookBackWrites.newItem(kind, for: category, amount: row.total, in: plan, context: context), for: row.id)
    }

    private func add(_ row: LookBackCategoryRow, to envelope: PlanItem) {
        guard let category = row.category else { return }
        record(LookBackWrites.add(category, to: envelope, in: context), for: row.id)
    }

    private func record(_ mark: LookBackMark, for id: LookBackRowID) {
        withAnimation(Motion.snap) { marks[reviewed.start, default: [:]][id] = mark }
    }

    private func undo(_ id: LookBackRowID) {
        guard let mark = marks[reviewed.start]?[id] else { return }
        LookBackWrites.undo(mark, in: context)
        withAnimation(Motion.snap) { marks[reviewed.start]?[id] = nil }
    }
}
