//
//  TourTargetRegistry.swift
//  ExpenseKu
//
//  Where each tour target sits on screen. Real views report through `tourTarget` only while
//  the tour hands them a session, so the app itself measures nothing. Frames are global:
//  a target can live in the editor sheet as well as under the tab bar.
//
//  Geometry reports rather than anchor preferences, for the reason the Plan guide found:
//  a ViewThatFits drops its children's preferences.
//

import SwiftData
import SwiftUI

nonisolated struct TourTargetFrame: Equatable, Sendable {
    let rect: CGRect
    let radius: CGFloat
}

/// A page or lens switch keeps the outgoing view reporting while it slides away, so every
/// reporter is kept and the newest one still on screen wins.
@MainActor
@Observable
final class TourTargetRegistry {
    private(set) var frames: [TourTarget: TourTargetFrame] = [:]
    @ObservationIgnored private var reports: [TourTarget: [(owner: UUID, frame: TourTargetFrame)]] = [:]

    func report(_ target: TourTarget, _ frame: TourTargetFrame, from owner: UUID) {
        var list = reports[target] ?? []
        if let index = list.firstIndex(where: { $0.owner == owner }) {
            list[index].frame = frame
        } else {
            list.append((owner, frame))
        }
        reports[target] = list
        publish(target)
    }

    func withdraw(_ target: TourTarget, from owner: UUID) {
        reports[target]?.removeAll { $0.owner == owner }
        publish(target)
    }

    private func publish(_ target: TourTarget) {
        let newest = reports[target]?.last?.frame
        if frames[target] != newest { frames[target] = newest }
    }
}

private struct TourTargetReport: ViewModifier {
    let targets: [TourTarget]
    let radius: CGFloat
    @Environment(\.tour) private var tour
    @State private var owner = UUID()

    func body(content: Content) -> some View {
        if let tour, !targets.isEmpty {
            content
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rect in
                    for target in targets {
                        tour.targets.report(target, TourTargetFrame(rect: rect, radius: radius), from: owner)
                    }
                }
                .onDisappear {
                    for target in targets { tour.targets.withdraw(target, from: owner) }
                }
        } else {
            content
        }
    }
}

extension View {
    func tourTarget(_ target: TourTarget?, radius: CGFloat = Metric.rowRadius) -> some View {
        modifier(TourTargetReport(targets: target.map { [$0] } ?? [], radius: radius))
    }

    func tourLanding(_ id: PersistentIdentifier) -> some View {
        modifier(TourLandingReport(id: id))
    }
}

private struct TourLandingReport: ViewModifier {
    let id: PersistentIdentifier
    @Environment(\.tour) private var tour

    func body(content: Content) -> some View {
        content.modifier(TourTargetReport(targets: targets, radius: Metric.rowRadius))
    }

    private var targets: [TourTarget] {
        guard let tour else { return [] }
        var targets: [TourTarget] = []
        if tour.landedExpenseID == id { targets.append(.landedRow) }
        if tour.recordedExpenseID == id { targets.append(.recordedRow) }
        return targets
    }
}
