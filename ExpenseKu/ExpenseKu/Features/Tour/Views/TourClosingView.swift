//
//  TourClosingView.swift
//  ExpenseKu
//
//  The celebration before the real, empty app (welcome-tour.md §4.2, AO19).
//

import SwiftUI

struct TourClosingView: View {
    let session: TourSession

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            TourCoinShower().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    WalletMascot(pose: .waving, size: 150)
                        .padding(.top, 40)
                    Text(appLocalized: .tourClosingTitle)
                        .font(.dsLargeTitle).bold()
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.center)
                    Text(appLocalized: .tourClosingLead)
                        .font(.dsBody)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    TourChapterTiles(ticked: true)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .readableColumn()
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom) {
                Button(AppLocalization.string(.tourStartUsing), action: session.finish)
                    .buttonStyle(.tour(.primary))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .readableColumn()
            }
        }
        .sensoryFeedback(.success, trigger: true)
    }
}
