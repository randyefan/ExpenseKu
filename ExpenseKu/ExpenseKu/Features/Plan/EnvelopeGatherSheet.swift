//
//  EnvelopeGatherSheet.swift
//  ExpenseKu
//
//  "Move expenses here…" (frame R4): starting from the envelope rather than the list,
//  tick the cycle's other expenses and move them in at once (envelope-assignment.md
//  §4.9). The target is chosen before anything is ticked, so no envelope picker
//  follows.
//

import SwiftUI
import SwiftData

struct EnvelopeGatherSheet: View {
    let envelope: PlanItem
    let cycle: PayCycle

    @Query private var cycleExpenses: [Expense]
    @State private var selection = ExpenseSelection()
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let calendar = Calendar.current

    init(envelope: PlanItem, cycle: PayCycle) {
        self.envelope = envelope
        self.cycle = cycle
        let start = cycle.start
        let end = cycle.end
        _cycleExpenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end })
    }

    private var name: String { envelope.name.isEmpty ? "Untitled" : envelope.name }

    var body: some View {
        let options = EnvelopeOptions(plan: envelope.plan, cycleExpenses: cycleExpenses)
        let candidates = EnvelopeGather.candidates(for: envelope, cycleExpenses: cycleExpenses,
                                                   claims: EnvelopeClaims(envelopes: options.envelopes))
        NavigationStack {
            Group {
                if candidates.isEmpty {
                    EmptyStateView(title: "Nothing to move",
                                   systemImage: "tray",
                                   message: "Everything this cycle is already in \(name).")
                } else {
                    List {
                        ForEach(expenseDayGroups(candidates, calendar: calendar)) { group in
                            Section {
                                ForEach(group.expenses) { expense in
                                    ExpenseListRow(expense: expense,
                                                   selectionMark: .of(expense, in: selection)) {
                                        selection.toggle(expense)
                                    }
                                }
                            } header: {
                                DayGroupHeader(title: DayLabel.title(group.day, calendar: calendar),
                                               total: group.total)
                                    .textCase(nil)
                                    .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
                            }
                        }
                    }
                    .cycleLensList()
                }
            }
            .background(Theme.bg)
            .safeAreaInset(edge: .bottom) {
                if !candidates.isEmpty {
                    Button("Move \(PlanCopy.counted(selection.count, "expense"))", systemImage: "tray") {
                        EnvelopeChoice.envelope(envelope.persistentModelID)
                            .apply(to: selection.expenses(in: candidates), envelopes: [envelope])
                        try? context.save()
                        dismiss()
                    }
                    .font(.dsBody.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.plan.opacity(selection.isEmpty ? 0.4 : 1), in: .capsule)
                    .buttonStyle(.plain)
                    .disabled(selection.isEmpty)
                    .padding(.horizontal, Metric.screenPadding)
                    .padding(.bottom, 8)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Move to \(name)")
                            .font(.dsBody).bold()
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        Text(subtitle(options))
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func subtitle(_ options: EnvelopeOptions) -> String {
        let title = cycle.title(calendar: calendar)
        guard let remainder = options.progress(of: envelope)?.remainderText else { return title }
        return "\(title) · \(remainder)"
    }
}
