//
//  TransferSheet.swift
//  ExpenseKu
//
//  One transfer line opened: its items still to send, all chosen, the adjustment, the
//  figure to move now, and what is already in (docs/prd/partial-transfer.md §6, frames
//  AD2–AD7).
//
//  The choice is this sheet's own state and dies with it (§7): only "Moved to BCA"
//  outlives it, by making the chosen items Funded. `row` arrives live, so an item put
//  back with "Not moved yet" reappears under To send at once — unchosen, because the
//  choice was made before it came back.
//

import SwiftUI
import SwiftData

struct TransferSheet: View {
    let plan: CyclePlan
    let row: TransferRow
    let account: Account?
    /// The line's own items, for the writes.
    let items: [PlanItem]
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var chosen: Set<PersistentIdentifier>
    @State private var isEditingAdjustment = false

    init(plan: CyclePlan, row: TransferRow, account: Account?, items: [PlanItem],
         onFinish: @escaping () -> Void) {
        self.plan = plan
        self.row = row
        self.account = account
        self.items = items
        self.onFinish = onFinish
        _chosen = State(initialValue: TransferPick.initialChoice(for: row))
    }

    var body: some View {
        let pick = TransferPick(row: row, chosen: chosen)

        NavigationStack {
            List {
                if pick.toSend.isEmpty {
                    Section {
                        Text(pick.allInMessage)
                            .font(.dsBody)
                            .foregroundStyle(Theme.textSecondary)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 4, trailing: 4))
                    }
                } else {
                    Section {
                        ForEach(pick.toSend) { member in
                            PlanListRow {
                                TransferPickRowView(member: member, isChosen: pick.isChosen(member)) {
                                    toggle(member)
                                }
                            }
                        }
                    } header: {
                        sectionHeader(pick.sendTitle)
                    }
                }

                Section {
                    PlanListRow(onSelect: { isEditingAdjustment = true }) {
                        TransferAdjustmentRow(adjustment: row.adjustment, note: pick.adjustmentNote)
                    }
                    PlanListRow {
                        TransferFigureRow(title: pick.figureTitle, amount: pick.figure,
                                          isNow: !pick.toSend.isEmpty)
                    }
                }

                if !pick.toSend.isEmpty {
                    Section {
                        TransferRecordButton(title: pick.recordEntry.title, isEnabled: pick.canRecord) {
                            record(pick)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                    }
                }

                if !pick.alreadyIn.isEmpty {
                    Section {
                        ForEach(pick.alreadyIn) { member in
                            PlanListRow {
                                TransferInRowView(member: member, accountName: row.accountName) { entry in
                                    undo(member, entry)
                                }
                            }
                        }
                    } header: {
                        sectionHeader(pick.alreadyInTitle)
                    }
                }
            }
            .cycleLensList()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.string(.close), systemImage: "xmark", action: onFinish)
                        .tint(Theme.text)
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        AccountPlate(style: row.plate)
                        Text(appLocalized: .transferTo(row.accountName))
                            .font(.dsHeadline).bold()
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
            }
        }
        .sheet(isPresented: $isEditingAdjustment) {
            TransferAdjustmentEditorView(plan: plan, row: row, account: account) {
                isEditingAdjustment = false
            }
            .presentationBackground(Theme.bg)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        SectionHeaderText(title)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
    }

    // MARK: - Writes

    private func toggle(_ member: TransferMember) {
        if chosen.contains(member.id) {
            chosen.remove(member.id)
        } else {
            chosen.insert(member.id)
        }
    }

    private func record(_ pick: TransferPick) {
        let ids = Set(pick.chosenMembers.map(\.id))
        for item in items where ids.contains(item.persistentModelID) {
            item.recordMoved()
        }
        try? context.save()
        onFinish()
    }

    private func undo(_ member: TransferMember, _ entry: FundMenuEntry) {
        guard let item = items.first(where: { $0.persistentModelID == member.id }) else { return }
        item.apply(entry)
        try? context.save()
    }
}
