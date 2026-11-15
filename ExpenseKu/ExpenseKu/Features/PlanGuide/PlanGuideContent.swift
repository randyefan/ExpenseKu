//
//  PlanGuideContent.swift
//  ExpenseKu
//
//  Every lesson of the Plan guide, with the spotlights each step walks and the sample
//  state each one shows (plan-guide-visual.md §4.5). Nothing here reads the owner's data:
//  the examples are drawn from the guide's own November sample.
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
                    scene: .beforePayday,
                    spotlights: .walk([
                        (.incomeLine, localized(.guideIntro1Spot1), nil),
                        (.planRows, localized(.guideIntro1Spot2), nil),
                        (.remainingLine, localized(.guideIntro1Spot3), nil)
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideIntro2Step),
                    heading: localized(.guideIntro2Heading),
                    lead: localized(.guideIntro2Lead),
                    scene: .onPayday,
                    spotlights: .walk([
                        (.incomeLine, localized(.guideIntro2Spot1), { $0.gajiArrived = true }),
                        (.transferChecklist, localized(.guideIntro2Spot2(idr(2_800_000), idr(2_200_000))), nil),
                        (.movedButton, localized(.guideIntro2Spot3), nil)
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideIntro3Step),
                    heading: localized(.guideIntro3Heading),
                    lead: localized(.guideIntro3Lead),
                    scene: .throughTheCycle,
                    spotlights: .walk(from: everydaySpending, [
                        (.kosRow, localized(.guideIntro3Spot1), { $0.kos = .done }),
                        (.harianRow, localized(.guideIntro3Spot2), nil),
                        (.remainingLine, localized(.guideIntro3Spot3(idr(3_000_000))), nil)
                    ])
                )
            ]
        case .startPlan:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideStart1Step),
                    heading: localized(.guideStart1Heading),
                    lead: localized(.guideStart1Lead),
                    scene: .chooseCycle,
                    spotlights: .walk([
                        (.cycleHeader, localized(.guideStart1Spot1), nil),
                        (.incomeLine, localized(.guideStart1Spot2), nil),
                        (.addPlanItem, localized(.guideStart1Spot3), nil)
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideStart2Step),
                    heading: localized(.guideStart2Heading),
                    lead: localized(.guideStart2Lead),
                    scene: .reuse,
                    spotlights: .walk([
                        (.copyFrom, localized(.guideStart2Spot1), nil),
                        (.startEmpty, localized(.guideStart2Spot2), nil),
                        (.lookBackRow, localized(.guideStart2Spot3), nil)
                    ])
                )
            ]
        case .allocationTypes:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideTypes1Step),
                    heading: localized(.guideTypes1Heading),
                    lead: localized(.guideTypes1Lead),
                    scene: .itemKinds,
                    spotlights: .walk([
                        (.kosRow, localized(.guideTypes1Spot1), nil),
                        (.harianRow, localized(.guideTypes1Spot2), nil),
                        (.liburanRow, localized(.guideTypes1Spot3), nil)
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideTypes2Step),
                    heading: localized(.guideTypes2Heading),
                    lead: localized(.guideTypes2Lead),
                    scene: .setAside,
                    spotlights: .walk([
                        (.rowBody, localized(.guideTypes2Spot1(idr(1_000_000))), nil),
                        (.remainingLine, localized(.guideTypes2Spot2(idr(1_000_000))), nil),
                        (.check, localized(.guideTypes2Spot3), nil)
                    ])
                )
            ]
        case .managePlanItems:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideManage1Step),
                    heading: localized(.guideManage1Heading),
                    lead: localized(.guideManage1Lead),
                    scene: .rowAndStatus,
                    spotlights: .walk([
                        (.rowBody, localized(.guideManage1Spot1), nil),
                        (.check, localized(.guideManage1Spot2), { $0.kos = .funded }),
                        (.check, localized(.guideManage1Spot3), { $0.kos = .done })
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideManage2Step),
                    heading: localized(.guideManage2Heading),
                    lead: localized(.guideManage2Lead),
                    scene: .datesAndAuto,
                    spotlights: .walk(from: autoKos, [
                        (.dueChip, localized(.guideManage2Spot1), nil),
                        (.autoChip, localized(.guideManage2Spot2), { $0.kos = .autoPosted }),
                        (.check, localized(.guideManage2Spot3), { $0.kos = .funded })
                    ])
                )
            ]
        case .paydayTransfers:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideTransfers1Step),
                    heading: localized(.guideTransfers1Heading),
                    lead: localized(.guideTransfers1Lead),
                    scene: .destinations,
                    spotlights: .walk([
                        (.incomeLine, localized(.guideTransfers1Spot1), { $0.gajiArrived = true }),
                        (.transferChecklist, localized(.guideTransfers1Spot2), nil),
                        (.kosRow, localized(.guideTransfers1Spot3), { $0.kosHasAccount = false })
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideTransfers2Step),
                    heading: localized(.guideTransfers2Heading),
                    lead: localized(.guideTransfers2Lead),
                    scene: .partialTransfer,
                    spotlights: .walk(from: paydayArrived, [
                        (.liburanPick, localized(.guideTransfers2Spot1), { $0.liburanChosen = false }),
                        (.transferNow, localized(.guideTransfers2Spot2(idr(1_800_000))), nil),
                        (.movedButton, localized(.guideTransfers2Spot3), nil),
                        (.transferChecklist, localized(.guideTransfers2Spot4(idr(1_000_000))), { $0.harianFunded = true })
                    ])
                )
            ]
        case .followEnvelope:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideEnvelope1Step),
                    heading: localized(.guideEnvelope1Heading),
                    lead: localized(.guideEnvelope1Lead),
                    scene: .envelopeFill,
                    spotlights: .walk(from: everydaySpending, [
                        (.envelopeBar, localized(.guideEnvelope1Spot1(idr(1_680_000), idr(1_800_000))), nil),
                        (.envelopeAdd, localized(.guideEnvelope1Spot2), nil),
                        (.editorEnvelope, localized(.guideEnvelope1Spot3), nil),
                        (.envelopeBar, localized(.guideEnvelope1Spot4(idr(165_000))), { $0.harianSpent = PlanGuideSampleState.harianWithMakan }),
                        (.envelopeBar, localized(.guideEnvelope1Spot5), { $0.harianSpent = PlanGuideSampleState.harianOverspent })
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideEnvelope2Step),
                    heading: localized(.guideEnvelope2Heading),
                    lead: localized(.guideEnvelope2Lead),
                    scene: .elsewhere,
                    spotlights: .walk(from: paidEarlyTicket, [
                        (.paidElsewhereRow, localized(.guideEnvelope2Spot1(idr(75_000))), nil),
                        (.paidElsewhereRow, localized(.guideEnvelope2Spot2), { $0.paidElsewhereMoved = true }),
                        (.paidEarlyRow, localized(.guideEnvelope2Spot3), nil)
                    ])
                )
            ]
        case .readAndTidy:
            [
                PlanGuideLesson(
                    stepTitle: localized(.guideTidy1Step),
                    heading: localized(.guideTidy1Heading),
                    lead: localized(.guideTidy1Lead),
                    scene: .changeView,
                    spotlights: .walk([
                        (.sortMenu, localized(.guideTidy1Spot1), nil),
                        (.accountGroups, localized(.guideTidy1Spot2), { $0.sort = .account }),
                        (.groupShares, localized(.guideTidy1Spot3), nil)
                    ])
                ),
                PlanGuideLesson(
                    stepTitle: localized(.guideTidy2Step),
                    heading: localized(.guideTidy2Heading),
                    lead: localized(.guideTidy2Lead),
                    scene: .noticesAndClearing,
                    spotlights: .walk(from: autoPosted, [
                        (.reviewNotice, localized(.guideTidy2Spot1), nil),
                        (.clearPlan, localized(.guideTidy2Spot2), nil)
                    ])
                )
            ]
        }
    }

    private static let everydaySpending = PlanGuideSampleState(harianSpent: PlanGuideSampleState.harianEveryday)
    private static let autoKos = PlanGuideSampleState(kosIsAuto: true)
    private static let paydayArrived = PlanGuideSampleState(gajiArrived: true)
    private static let paidEarlyTicket = PlanGuideSampleState(harianSpent: PlanGuideSampleState.harianEveryday,
                                                              paidEarlyTicket: true)
    private static let autoPosted = PlanGuideSampleState(gajiArrived: true, kos: .autoPosted, kosIsAuto: true)

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

    private static func idr(_ amount: Decimal) -> String {
        amount.formattedIDR()
    }

    private static func localized(_ resource: LocalizedStringResource) -> String {
        AppLocalization.string(resource)
    }
}
