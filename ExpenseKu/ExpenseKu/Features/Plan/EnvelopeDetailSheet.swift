//
//  EnvelopeDetailSheet.swift
//  ExpenseKu
//
//  An envelope's detail (docs/prd/envelope-detail.md, frames T2–T6): the card, then every
//  expense the envelope counts — its own cycle by day, unheaded, then one "Paid early ·
//  ‹cycle›" section per earlier cycle. `EnvelopeDetail` decides what is listed, by asking
//  `EnvelopeClaims`; this view only draws it.
//
//  Rows carry no envelope tag: every one of them is in this envelope.
//
//  Anything that needs another sheet goes out as an `EnvelopeDetailAction`. ExpensesView
//  closes this sheet, opens the other, and brings this one back after (§4.6). A delete
//  needs no sheet, so it happens here and the list and card follow at once.
//

import SwiftUI
import SwiftData

struct EnvelopeDetailSheet: View {
    let envelope: PlanItem
    let cycle: PayCycle
    let onAction: (EnvelopeDetailAction) -> Void

    @Query private var expenses: [Expense]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let calendar = Calendar.current

    init(envelope: PlanItem, cycle: PayCycle, onAction: @escaping (EnvelopeDetailAction) -> Void) {
        self.envelope = envelope
        self.cycle = cycle
        self.onAction = onAction
        let start = cycle.start
        let end = cycle.end
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end })
    }

    private var isLive: Bool { !envelope.isDeleted && envelope.modelContext != nil }

    var body: some View {
        NavigationStack {
            Group {
                if isLive {
                    content
                }
            }
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(isLive ? EnvelopeDetail.displayName(of: envelope) : "")
                            .font(.dsBody).bold()
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        Text(cycle.title(calendar: calendar))
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { onAction(.edit) }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: isLive) { _, live in
            if !live { dismiss() }
        }
    }

    private var content: some View {
        let envelopes = EnvelopeOffer.activeEnvelopes(of: envelope.plan)
        let progress = EnvelopeSpend.progress(envelopes: envelopes, cycleExpenses: expenses, cycle: cycle)
            .first { $0.itemID == envelope.persistentModelID }
            ?? EnvelopeProgress(itemID: envelope.persistentModelID, planned: envelope.amount, spent: 0)
        let detail = EnvelopeDetail(envelope: envelope,
                                    claims: EnvelopeClaims(envelopes: envelopes, cycle: cycle),
                                    cycleExpenses: expenses, payday: Payday.current, calendar: calendar)
        return List {
            Section {
                EnvelopeDetailCard(
                    envelope: envelope,
                    progress: progress,
                    paidEarlyCaption: progress.paidEarlyCaption(payday: Payday.current, calendar: calendar),
                    onAddExpense: { onAction(.addExpense) },
                    onMoveExpenses: { onAction(.moveExpenses) }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }

            if detail.isEmpty {
                Section {
                    EmptyStateView(title: EnvelopeDetail.emptyTitle(for: envelope),
                                   systemImage: "tray",
                                   message: EnvelopeDetail.emptyMessage(for: envelope))
                        .padding(.top, 32)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
            } else {
                ForEach(detail.sections) { section in
                    EnvelopeDetailSection(section: section, calendar: calendar,
                                          onOpen: { onAction(.openExpense($0)) },
                                          onDelete: delete)
                }
            }
        }
        .cycleLensList()
        .environment(\.showsPlanOriginTags, false)
        .environment(\.expenseRowActions, ExpenseRowActions(
            move: { onAction(.move($0)) },
            delete: { delete([$0]) }
        ))
    }

    private func delete(_ doomed: [Expense]) {
        doomed.forEach(context.delete)
        try? context.save()
    }
}
