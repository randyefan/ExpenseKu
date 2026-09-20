//
//  CyclePlanLens.swift
//  ExpenseKu
//
//  The third lens on the Expenses home: the same cycle seen from the other side —
//  what was intended, against what happened (PRD §6).
//
//  It is a lens, not a fourth tab, because a plan and a ledger are two readings of one
//  pay cycle. Sharing the home's cycle navigator is the point: two navigators that
//  must stay in sync is the bug this avoids.
//
//  A List with sections, matching CycleListLens down to the chrome — the same
//  .insetGrouped style, the same compact section spacing, the same horizontal content
//  margin and the same header section with zeroed insets. Any difference shows up as
//  the header *sliding* during the lens cross-fade, which a still screenshot will not
//  catch.
//
//  It owns no state and writes nothing. Everything goes out as a PlanAction, because
//  this view sits under .id(LensKey(cycle:lens:)) and is rebuilt whenever the owner
//  pages or switches lens.
//

import SwiftUI

struct CyclePlanLens<Header: View>: View {
    let contents: PlanContents
    let payday: Int
    let today: Date
    let calendar: Calendar
    let dormantExpanded: Bool
    var revealTrigger: AnyHashable = 0
    let onAction: (PlanAction) -> Void
    @ViewBuilder let header: Header

    var body: some View {
        List {
            Section {
                VStack(spacing: Metric.cardGap) {
                    header
                    if contents.hasPlan {
                        notice
                        PlanTotalsCard(contents: contents, onAction: onAction)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }

            if contents.hasPlan {
                planItems
                dormantSection
                addRows
                transferChecklist
                groupShares
            } else {
                Section {
                    PlanEmptyState { onAction(.startPlan) }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
            }
        }
        .cycleLensList()
    }

    // MARK: - Sections

    @ViewBuilder
    private var notice: some View {
        if !contents.review.isEmpty {
            PlanNotice(
                kind: .review,
                title: contents.review.title,
                detail: contents.review.detail,
                onTap: { onAction(.openReview) }
            )
        } else if let plan = contents.plan,
                  let source = plan.copiedFromCycleStart,
                  !plan.carryOverNoticeSeen {
            PlanNotice(
                kind: .carriedOver,
                title: "Copied from last cycle",
                detail: PlanCopy.carriedOver(from: source, payday: payday,
                                             items: plan.copiedItemCount,
                                             incomeLines: plan.copiedIncomeCount,
                                             calendar: calendar)
            )
        } else if contents.transfers.contains(where: { !$0.hasTransferred }),
                  contents.incomeLines.contains(where: \.hasArrived),
                  contents.doneCount == 0 {
            PlanNotice(
                kind: .payday,
                title: "Payday — " + PlanCopy.counted(
                    contents.transfers.count(where: { !$0.hasTransferred }), "transfer"
                ) + " to make",
                detail: "Work down the checklist at the foot."
            )
        }
    }

    @ViewBuilder
    private var planItems: some View {
        if !contents.activeItems.isEmpty {
            Section {
                ForEach(contents.activeItems) { item in
                    PlanListRow {
                        if item.isEnvelope {
                            PlanEnvelopeRow(
                                item: item,
                                progress: contents.envelope(for: item),
                                onSelect: { onAction(.editPlanItem(item)) }
                            )
                        } else {
                            PlanFixedRow(
                                item: item,
                                cycle: contents.cycle,
                                today: today,
                                calendar: calendar,
                                onTapCheck: { onAction(.tapDoneCheck(item)) },
                                onSelect: { onAction(.editPlanItem(item)) }
                            )
                        }
                    }
                }
            } header: {
                SectionHeaderText(contents.sectionTitle)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
            }
            // Per section, never per row: a 25-row plan must not cascade 25 reveals.
            .reveal(0, trigger: revealTrigger)
        }
    }

    @ViewBuilder
    private var dormantSection: some View {
        if !contents.dormantItems.isEmpty {
            Section {
                if dormantExpanded {
                    ForEach(contents.dormantItems) { item in
                        PlanListRow {
                            DormantRow(
                                item: item,
                                payday: payday,
                                calendar: calendar,
                                onActivate: { onAction(.activateDormant(item)) }
                            )
                        }
                    }
                }
            } header: {
                DormantHeader(
                    count: contents.dormantItems.count,
                    isExpanded: dormantExpanded,
                    onToggle: { onAction(.toggleDormantSection) }
                )
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
            }
        }
    }

    /// The ＋ toolbar button is untouched and still logs an expense (PRD goal 2), so
    /// plan items are added from the foot of the list — the same PickerAddRow pattern
    /// as "New Category". The caption says so, because the two are easy to confuse.
    private var addRows: some View {
        Section {
            PlanListRow(onSelect: { onAction(.addPlanItem) }) {
                PickerAddRow(title: "Add plan item").padding(.vertical, 4)
            }
            PlanListRow(onSelect: { onAction(.addIncomeLine) }) {
                PickerAddRow(title: "Add income line").padding(.vertical, 4)
            }
        } footer: {
            Text("＋ in the toolbar still logs an expense. Plan items are added here.")
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
        }
    }

    @ViewBuilder
    private var transferChecklist: some View {
        if !contents.transfers.isEmpty {
            Section {
                ForEach(contents.transfers) { row in
                    PlanListRow {
                        TransferRowView(
                            row: row,
                            onToggleTransferred: { onAction(.toggleTransferred(row)) },
                            onEditAdjustment: { onAction(.editAdjustment(row)) }
                        )
                    }
                }
            } header: {
                SectionHeaderText(
                    "Transfer checklist · \(TransferLines.sentCount(contents.transfers)) of \(contents.transfers.count) sent"
                )
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
            }
        }
    }

    @ViewBuilder
    private var groupShares: some View {
        if !contents.groupShares.isEmpty {
            Section {
                ForEach(contents.groupShares) { share in
                    PlanListRow { GroupShareRowView(share: share) }
                }
            } header: {
                SectionHeaderText("Share of income · planned")
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
            }
        }
    }
}
