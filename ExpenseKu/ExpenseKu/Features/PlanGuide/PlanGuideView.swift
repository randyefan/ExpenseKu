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
    @Environment(\.dismiss) private var dismiss

    init(entry: PlanGuideEntry, store: PlanGuideStore) {
        self.store = store
        var session = PlanGuideSession(entry: entry, progress: store.progress)
        #if DEBUG
        if let target = DebugLaunch.planGuide?.split(separator: ":"), target.count == 2,
           let material = PlanGuideMaterial(rawValue: String(target[0])), let step = Int(target[1]) {
            session.open(material)
            while case .lesson(_, let shown) = session.route, shown < step { session.next() }
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
                    finishTitle: AppLocalization.string(material == .introduction ? .guideExploreTopics : .guideFinishTopic),
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
