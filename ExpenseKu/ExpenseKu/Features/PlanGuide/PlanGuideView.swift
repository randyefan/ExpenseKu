//
//  PlanGuideView.swift
//  ExpenseKu
//
//  The Plan guide, presented full-screen over Plan (plan-guide.md §4.5, decision 4). It
//  owns one visit's route and hands every progress change to the store as it happens,
//  so a Close, a lens rebuild underneath or a relaunch never loses the step on screen.
//

import SwiftUI

struct PlanGuideView: View {
    let store: PlanGuideStore
    @State private var session: PlanGuideSession
    @State private var samples = PlanGuideSampleCache()
    @Environment(\.dismiss) private var dismiss

    init(entry: PlanGuideEntry, store: PlanGuideStore) {
        self.store = store
        var session = PlanGuideSession(entry: entry, progress: store.progress)
        #if DEBUG
        if let target = DebugLaunch.planGuide?.split(separator: ":"), target.count >= 2,
           let material = PlanGuideMaterial(rawValue: String(target[0])), let step = Int(target[1]) {
            let spotlight = target.count > 2 ? Int(target[2]) ?? 1 : 1
            session.open(material)
            func isPast() -> Bool {
                guard case .lesson(_, let shown) = session.route else { return false }
                return shown > step || (shown == step && session.spotlight > spotlight)
            }
            func isBefore() -> Bool {
                guard case .lesson(_, let shown) = session.route else { return false }
                return shown < step || (shown == step && session.spotlight < spotlight)
            }
            while isPast(), !session.isAtStart { session.back() }
            while isBefore(), !session.isAtEnd { session.next() }
        }
        #endif
        _session = State(initialValue: session)
    }

    var body: some View {
        Group {
            switch session.route {
            case .index:
                PlanGuideIndexView(
                    progress: session.progress,
                    onOpen: { material in withAnimation(Motion.snap) { session.open(material) } },
                    onClose: { dismiss() }
                )
            case .lesson(let material, let step):
                PlanGuideLessonView(
                    title: PlanGuideContent.title(of: material),
                    step: step,
                    stepCount: material.stepCount,
                    lesson: PlanGuideContent.lessons(of: material)[step - 1],
                    spotlight: session.spotlight,
                    isAtStart: session.isAtStart,
                    isAtEnd: session.isAtEnd,
                    finishTitle: AppLocalization.string(material == .introduction ? .guideExploreTopics : .guideFinishTopic),
                    cache: samples,
                    onClose: { dismiss() },
                    onTopics: { withAnimation(Motion.snap) { session.showTopics() } },
                    onBack: { withAnimation(Motion.snap) { session.back() } },
                    onNext: { withAnimation(Motion.snap) { session.next() } },
                    onFinish: { withAnimation(Motion.snap) { session.finish() } }
                )
                .id(session.route)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: session.progress, initial: true) { _, progress in
            store.save(progress)
        }
    }
}
