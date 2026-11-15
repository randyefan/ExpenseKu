//
//  PlanGuideContent.swift
//  ExpenseKu
//
//  Every lesson of the Plan guide (plan-guide.md §4.2 and §4.4), as static examples drawn
//  from the PRD's one November sample (§5). Nothing here reads the owner's data: the guide
//  explains the rules, it never previews them against a real plan.
//

import Foundation

enum PlanGuideContent {
    static func lessons(of material: PlanGuideMaterial) -> [PlanGuideLesson] {
        switch material {
        case .introduction:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideIntro1Step),
                    heading: localized(.guideIntro1Heading),
                    lead: localized(.guideIntro1Lead),
                    example: PlanGuideExample(
                        title: localized(.guideIntro1Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideIntro1Row1Name), value: Decimal(8_000_000).formattedIDR(), detail: localized(.guideIntro1Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideIntro1Row2Name), value: Decimal(5_000_000).formattedIDR(), detail: localized(.guideIntro1Row2Detail)),
                            PlanGuideExampleRow(name: localized(.guideIntro1Row3Name), value: Decimal(3_000_000).formattedIDR(), detail: localized(.guideIntro1Row3Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideIntro1Takeaway1Heading), body: localized(.guideIntro1Takeaway1Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideIntro2Step),
                    heading: localized(.guideIntro2Heading),
                    lead: localized(.guideIntro2Lead),
                    example: PlanGuideExample(
                        title: localized(.guideIntro2Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideIntro2Row1Name), value: Decimal(2_800_000).formattedIDR(), detail: localized(.guideIntro2Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideIntro2Row2Name), value: Decimal(2_200_000).formattedIDR(), detail: localized(.guideIntro2Row2Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideIntro2Takeaway1Heading), body: localized(.guideIntro2Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideIntro2Takeaway2Heading), body: localized(.guideIntro2Takeaway2Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideIntro3Step),
                    heading: localized(.guideIntro3Heading),
                    lead: localized(.guideIntro3Lead),
                    example: PlanGuideExample(
                        title: localized(.guideIntro3Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideIntro3Row1Name), value: Decimal(2_200_000).formattedIDR(), detail: localized(.guideIntro3Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideIntro3Row2Name), value: localized(.guideIntro3Row2Value(Decimal(120_000).formattedIDR())), detail: localized(.guideIntro3Row2Detail(Decimal(1_680_000).formattedIDR(), Decimal(1_800_000).formattedIDR()))),
                            PlanGuideExampleRow(name: localized(.guideIntro3Row3Name), value: Decimal(3_000_000).formattedIDR(), detail: localized(.guideIntro3Row3Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideIntro3Takeaway1Heading), body: localized(.guideIntro3Takeaway1Body))
                    ]
                )
            ]
        case .startPlan:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideStart1Step),
                    heading: localized(.guideStart1Heading),
                    lead: localized(.guideStart1Lead),
                    example: PlanGuideExample(
                        title: localized(.guideStart1Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideStart1Row1Name), value: localized(.guideStart1Row1Value), detail: localized(.guideStart1Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideStart1Row2Name), value: Decimal(8_000_000).formattedIDR(), detail: localized(.guideStart1Row2Detail)),
                            PlanGuideExampleRow(name: localized(.guideStart1Row3Name), value: localized(.guideStart1Row3Value), detail: localized(.guideStart1Row3Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideStart1Takeaway1Heading), body: localized(.guideStart1Takeaway1Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideStart2Step),
                    heading: localized(.guideStart2Heading),
                    lead: localized(.guideStart2Lead),
                    example: PlanGuideExample(
                        title: localized(.guideStart2Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideStart2Row1Name), value: localized(.guideStart2Row1Value), detail: localized(.guideStart2Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideStart2Row2Name), value: localized(.guideStart2Row2Value), detail: localized(.guideStart2Row2Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideStart2Takeaway1Heading), body: localized(.guideStart2Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideStart2Takeaway2Heading), body: localized(.guideStart2Takeaway2Body))
                    ]
                )
            ]
        case .allocationTypes:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideTypes1Step),
                    heading: localized(.guideTypes1Heading),
                    lead: localized(.guideTypes1Lead),
                    example: PlanGuideExample(
                        title: localized(.guideTypes1Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideTypes1Row1Name), value: Decimal(2_200_000).formattedIDR(), detail: localized(.guideTypes1Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideTypes1Row2Name), value: Decimal(1_800_000).formattedIDR(), detail: localized(.guideTypes1Row2Detail)),
                            PlanGuideExampleRow(name: localized(.guideTypes1Row3Name), value: Decimal(1_000_000).formattedIDR(), detail: localized(.guideTypes1Row3Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideTypes1Takeaway1Heading), body: localized(.guideTypes1Takeaway1Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideTypes2Step),
                    heading: localized(.guideTypes2Heading),
                    lead: localized(.guideTypes2Lead),
                    example: PlanGuideExample(
                        title: localized(.guideTypes2Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideTypes2Row1Name), value: Decimal(1_000_000).formattedIDR(), detail: localized(.guideTypes2Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideTypes2Row2Name), value: Decimal(2_000_000).formattedIDR(), detail: localized(.guideTypes2Row2Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideTypes2Takeaway1Heading), body: localized(.guideTypes2Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideTypes2Takeaway2Heading), body: localized(.guideTypes2Takeaway2Body))
                    ]
                )
            ]
        case .managePlanItems:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideManage1Step),
                    heading: localized(.guideManage1Heading),
                    lead: localized(.guideManage1Lead),
                    example: PlanGuideExample(
                        title: localized(.guideManage1Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideManage1Row1Name), value: localized(.guideManage1Row1Value), detail: localized(.guideManage1Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideManage1Row2Name), value: localized(.guideManage1Row2Value), detail: localized(.guideManage1Row2Detail)),
                            PlanGuideExampleRow(name: localized(.guideManage1Row3Name), value: localized(.guideManage1Row3Value), detail: localized(.guideManage1Row3Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideManage1Takeaway1Heading), body: localized(.guideManage1Takeaway1Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideManage2Step),
                    heading: localized(.guideManage2Heading),
                    lead: localized(.guideManage2Lead),
                    example: PlanGuideExample(
                        title: localized(.guideManage2Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideManage2Row1Name), value: Decimal(2_200_000).formattedIDR(), detail: localized(.guideManage2Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideManage2Row2Name), value: localized(.guideManage2Row2Value), detail: localized(.guideManage2Row2Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideManage2Takeaway1Heading), body: localized(.guideManage2Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideManage2Takeaway2Heading), body: localized(.guideManage2Takeaway2Body))
                    ]
                )
            ]
        case .paydayTransfers:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideTransfers1Step),
                    heading: localized(.guideTransfers1Heading),
                    lead: localized(.guideTransfers1Lead),
                    example: PlanGuideExample(
                        title: localized(.guideTransfers1Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideTransfers1Row1Name), value: Decimal(2_800_000).formattedIDR(), detail: localized(.guideTransfers1Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideTransfers1Row2Name), value: Decimal(2_200_000).formattedIDR(), detail: localized(.guideTransfers1Row2Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideTransfers1Takeaway1Heading), body: localized(.guideTransfers1Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideTransfers1Takeaway2Heading), body: localized(.guideTransfers1Takeaway2Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideTransfers2Step),
                    heading: localized(.guideTransfers2Heading),
                    lead: localized(.guideTransfers2Lead),
                    example: PlanGuideExample(
                        title: localized(.guideTransfers2Card),
                        label: localized(.guideTransfers2Label),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideTransfers2Row1Name), value: Decimal(1_800_000).formattedIDR(), selection: .selected),
                            PlanGuideExampleRow(name: localized(.guideTransfers2Row2Name), value: Decimal(1_000_000).formattedIDR(), selection: .unselected)
                        ],
                        summary: PlanGuideExampleRow(name: localized(.guideTransfers2Summary), value: Decimal(1_800_000).formattedIDR()),
                        actionTitle: localized(.guideTransfers2Action)
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideTransfers2Takeaway1Heading), body: localized(.guideTransfers2Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideTransfers2Takeaway2Heading), body: localized(.guideTransfers2Takeaway2Body))
                    ]
                )
            ]
        case .followEnvelope:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideEnvelope1Step),
                    heading: localized(.guideEnvelope1Heading),
                    lead: localized(.guideEnvelope1Lead),
                    example: PlanGuideExample(
                        title: localized(.guideEnvelope1Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideEnvelope1Row1Name), value: Decimal(1_800_000).formattedIDR(), detail: localized(.guideEnvelope1Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideEnvelope1Row2Name), value: Decimal(120_000).formattedIDR(), detail: localized(.guideEnvelope1Row2Detail)),
                            PlanGuideExampleRow(name: localized(.guideEnvelope1Row3Name), value: Decimal(1_680_000).formattedIDR(), detail: localized(.guideEnvelope1Row3Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideEnvelope1Takeaway1Heading), body: localized(.guideEnvelope1Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideEnvelope1Takeaway2Heading), body: localized(.guideEnvelope1Takeaway2Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideEnvelope2Step),
                    heading: localized(.guideEnvelope2Heading),
                    lead: localized(.guideEnvelope2Lead),
                    example: PlanGuideExample(
                        title: localized(.guideEnvelope2Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideEnvelope2Row1Name), value: Decimal(75_000).formattedIDR(), detail: localized(.guideEnvelope2Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideEnvelope2Row2Name), value: Decimal(300_000).formattedIDR(), detail: localized(.guideEnvelope2Row2Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideEnvelope2Takeaway1Heading), body: localized(.guideEnvelope2Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideEnvelope2Takeaway2Heading), body: localized(.guideEnvelope2Takeaway2Body))
                    ]
                )
            ]
        case .readAndTidy:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideTidy1Step),
                    heading: localized(.guideTidy1Heading),
                    lead: localized(.guideTidy1Lead),
                    example: PlanGuideExample(
                        title: localized(.guideTidy1Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideTidy1Row1Name), value: localized(.guideTidy1Row1Value), detail: localized(.guideTidy1Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideTidy1Row2Name), value: localized(.guideTidy1Row2Value), detail: localized(.guideTidy1Row2Detail)),
                            PlanGuideExampleRow(name: localized(.guideTidy1Row3Name), value: localized(.guideTidy1Row3Value), detail: localized(.guideTidy1Row3Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideTidy1Takeaway1Heading), body: localized(.guideTidy1Takeaway1Body))
                    ]
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideTidy2Step),
                    heading: localized(.guideTidy2Heading),
                    lead: localized(.guideTidy2Lead),
                    example: PlanGuideExample(
                        title: localized(.guideTidy2Card),
                        label: localized(.guideExampleNovember),
                        rows: [
                            PlanGuideExampleRow(name: localized(.guideTidy2Row1Name), value: localized(.guideTidy2Row1Value), detail: localized(.guideTidy2Row1Detail)),
                            PlanGuideExampleRow(name: localized(.guideTidy2Row2Name), value: localized(.guideTidy2Row2Value), detail: localized(.guideTidy2Row2Detail))
                        ]
                    ),
                    takeaways: [
                        PlanGuideTakeaway(heading: localized(.guideTidy2Takeaway1Heading), body: localized(.guideTidy2Takeaway1Body)),
                        PlanGuideTakeaway(heading: localized(.guideTidy2Takeaway2Heading), body: localized(.guideTidy2Takeaway2Body))
                    ]
                )
            ]
        }
    }

    static func title(of material: PlanGuideMaterial) -> String {
        switch material {
        case .introduction: localized(.guideIntroTitle)
        case .startPlan: localized(.guideStartTitle)
        case .allocationTypes: localized(.guideTypesTitle)
        case .managePlanItems: localized(.guideManageTitle)
        case .paydayTransfers: localized(.guideTransfersTitle)
        case .followEnvelope: localized(.guideEnvelopeTitle)
        case .readAndTidy: localized(.guideTidyTitle)
        }
    }

    static func subtitle(of material: PlanGuideMaterial) -> String {
        switch material {
        case .introduction: ""
        case .startPlan: localized(.guideStartSubtitle)
        case .allocationTypes: localized(.guideTypesSubtitle)
        case .managePlanItems: localized(.guideManageSubtitle)
        case .paydayTransfers: localized(.guideTransfersSubtitle)
        case .followEnvelope: localized(.guideEnvelopeSubtitle)
        case .readAndTidy: localized(.guideTidySubtitle)
        }
    }

    private static func localized(_ resource: LocalizedStringResource) -> String {
        AppLocalization.string(resource)
    }
}
