//
//  PlanGuideSpotlightShape.swift
//  ExpenseKu
//

import SwiftUI

nonisolated struct PlanGuideSpotlightShape: Shape {
    var hole: CGRect
    var radius: CGFloat
    var companion: CGRect?

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat>> {
        get { .init(.init(hole.minX, hole.minY), .init(.init(hole.width, hole.height), radius)) }
        set {
            hole = CGRect(x: newValue.first.first, y: newValue.first.second,
                          width: newValue.second.first.first, height: newValue.second.first.second)
            radius = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        if let companion, !companion.intersects(hole) {
            path.addRoundedRect(in: companion, cornerSize: CGSize(width: 12, height: 12))
        }
        return path
    }

    var cornerRadius: CGFloat { min(radius, hole.height / 2, hole.width / 2) }
}
