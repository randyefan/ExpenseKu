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
        case .tapDoneCheck(let item):
            tapDoneCheck(item)
        case .activateDormant(let item):
            // Waking a row is the same act as editing its amount, and the amount is
            // the only thing that makes it dormant — so it opens the editor rather
            // than silently un-dimming a Rp 0 row.
            item.carriedOver = false
            try? context.save()
            planSheet = .editPlanItem(item)
        case .toggleDormantSection:
            withAnimation(Motion.snap) { dormantExpanded.toggle() }

        case .toggleTransferred(let row):
            toggleTransferred(row, in: contents)
        case .editAdjustment(let row):
            planSheet = .transferAdjustment(accountID: row.accountID)

        case .openReview:
            planSheet = .review
        }
    }

    /// Fills a forward cycle's plan from the previous one, on arrival (PRD §7.2).
    ///
    /// Only ever **forward**, never for a cycle older than the newest plan. Carry-over
    /// is a write, and paging back through history to look at what happened must not
    /// silently manufacture plans for cycles the owner never planned.
    func carryOverIfNeeded() {
        guard lens == .plan,
              PlanLookup.plan(for: cycle, in: plans) == nil,
              let newest = plans.map(\.cycleStart).max(),
              cycle.start > newest else { return }
        PlanCarryOver.makePlan(for: cycle, from: plans, in: context)
    }

    /// The carry-over notice has done its job once the owner starts adjusting, which
    /// is what it asks them to do.
    private func markCarryOverSeen(_ contents: PlanContents) {
        guard let plan = contents.plan, !plan.carryOverNoticeSeen,
              plan.copiedFromCycleStart != nil else { return }
        plan.carryOverNoticeSeen = true
    }

    // MARK: - Writes

    /// Only reachable for the owner's very first cycle: every later one arrives by
    /// carry-over (PRD §7.2).
    private func startPlan() {
        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(plan)
        try? context.save()
    }

    /// What the lead control means depends on the row's state, which is
    /// DoneCheckState's job. Ticking opens the confirmation sheet; un-ticking asks
    /// before deleting the expense it created.
    private func tapDoneCheck(_ item: PlanItem) {
        switch DoneCheckState.state(for: item) {
        case .todo:
            planSheet = .confirmDone(item)
        case .done, .autoPosted:
            planConfirmation = .untick(item)
        case .auto, .envelope:
            break
        }
    }

    /// The TransferLine is created on first use — until the owner ticks or adjusts
    /// something there is nothing about that account worth storing.
    private func toggleTransferred(_ row: TransferRow, in contents: PlanContents) {
        guard let plan = contents.plan else { return }
        if let existing = (plan.transferLines ?? []).first(
            where: { $0.account?.persistentModelID == row.accountID }
        ) {
            existing.hasTransferred.toggle()
        } else {
            let account = (plan.items ?? [])
                .compactMap(\.account)
                .first { $0.persistentModelID == row.accountID }
            context.insert(TransferLine(account: account, hasTransferred: true, plan: plan))
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
}

// MARK: - Presentation

extension View {
    /// The plan's editors, as one `.sheet(item:)`.
    func planSheet(
        _ sheet: Binding<PlanSheet?>,
        confirmation: Binding<PlanConfirmation?>,
        contents: PlanContents,
        plans: [CyclePlan],
        today: Date,
        onOpenExpense: @escaping (Expense) -> Void
    ) -> some View {
        self.sheet(item: sheet) { which in
            PlanSheetContent(
                which: which,
                contents: contents,
                plans: plans,
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
        }
    }

    /// The two destructive confirmations (frames I4 and I7).
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
        onDeleteItem: @escaping (PlanItem) -> Void
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
        return PlanCopy.deleteItemBody(amount: expense?.amount, date: expense?.date)
    }
}

/// Resolves a `PlanSheet` to its view. A separate type so the `.sheet(item:)` closure
/// above stays readable, and so each editor is built only when it is presented.
private struct PlanSheetContent: View {
    let which: PlanSheet
    let contents: PlanContents
    let plans: [CyclePlan]
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
            case .transferAdjustment(let accountID):
                if let row = contents.transfers.first(where: { $0.accountID == accountID }) {
                    TransferAdjustmentEditorView(
                        plan: plan,
                        row: row,
                        account: (plan.items ?? []).compactMap(\.account)
                            .first { $0.persistentModelID == accountID },
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
            }
        }
    }
}
