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
//  Filtered to Funded items (L6), it shows only what that filter is about: the header
//  and the totals stay, untouched, and the rest of the list steps aside until ✕.
//

import SwiftData
import SwiftUI

struct CyclePlanLens<Header: View>: View {
    let contents: PlanContents
    let payday: Int
    let today: Date
    let calendar: Calendar
    let dormantExpanded: Bool
    var isFundedFiltered = false
    var sort: PlanSort = .amount
    var lookBackMonth: String?
    var copySourceMonth: String?
    var guideInvitation: PlanGuideInvitation?
    var onOpenGuide: () -> Void = {}
    var revealTrigger: AnyHashable = 0
    let onAction: (PlanAction) -> Void
    @ViewBuilder let header: Header

    /// The tour's spotlights end on the last plan row, which would sit under the tab bar.
    @Environment(\.tour) private var tour

    var body: some View {
        ScrollViewReader { proxy in
            list
                .onChange(of: tour?.command) { _, request in
                    guard request?.command == .revealPlanRows,
                          let last = contents.plan?.items?.max(by: { $0.createdAt < $1.createdAt }) else { return }
                    withAnimation(Motion.settle) { proxy.scrollTo(last.persistentModelID, anchor: .center) }
                }
        }
    }

    // List ignores ScrollPosition, so the tour's scroll goes through a ScrollViewReader.
    private var list: some View {
        List {
            Section {
                VStack(spacing: Metric.cardGap) {
                    header
                    if contents.hasPlan {
                        notice
                        PlanTotalsCard(contents: contents, payday: payday, calendar: calendar, onAction: onAction)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }

            if contents.hasPlan {
                planItems
                if !isFundedFiltered {
                    dormantSection
                    addRows
                    transferChecklist
                    groupShares
                }
            } else {
                Section {
                    PlanEmptyState(
                        copySourceMonth: copySourceMonth,
                        guideInvitation: guideInvitation,
                        onOpenGuide: onOpenGuide,
                        onCopy: { onAction(.copyPlan) },
                        onStart: { onAction(.startPlan) }
                    )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
            }
        }
        .cycleLensList()
    }

    // MARK: - Sections

    /// One notice at a time. Review comes first: ADR-0007 accepts it as the only
    /// defence against a wrong autodebit, so nothing may push it off the screen.
    @ViewBuilder
    private var notice: some View {
        if isFundedFiltered {
            FundedFilterBar(total: contents.funded.total) {
                onAction(.clearFundedFilter)
            }
        } else if !contents.review.isEmpty {
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
                title: AppLocalization.string(.copiedFromLastCycle),
                detail: PlanCopy.carriedOver(from: source, payday: payday,
                                             items: plan.copiedItemCount,
                                             incomeLines: plan.copiedIncomeCount,
                                             calendar: calendar)
            )
        } else if !contents.funded.isEmpty {
            PlanNotice(
                kind: .funded,
                title: contents.funded.title,
                detail: contents.funded.detail,
                onTap: { onAction(.showFunded) }
            )
        } else if contents.transfers.contains(where: { !$0.isAllIn }),
                  contents.incomeLines.contains(where: \.hasArrived),
                  contents.doneCount == 0 {
            PlanNotice(
                kind: .payday,
                title: AppLocalization.string(.paydayTransfers(contents.transfers.count(where: { !$0.isAllIn }))),
                detail: AppLocalization.string(.workDownTheChecklistAtTheFoot)
            )
        }
    }

    private var shownItems: [PlanItem] {
        isFundedFiltered ? contents.funded.items : contents.activeItems
    }

    private var sectionTitle: String {
        isFundedFiltered
            ? PlanCopy.filteredSectionTitle(shown: shownItems.count, of: contents.activeItems.count)
            : contents.sectionTitle
    }

    private var sections: [PlanSection] {
        PlanSections.sections(shownItems, by: isFundedFiltered ? .amount : sort,
                              cycle: contents.cycle, calendar: calendar)
    }

    private var planItems: some View {
        ForEach(sections.enumerated(), id: \.element.id) { index, section in
            Section {
                ForEach(section.items) { item in
                    PlanListRow {
                        if item.isSetAside {
                            PlanSetAsideRow(
                                item: item,
                                payday: payday,
                                calendar: calendar,
                                onChooseFunding: { onAction(.chooseFunding(item, $0)) },
                                onSelect: { onAction(.editPlanItem(item)) }
                            )
                        } else if item.isEnvelope {
                            let progress = contents.envelope(for: item)
                            PlanEnvelopeRow(
                                item: item,
                                progress: progress,
                                fromEarlierCaption: progress?.fromEarlierCaption(payday: payday, calendar: calendar),
                                ownShareCaption: progress?.ownShareCaption(cycle: contents.cycle, calendar: calendar),
                                onChooseFunding: { onAction(.chooseFunding(item, $0)) },
                                onSelect: { onAction(.openEnvelope(item)) },
                                onAddExpense: { onAction(.addExpense(to: item)) },
                                onMoveExpenses: { onAction(.moveExpenses(to: item)) }
                            )
                            .tourTarget(.harianRow)
                        } else {
                            PlanFixedRow(
                                item: item,
                                cycle: contents.cycle,
                                today: today,
                                calendar: calendar,
                                onTapCheck: { onAction(.tapDoneCheck(item)) },
                                onChooseFunding: { onAction(.chooseFunding(item, $0)) },
                                onSelect: { onAction(.editPlanItem(item)) }
                            )
                        }
                    }
                    .environment(\.planRowsShowAccount, !section.isAccountGroup)
                }
            } header: {
                VStack(alignment: .leading, spacing: 10) {
                    if index == 0 {
                        HStack {
                            SectionHeaderText(sectionTitle)
                            Spacer(minLength: 8)
                            if !isFundedFiltered {
                                PlanSortMenu(sort: sort) { onAction(.sortPlan($0)) }
                            }
                        }
                    }
                    if section.heading != nil {
                        PlanSectionHeader(section: section)
                    }
                }
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
                PickerAddRow(title: AppLocalization.string(.addPlanItem)).padding(.vertical, 4)
            }
            PlanListRow(onSelect: { onAction(.addIncomeLine) }) {
                PickerAddRow(title: AppLocalization.string(.addIncomeLine)).padding(.vertical, 4)
            }
            if let lookBackMonth {
                PlanListRow(onSelect: { onAction(.lookBack) }) {
                    LookBackEntryRow(month: lookBackMonth).padding(.vertical, 4)
                }
            }
        } footer: {
            Text(appLocalized: .inTheToolbarStillLogsAnExpensePlanItemsAreAdded)
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
                        TransferRowView(row: row) { onAction(.openTransfer(row)) }
                    }
                }
            } header: {
                SectionHeaderText(
                    AppLocalization.string(.transferChecklistOfSent(String(TransferLines.sentCount(contents.transfers)), String(contents.transfers.count)))
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
                SectionHeaderText(.shareOfIncomePlanned)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
            }
        }
    }
}
