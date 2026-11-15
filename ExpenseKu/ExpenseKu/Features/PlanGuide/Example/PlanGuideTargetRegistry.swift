//
//  PlanGuideTargetRegistry.swift
//  ExpenseKu
//
//  Where each spotlightable part of a guide example sits (plan-guide-visual.md §4.3). The
//  Plan views report their parts through `planGuideTarget` only when a guide example hands
//  them a registry, so the real Plan lens measures nothing.
//
//  Geometry reports rather than anchor preferences: the Fixed row's chip line is a
//  ViewThatFits, which drops its children's preferences.
//

import SwiftUI

struct PlanGuideTargetFrame: Equatable {
    let rect: CGRect
    let radius: CGFloat
}

@MainActor
@Observable
final class PlanGuideTargetRegistry {
    nonisolated static let space = "planGuideExample"

    private(set) var frames: [PlanGuideTarget: PlanGuideTargetFrame] = [:]
    @ObservationIgnored private var owners: [PlanGuideTarget: UUID] = [:]

    func report(_ target: PlanGuideTarget, _ frame: PlanGuideTargetFrame, from owner: UUID) {
        owners[target] = owner
        if frames[target] != frame { frames[target] = frame }
    }

    func withdraw(_ target: PlanGuideTarget, from owner: UUID) {
        guard owners[target] == owner else { return }
        owners[target] = nil
        frames[target] = nil
    }
}

extension EnvironmentValues {
    @Entry var planGuideTargets: PlanGuideTargetRegistry?
}

private struct PlanGuideTargetReport: ViewModifier {
    let target: PlanGuideTarget
    let radius: CGFloat
    @Environment(\.planGuideTargets) private var registry
    @State private var owner = UUID()

    func body(content: Content) -> some View {
        if let registry {
            content
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(PlanGuideTargetRegistry.space)) } action: {
                    registry.report(target, PlanGuideTargetFrame(rect: $0, radius: radius), from: owner)
                }
                .onDisappear { registry.withdraw(target, from: owner) }
        } else {
            content
        }
    }
}

extension View {
    func planGuideTarget(_ target: PlanGuideTarget, radius: CGFloat = Metric.rowRadius) -> some View {
        modifier(PlanGuideTargetReport(target: target, radius: radius))
    }
}
