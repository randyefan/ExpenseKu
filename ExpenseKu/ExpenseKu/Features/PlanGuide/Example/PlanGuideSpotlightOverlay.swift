//
//  PlanGuideSpotlightOverlay.swift
//  ExpenseKu
//
//  Dims the example around the lit part and rings it (plan-guide-visual.md §4.3,
//  decision 22). It is an overlay, never a change to the parts themselves, so moving
//  between spotlights cannot shift the layout. The canvas colour at 70 % over the example
//  reads as the rest of it at 30 %.
//
//  It also reports where the lit part sits in the lesson's scroll content, so a lesson
//  at a large text size can bring it into view (§4.6).
//

import SwiftUI

struct PlanGuideSpotlightOverlay: View {
    let target: PlanGuideTarget
    let registry: PlanGuideTargetRegistry
    let onLocate: (CGRect) -> Void

    static let ringOutset: CGFloat = 4
    nonisolated static let contentSpace = "planGuideLessonContent"

    var body: some View {
        GeometryReader { proxy in
            if let frame = registry.frames[target] {
                let hole = frame.rect.insetBy(dx: -Self.ringOutset, dy: -Self.ringOutset)
                let radius = frame.radius + Self.ringOutset
                let shape = PlanGuideSpotlightShape(hole: hole, radius: radius,
                                                    companion: target == .openMenu ? nil : registry.frames[.openMenu]?.rect)
                ZStack(alignment: .topLeading) {
                    shape
                        .fill(Theme.bg.opacity(0.7), style: FillStyle(eoFill: true))
                    RoundedRectangle(cornerRadius: shape.cornerRadius)
                        .stroke(Theme.accent, lineWidth: 2)
                        .frame(width: hole.width, height: hole.height)
                        .offset(x: hole.minX, y: hole.minY)
                }
                .onChange(of: hole.offsetBy(dx: proxy.frame(in: .named(Self.contentSpace)).minX,
                                            dy: proxy.frame(in: .named(Self.contentSpace)).minY),
                          initial: true) { _, located in
                    onLocate(located)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
