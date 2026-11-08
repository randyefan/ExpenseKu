//
//  ExpensesView+Plan.swift
//  ExpenseKu
//
//  What the Plan lens's actions actually do, and the sheets they raise.
//
//  It lives here rather than in ExpensesView so the home screen's own file stays about
//  the home screen. All of it runs *above* the `.id(LensKey(cycle:lens:))` that rebuilds
//  the lens on every page and lens switch — a sheet presented from inside the lens
//  would be dismissed the moment the owner paged.
//

import SwiftUI
import SwiftData

extension ExpensesView {
    func perform(_ action: PlanAction, in contents: PlanContents) {
        markCarryOverSeen(contents)
        switch action {
        case .startPlan:
            startPlan()
        case .copyPlan:
            PlanCarryOver.makePlan(for: cycle, from: plans, in: context)

        case .addIncomeLine:
            planSheet = .newIncomeLine
        case .editIncomeLine(let line):
            planSheet = .editIncomeLine(line)
        case .toggleIncomeArrived(let line):
            line.hasArrived.toggle()
            try? context.save()

        case .addPlanItem:
            planSheet = .newPlanItem
        case .editPlanItem(let item):
            planSheet = .editPlanItem(item)
        case .openEnvelope(let envelope):
            envelopeSheet = .detail(envelope, cycle)
        case .moveExpenses(let envelope):
            envelopeSheet = .gather(envelope, cycle)
        case .addExpense(let envelope):
            newExpense = NewExpensePreset(
                envelope: envelope,
                date: EnvelopeAddDate.date(in: cycle, now: .now, calendar: .current)
            )
        case .tapDoneCheck(let item):
            tapDoneCheck(item)
        case .chooseFunding(let item, let entry):
            chooseFunding(entry, for: item)
        case .activateDormant(let item):
            // Waking a row is the same act as editing its amount, and the amount is
            // the only thing that makes it dormant — so it opens the editor rather
            // than silently un-dimming a Rp 0 row.
            item.carriedOver = false
            try? context.save()
            planSheet = .editPlanItem(item)
        case .toggleDormantSection:
            withAnimation(Motion.snap) { dormantExpanded.toggle() }

        case .openTransfer(let row):
            planSheet = .transfer(accountID: row.accountID)

        case .openReview:
            planSheet = .review
        case .lookBack:
            planSheet = .lookBack
        case .showFunded:
            fundedFilterCycle = cycle
            planSortChoice = nil
        case .clearFundedFilter:
            fundedFilterCycle = nil
        case .sortPlan(let sort):
            withAnimation(Motion.snap) { planSortChoice = PlanSortChoice(cycle: cycle, sort: sort) }
        }
    }

    /// L6's filter, only while it applies to the cycle on screen and has something
    /// to show. Paging away or paying the last Funded item ends it.
    func isFundedFilterOn(_ contents: PlanContents) -> Bool {
        fundedFilterCycle == cycle && !contents.funded.isEmpty
    }

    var planSort: PlanSort {
        guard let planSortChoice, planSortChoice.cycle == cycle else { return .amount }
        return planSortChoice.sort
    }

    /// The carry-over notice has done its job once the owner starts adjusting, which
    /// is what it asks them to do.
    private func markCarryOverSeen(_ contents: PlanContents) {
        guard let plan = contents.plan, !plan.carryOverNoticeSeen,
              plan.copiedFromCycleStart != nil else { return }
        plan.carryOverNoticeSeen = true
    }

    // MARK: - Writes

    private func startPlan() {
        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(plan)
        try? context.save()
    }

    /// What the lead control means depends on the row's state, which is
    /// DoneCheckTap's job. Ticking opens the confirmation sheet; un-ticking asks
    /// before deleting the expense it created. A Menu reports through
    /// `chooseFunding` instead and never lands here.
    private func tapDoneCheck(_ item: PlanItem) {
        switch DoneCheckTap.of(item) {
        case .confirmDone:
            planSheet = .confirmDone(item)
        case .untick:
            planConfirmation = .untick(item)
        case .menu, .none:
            break
        }
    }

    /// Funded is the owner's report, never a balance. The transfer line reads it, so
    /// its tick follows (partial-transfer.md §5.1).
    private func chooseFunding(_ entry: FundMenuEntry, for item: PlanItem) {
        guard item.apply(entry) else {
            planSheet = .confirmDone(item)
            return
        }
        try? context.save()
    }

    /// I4. Un-ticking deletes the Expense the tick created. Unlinking without deleting
    /// was rejected: the orphan would keep counting in its envelope and in every cycle
    /// total (§7.3).
    func confirmUntick(_ item: PlanItem) {
        guard let expense = item.linkedExpense else { return }
        context.delete(expense)
        try? context.save()
    }

    /// I7. The Expense survives and only the link is dropped — ADR-0001 nullify, which
    /// the relationship already does. Deleting the item is the whole operation.
    func confirmDeleteItem(_ item: PlanItem) {
        context.delete(item)
        try? context.save()
    }

    /// AH2. The plan's own parts cascade with it; every link from outside it nullifies,
    /// so no Expense goes (clear-plan.md §4.3).
    func confirmClearPlan(_ plan: CyclePlan) {
        context.delete(plan)
        try? context.save()
    }

    var canClearPlan: Bool {
        lens == .plan && PlanClearing.canClear(PlanLookup.plan(for: cycle, in: plans), cycle: cycle,
                                               today: .now, payday: payday, calendar: calendar)
    }

    func requestClearPlan() {
        guard let plan = PlanLookup.plan(for: cycle, in: plans) else { return }
        planConfirmation = .clearPlan(plan)
    }

    /// The month Copy from names: the latest plan before this cycle, gaps skipped.
    func copySourceMonth(_ contents: PlanContents) -> String? {
        guard !contents.hasPlan, let source = PlanLookup.source(before: cycle, in: plans) else { return nil }
        return LookBackCopy.month(of: PayCycle.containing(source.cycleStart, payday: payday, calendar: calendar),
                                  calendar: calendar)
    }
}

// MARK: - Presentation

extension View {
    /// The plan's editors, as one `.sheet(item:)`.
    func planSheet(
        _ sheet: Binding<PlanSheet?>,
        confirmation: Binding<PlanConfirmation?>,
        contents: PlanContents,
        plans: [CyclePlan],
        expenses: [Expense],
        payday: Int,
        today: Date,
        onOpenExpense: @escaping (Expense) -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        self.sheet(item: sheet, onDismiss: onDismiss) { which in
            PlanSheetContent(
                which: which,
                contents: contents,
                plans: plans,
                expenses: expenses,
                payday: payday,
                today: today,
                onOpenExpense: { expense in
                    sheet.wrappedValue = nil
                    onOpenExpense(expense)
                },
                onRequestDelete: { item in
                    sheet.wrappedValue = nil
                    confirmation.wrappedValue = .deleteItem(item)
                },
                onFinish: { sheet.wrappedValue = nil }
            )
            .presentationBackground(Theme.bg)
        }
    }

    /// The plan's destructive confirmations (frames I4, I7 and AH2).
    ///
    /// An `.alert`, not a `.confirmationDialog`: the design draws a centred dialog, and
    /// each of these has a sentence of consequence to read before the owner taps —
    /// which an action sheet sliding up from the bottom buries under the thumb.
    ///
    /// It is attached a level above the editors on purpose. Several presentation
    /// modifiers stacked on one view do not all fire; this one was silently swallowed
    /// behind the four sheets ExpensesView already carries, and the tap did nothing at
    /// all until it moved.
    func planConfirmation(
        _ confirmation: Binding<PlanConfirmation?>,
        onUntick: @escaping (PlanItem) -> Void,
        onDeleteItem: @escaping (PlanItem) -> Void,
        onClearPlan: @escaping (CyclePlan) -> Void
    ) -> some View {
        self.alert(
            confirmationTitle(confirmation.wrappedValue),
            isPresented: Binding(
                get: { confirmation.wrappedValue != nil },
                set: { if !$0 { confirmation.wrappedValue = nil } }
            ),
            presenting: confirmation.wrappedValue
        ) { pending in
            switch pending {
            case .untick(let item):
                Button("Delete expense", role: .destructive) { onUntick(item) }
            case .deleteItem(let item):
                Button("Delete plan item", role: .destructive) { onDeleteItem(item) }
            case .clearPlan(let plan):
                Button("Clear Plan", role: .destructive) { onClearPlan(plan) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { pending in
            Text(confirmationBody(pending))
        }
    }
}

private func confirmationTitle(_ pending: PlanConfirmation?) -> String {
    switch pending {
    case .untick: "Delete the expense too?"
    case .deleteItem: "Delete this plan item?"
    case .clearPlan(let plan):
        PlanClearing.title(month: LookBackCopy.month(
            of: PayCycle.containing(plan.cycleStart, payday: Payday.current), calendar: .current))
    case nil: ""
    }
}

private func confirmationBody(_ pending: PlanConfirmation) -> String {
    switch pending {
    case .untick(let item):
        guard let expense = item.linkedExpense else { return "" }
        return PlanCopy.untickBody(amount: expense.amount, date: expense.date)
    case .deleteItem(let item):
        let expense = item.linkedExpense
        let setAsides = SetAside.sources(into: item)
        return PlanCopy.deleteItemBody(amount: expense?.amount, date: expense?.date,
                                       assignedCount: item.assignedExpenses?.count ?? 0,
                                       setAsideCount: setAsides.count,
                                       setAsideMonths: SetAside.months(of: setAsides, payday: Payday.current,
                                                                       calendar: .current))
    case .clearPlan(let plan):
        return PlanClearing.message(PlanClearing.reach(of: plan, payday: Payday.current, calendar: .current))
    }
}

/// Resolves a `PlanSheet` to its view. A separate type so the `.sheet(item:)` closure
/// above stays readable, and so each editor is built only when it is presented.
private struct PlanSheetContent: View {
    let which: PlanSheet
    let contents: PlanContents
    let plans: [CyclePlan]
    let expenses: [Expense]
    let payday: Int
    let today: Date
    let onOpenExpense: (Expense) -> Void
    let onRequestDelete: (PlanItem) -> Void
    let onFinish: () -> Void

    var body: some View {
        if let plan = contents.plan {
            switch which {
            case .newPlanItem:
                PlanItemEditorView(plan: plan, editing: nil, plans: plans,
                                   onFinish: onFinish, onDelete: onRequestDelete)
            case .editPlanItem(let item):
                PlanItemEditorView(plan: plan, editing: item, plans: plans,
                                   onFinish: onFinish, onDelete: onRequestDelete)
            case .newIncomeLine:
                IncomeLineEditorView(plan: plan, editing: nil, onFinish: onFinish)
            case .editIncomeLine(let line):
                IncomeLineEditorView(plan: plan, editing: line, onFinish: onFinish)
            case .transfer(let accountID):
                if let row = contents.transfers.first(where: { $0.accountID == accountID }) {
                    TransferSheet(
                        plan: plan,
                        row: row,
                        account: (plan.items ?? []).compactMap(\.account)
                            .first { $0.persistentModelID == accountID },
                        items: contents.activeItems.filter { $0.account?.persistentModelID == accountID },
                        onFinish: onFinish
                    )
                }
            case .confirmDone(let item):
                PlanDoneSheet(item: item, today: today, onFinish: onFinish)
            case .review:
                AutoReviewSheet(
                    review: contents.review,
                    items: contents.activeItems,
                    onOpenExpense: onOpenExpense,
                    onFinish: onFinish
                )
            case .lookBack:
                LookBackSheet(plan: plan, onScreen: contents.cycle, plans: plans, expenses: expenses,
                              payday: payday, calendar: .current, onFinish: onFinish)
            }
        }
    }
}
