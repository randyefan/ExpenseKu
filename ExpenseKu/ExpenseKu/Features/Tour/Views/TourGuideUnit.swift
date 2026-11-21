//
//  TourGuideUnit.swift
//  ExpenseKu
//
//  The wallet and its bubble as one unit (welcome-tour.md §4.3): the wallet sits on the side
//  away from the target and the bubble's tail points back at it.
//

import SwiftUI

struct TourGuideUnit: View {
    let session: TourSession
    let line: String
    let placement: TourPlacement
    let width: CGFloat

    @Environment(\.dynamicTypeSize) private var typeSize

    private var walletSize: CGFloat { typeSize.isAccessibilitySize ? 56 : 84 }
    private static let spacing: CGFloat = 2

    var body: some View {
        HStack(alignment: .bottom, spacing: Self.spacing) {
            if placement.walletLeading { wallet }
            bubble
            if !placement.walletLeading { wallet }
        }
        .frame(width: width)
    }

    private var wallet: some View {
        WalletMascot(pose: session.pose, mirrored: placement.mirrored, size: walletSize,
                     shake: session.touch?.id ?? 0, hop: session.hops)
    }

    private var bubble: some View {
        TourBubble(
            eyebrow: AppLocalization.string(.tourEyebrow(session.position.chapter.rawValue,
                                                         AppLocalization.string(session.position.chapter.title))),
            line: line,
            fills: TourChapter.allCases.map(session.fill(of:)),
            nextTitle: nextTitle,
            tail: tail,
            onSkip: session.skip,
            onNext: session.next
        )
    }

    private var nextTitle: String? {
        guard case .spotlight = session.beat?.kind else { return nil }
        let isLast = session.beat == TourScript(lastCycleName: "").missions(in: .plan).last?.beats.last
        return AppLocalization.string(isLast ? .done : .tourNext)
    }

    private var tail: TourBubbleTail? {
        guard let tailX = placement.tailX else { return nil }
        let offset = placement.walletLeading ? walletSize + Self.spacing : 0
        return TourBubbleTail(edge: placement.side == .below ? .top : .bottom, x: tailX - offset)
    }
}
