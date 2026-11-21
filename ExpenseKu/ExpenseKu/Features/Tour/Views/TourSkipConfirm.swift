//
//  TourSkipConfirm.swift
//  ExpenseKu
//
//  Skip in the bubble asks first, through the Confused wallet (welcome-tour.md §4.7, AO20).
//

import SwiftUI

struct TourSkipConfirm: View {
    let session: TourSession

    var body: some View {
        ZStack {
            Theme.tourScrim
                .ignoresSafeArea()
                .contentShape(.rect)
            VStack(spacing: 16) {
                WalletMascot(pose: .confused, size: 110, shake: 1)
                Text(appLocalized: .tourSkipQuestion)
                    .font(.dsHeadline).bold()
                    .foregroundStyle(Theme.tourBubbleText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button(AppLocalization.string(.tourSkip), action: session.confirmSkip)
                        .buttonStyle(.tour(.bubbleOutlined, height: 48))
                    Button(AppLocalization.string(.tourKeepGoing), action: session.keepGoing)
                        .buttonStyle(.tour(.primary, height: 48))
                }
            }
            .padding(22)
            .background(Theme.tourBubble, in: .rect(cornerRadius: 24))
            .frame(maxWidth: 340)
            .padding(.horizontal, 24)
        }
    }
}
