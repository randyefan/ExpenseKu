//
//  PlanGuideChangeViewScene.swift
//  ExpenseKu
//
//  The plan's own header, sort control and sections, with the sort menu drawn open while
//  it is lit (plan-guide-visual.md decision 31), and SHARE OF INCOME · PLANNED below.
//

import SwiftUI

struct PlanGuideChangeViewScene: View {
    let target: PlanGuideTarget
    let sample: PlanGuideSample

    var body: some View {
        let contents = sample.contents
        let sort = sample.state.sort
        let sections = PlanSections.sections(contents.activeItems, by: sort, cycle: contents.cycle,
                                             calendar: sample.calendar)

        VStack(alignment: .leading, spacing: Metric.cardGap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SectionHeaderText(contents.sectionTitle)
                    Spacer(minLength: 8)
                    PlanSortMenu(sort: sort, onChoose: { _ in })
                }
                .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: Metric.cardGap) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            if section.heading != nil {
                                PlanSectionHeader(section: section)
                                    .padding(.horizontal, 4)
                            }
                            PlanGuideCard {
                                ForEach(section.items) { item in
                                    PlanGuideItemRow(item: item, sample: sample)
                                        .environment(\.planRowsShowAccount, !section.isAccountGroup)
                                }
                            }
                        }
                    }
                }
                .planGuideTarget(.accountGroups, radius: Metric.cardRadius)
                .overlay(alignment: .topTrailing) {
                    if target == .sortMenu {
                        PlanGuideMenuPanel(items: PlanSort.allCases.map {
                            .init(title: $0.title, systemImage: $0.systemImage, isChecked: $0 == sort)
                        }, showsChecks: true)
                        .planGuideTarget(.sortMenu)
                    }
                }
            }

            PlanGuideCard(header: AppLocalization.string(.shareOfIncomePlanned)) {
                ForEach(contents.groupShares) { share in
                    GroupShareRowView(share: share)
                }
            }
            .planGuideTarget(.groupShares, radius: Metric.cardRadius)
        }
    }
}
