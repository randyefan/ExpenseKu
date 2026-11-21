//
//  WelcomeTourView.swift
//  ExpenseKu
//
//  The ExpenseKu tour (docs/prd/welcome-tour.md): the app's real tabs drawn from the tour's
//  own sample store, with the mission overlay above them. Shown full screen over the app.
//

import SwiftData
import SwiftUI

struct WelcomeTourView: View {
    @State private var session: TourSession
    @State private var receiptInbox = ReceiptInbox()
    @State private var receiptReadAhead = ReceiptReadAhead()

    init(launch: TourLaunch, store: TourStore, onEnd: @escaping () -> Void) {
        _session = State(initialValue: TourSession(launch: launch, store: store, onEnd: onEnd))
    }

    var body: some View {
        @Bindable var session = session
        ZStack {
            TourStage(tab: $session.tab)
                .modelContainer(session.sample.container)
                .environment(receiptInbox)
                .environment(receiptReadAhead)
                .tourLayer(.root)
                .accessibilityHidden(session.scene != .playing)

            switch session.scene {
            case .opening:
                TourOpeningView(session: session)
                    .transition(.opacity)
            case .chapterCard(let chapter):
                TourChapterCard(session: session, chapter: chapter)
                    .transition(.opacity)
            case .closing:
                TourClosingView(session: session)
                    .transition(.opacity)
            case .playing:
                EmptyView()
            }
        }
        .environment(\.tour, session)
        .animation(.easeInOut(duration: 0.3), value: session.scene)
        .opacity(session.isLeaving ? 0 : 1)
        .animation(.easeInOut(duration: 0.3), value: session.isLeaving)
        .background(Theme.bg)
    }
}

struct TourStage: View {
    @Binding var tab: TourTab

    var body: some View {
        TabView(selection: $tab) {
            Tab(AppLocalization.string(.expenses), systemImage: "list.bullet", value: TourTab.expenses) {
                ExpensesView()
            }
            Tab(AppLocalization.string(.insights), systemImage: "chart.pie", value: TourTab.insights) {
                InsightsView()
            }
            Tab(AppLocalization.string(.manage), systemImage: "folder", value: TourTab.manage) {
                ManageView()
            }
        }
        .tint(Theme.accent)
    }
}
