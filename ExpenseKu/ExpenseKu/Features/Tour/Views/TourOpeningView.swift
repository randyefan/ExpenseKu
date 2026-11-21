//
//  TourOpeningView.swift
//  ExpenseKu
//
//  The tour's first screen (welcome-tour.md §4.2, AO1): the wallet drops in, bounces, waves.
//

import SwiftUI

struct TourOpeningView: View {
    let session: TourSession

    @State private var landed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                WalletMascot(pose: .waving, size: 150)
                    .offset(y: landed || reduceMotion ? 0 : -420)
                    .padding(.top, 24)
                Text(appLocalized: .tourOpeningTitle)
                    .font(.dsLargeTitle).bold()
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                Text(appLocalized: .tourOpeningLead)
                    .font(.dsBody)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(appLocalized: .tourOpeningMeta)
                    .font(.dsCaption).bold()
                    .foregroundStyle(Theme.accentText)
                    .multilineTextAlignment(.center)
                TourChapterTiles()
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .readableColumn()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                Button(AppLocalization.string(.tourStart), action: session.start)
                    .buttonStyle(.tour(.primary))
                Button(AppLocalization.string(.tourSkip), action: session.skip)
                    .buttonStyle(.tour(.plain, height: 44))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .readableColumn()
            .background(Theme.bg)
        }
        .background(Theme.bg)
        .sensoryFeedback(.impact(weight: .light), trigger: landed)
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.45).delay(0.15)) { landed = true }
        }
    }
}
