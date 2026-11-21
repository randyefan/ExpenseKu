//
//  TourSession.swift
//  ExpenseKu
//
//  One run of the tour (welcome-tour.md §4): where it is in the script, the sample store
//  the real screens are drawn from, and what the wallet is doing. The screens report events
//  and the session decides; it never reaches into a screen, it only issues a command the
//  screen carries out (TourCommand).
//
//  The sample's payday 25 is lent to `Payday.current` for the session's life, because the
//  screens read the payday straight from there; the user's own payday is never written.
//

import SwiftData
import SwiftUI

nonisolated enum TourLayer: Hashable, Sendable {
    case root
    case editor
}

nonisolated struct TourTouch: Equatable, Sendable {
    let point: CGPoint
    let id: Int
}

@MainActor
@Observable
final class TourSession {
    enum Scene: Equatable {
        case opening
        case playing
        case chapterCard(TourChapter)
        case closing
    }

    static let celebration: Duration = .milliseconds(900)
    static let lastCelebration: Duration = .milliseconds(1800)
    static let moment: Duration = .milliseconds(2400)
    static let confusion: Duration = .milliseconds(1300)

    private(set) var scene: Scene
    private(set) var position: TourPosition
    private(set) var sample: TourSample
    private(set) var isNudged = false
    private(set) var isCelebrating = false
    private(set) var touch: TourTouch?
    private(set) var completions = 0
    private(set) var hops = 0
    private(set) var command: TourCommandRequest?
    private(set) var editorIsOpen = false
    private(set) var landedExpenseID: PersistentIdentifier?
    private(set) var isLeaving = false
    var isConfirmingSkip = false
    var tab: TourTab = .expenses {
        didSet { if tab != oldValue { note(.tab(tab)) } }
    }

    let targets = TourTargetRegistry()
    let isReplay: Bool

    @ObservationIgnored private let store: TourStore
    @ObservationIgnored private let onEnd: () -> Void
    @ObservationIgnored private var script: TourScript
    @ObservationIgnored private var pending: Task<Void, Never>?
    @ObservationIgnored private var confusionTask: Task<Void, Never>?
    @ObservationIgnored private var commandCount = 0

    init(launch: TourLaunch, store: TourStore, onEnd: @escaping () -> Void) {
        Payday.sampleOverride = TourSample.payday
        self.store = store
        self.onEnd = onEnd
        isReplay = launch.isReplay
        let sample: TourSample
        switch launch.entry {
        case .opening:
            scene = .opening
            position = .start(of: .record)
            sample = TourSample(startingAt: .record)
        case .chapter(let chapter):
            scene = .playing
            position = .start(of: chapter)
            sample = TourSample(startingAt: chapter)
        }
        self.sample = sample
        script = TourScript(lastCycleName: sample.lastCycleName)
        if scene == .playing { beginChapter(position.chapter) }
    }

    var beat: TourBeat? { scene == .playing ? script.beat(at: position) : nil }

    var line: TourLine? {
        guard let beat else { return nil }
        return isNudged ? beat.nudge ?? beat.line : beat.line
    }

    var pose: WalletPose {
        if touch != nil || isConfirmingSkip { return .confused }
        if isCelebrating { return .happy }
        return beat?.pose ?? .talking
    }

    var activeLayer: TourLayer { editorIsOpen ? .editor : .root }

    /// Mission 1.5 asks for Jago, which the editor would already pick as the last Account
    /// logged by hand; until then the tour's editor opens with no Account.
    var leavesAccountEmpty: Bool {
        scene == .playing && position.chapter == .record && position.mission < 5
    }

    var recordedExpenseID: PersistentIdentifier? { sample.recordedExpense?.persistentModelID }

    var doneChapters: Set<TourChapter> { store.progress.done }

    func fill(of chapter: TourChapter) -> Double {
        script.fill(of: chapter, at: scene == .playing ? position : nil, done: doneChapters)
    }

    // MARK: - Reports from the screens

    func note(_ event: TourEvent) {
        switch event {
        case .editorOpened: editorIsOpen = true
        case .editorClosed: editorIsOpen = false
        default: break
        }
        guard scene == .playing, !isCelebrating, !isConfirmingSkip,
              let goal = beat?.goal, goal.isMet(by: event) else { return }
        complete()
    }

    func land(_ id: PersistentIdentifier) {
        landedExpenseID = id
        if position.chapter == .record, position.mission == 5,
           let expense = sample.container.mainContext.model(for: id) as? Expense {
            sample.adopt(recorded: expense)
        }
    }

    func next() {
        guard case .spotlight = beat?.kind, !isCelebrating else { return }
        advance()
    }

    func wrongTouch(at point: CGPoint) {
        guard scene == .playing, !isCelebrating, let beat else { return }
        switch beat.kind {
        case .watch, .moment: return
        case .act, .spotlight: break
        }
        isNudged = true
        touch = TourTouch(point: point, id: (touch?.id ?? 0) + 1)
        confusionTask?.cancel()
        confusionTask = Task { [weak self] in
            try? await Task.sleep(for: Self.confusion)
            guard !Task.isCancelled else { return }
            self?.touch = nil
        }
    }

    // MARK: - Scenes

    func start() {
        guard scene == .opening else { return }
        scene = .playing
        position = .start(of: .record)
        beginChapter(.record)
    }

    func continueFromCard() {
        guard case .chapterCard(let chapter) = scene, let next = chapter.next else { return }
        position = .start(of: next)
        scene = .playing
        beginChapter(next)
    }

    func skip() {
        if scene == .opening {
            leave(with: TourAutoOpen.outcome(afterSkipping: store.outcome, isReplay: isReplay))
        } else {
            isConfirmingSkip = true
        }
    }

    func keepGoing() {
        isConfirmingSkip = false
    }

    func confirmSkip() {
        isConfirmingSkip = false
        leave(with: TourAutoOpen.outcome(afterSkipping: store.outcome, isReplay: isReplay))
    }

    func finish() {
        guard scene == .closing else { return }
        leave(with: .finished)
    }

    // MARK: - Moving through the script

    private func beginChapter(_ chapter: TourChapter) {
        store.record(store.progress.starting(chapter))
        isNudged = false
        begin()
    }

    private func begin() {
        guard let beat else { return }
        hops += 1
        if let command = beat.command { issue(command) }
        if case .moment = beat.kind {
            schedule(after: Self.moment) { $0.advance() }
        }
    }

    private func complete() {
        completions += 1
        advance()
    }

    private func advance() {
        let finished = beat
        switch script.step(after: position) {
        case .beat(let next):
            move(to: next)
        case .missionDone(let next):
            if case .moment = finished?.kind {
                move(to: next)
            } else {
                celebrate { $0.move(to: next) }
            }
        case .chapterDone:
            if case .moment = finished?.kind {
                endChapter()
            } else {
                celebrate(for: Self.lastCelebration) { $0.endChapter() }
            }
        }
    }

    private func move(to next: TourPosition) {
        position = next
        isNudged = false
        touch = nil
        begin()
    }

    private func celebrate(for duration: Duration = celebration, then action: @escaping (TourSession) -> Void) {
        isCelebrating = true
        schedule(after: duration) { session in
            session.isCelebrating = false
            action(session)
        }
    }

    private func endChapter() {
        let chapter = position.chapter
        store.record(store.progress.finishing(chapter))
        scene = chapter == .insights ? .closing : .chapterCard(chapter)
    }

    private func issue(_ command: TourCommand) {
        commandCount += 1
        self.command = TourCommandRequest(id: commandCount, command: command)
    }

    private func schedule(after delay: Duration, _ action: @escaping (TourSession) -> Void) {
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            action(self)
        }
    }

    private func leave(with outcome: TourOutcome?) {
        pending?.cancel()
        confusionTask?.cancel()
        store.record(outcome)
        store.record(store.progress.leaving())
        isLeaving = true
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            Payday.sampleOverride = nil
            self?.onEnd()
        }
    }
}
