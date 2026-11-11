//
//  PaidElsewhereSheet.swift
//  ExpenseKu
//
//  One Account of an envelope's PAID ELSEWHERE opened (docs/prd/paid-elsewhere.md §4.5,
//  frames AE2–AE6): its expenses still to move, all chosen, the figure to move now, and
//  what is already moved — the transfer sheet's pattern (partial-transfer.md §6).
//
//  It reads the envelope's expenses itself, the way the detail does, so a mark cleared
//  with "Not moved yet" puts the expense back under To move at once — unchosen, because
//  the choice was made before it came back.
//

import SwiftUI
import SwiftData

struct PaidElsewhereSheet: View {
    let envelope: PlanItem
    let cycle: PayCycle
    let account: Account

    @Query private var expenses: [Expense]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var chosen: Set<PersistentIdentifier>?
    private let calendar = Calendar.current

    init(envelope: PlanItem, cycle: PayCycle, account: Account) {
        self.envelope = envelope
        self.cycle = cycle
        self.account = account
        let start = cycle.start
        let end = cycle.end
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end })
    }

    private var row: PaidElsewhereRow? {
        guard !envelope.isDeleted, envelope.modelContext != nil else { return nil }
        let detail = EnvelopeDetail(envelope: envelope,
                                    claims: EnvelopeClaims(envelopes: EnvelopeOffer.activeEnvelopes(of: envelope.plan),
                                                           cycle: cycle),
                                    cycleExpenses: expenses, payday: Payday.current, calendar: calendar)
        return PaidElsewhere(envelope: envelope, expenses: detail.expenses, calendar: calendar).row(for: account)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let row {
                    content(PaidElsewherePick(row: row, chosen: chosen ?? PaidElsewherePick.initialChoice(for: row)))
                }
            }
            .background(Theme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.string(.close), systemImage: "xmark") { dismiss() }
                        .tint(Theme.text)
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        AccountPlate(style: AccountPlateStyle(account: account))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(appLocalized: .moveFrom(envelope.account?.name ?? ""))
                                .font(.dsHeadline).bold()
                                .foregroundStyle(Theme.text)
                            Text(appLocalized: .to(account.name))
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            if chosen == nil, let row { chosen = PaidElsewherePick.initialChoice(for: row) }
        }
        .onChange(of: row == nil) { _, isGone in
            if isGone { dismiss() }
        }
    }

    private func content(_ pick: PaidElsewherePick) -> some View {
        List {
            if pick.toMove.isEmpty {
                Section {
                    Text(pick.allMovedMessage)
                        .font(.dsBody)
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 4, trailing: 4))
                }
            } else {
                Section {
                    ForEach(pick.toMove) { member in
                        PlanListRow {
                            PaidElsewherePickRow(member: member, isChosen: pick.isChosen(member)) {
                                toggle(member, in: pick)
                            }
                        }
                    }
                } header: {
                    sectionHeader(pick.toMoveTitle)
                }
            }

            Section {
                PlanListRow {
                    TransferFigureRow(title: pick.figureTitle, amount: pick.figure, isNow: !pick.toMove.isEmpty)
                }
            }

            if !pick.toMove.isEmpty {
                Section {
                    TransferRecordButton(title: pick.recordTitle, isEnabled: pick.canRecord) {
                        record(pick)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                }
            }

            if !pick.alreadyMoved.isEmpty {
                Section {
                    ForEach(pick.alreadyMoved) { member in
                        PlanListRow {
                            PaidElsewhereMovedRow(member: member) { undo(member) }
                        }
                    }
                } header: {
                    sectionHeader(pick.alreadyMovedTitle)
                }
            }
        }
        .cycleLensList()
    }

    private func sectionHeader(_ title: String) -> some View {
        SectionHeaderText(title)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
    }

    // MARK: - Writes

    private func toggle(_ member: PaidElsewhereMember, in pick: PaidElsewherePick) {
        var next = pick.chosen
        if next.contains(member.id) {
            next.remove(member.id)
        } else {
            next.insert(member.id)
        }
        chosen = next
    }

    private func record(_ pick: PaidElsewherePick) {
        for member in pick.chosenMembers {
            expense(for: member.id)?.isMovedFromEnvelope = true
        }
        try? context.save()
        dismiss()
    }

    private func undo(_ member: PaidElsewhereMember) {
        expense(for: member.id)?.isMovedFromEnvelope = false
        try? context.save()
    }

    private func expense(for id: PersistentIdentifier) -> Expense? {
        context.model(for: id) as? Expense
    }
}
