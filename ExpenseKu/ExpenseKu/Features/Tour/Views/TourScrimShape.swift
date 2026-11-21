//
//  TourScrimShape.swift
//  ExpenseKu
//

import SwiftUI

nonisolated struct TourHole: Equatable, Sendable {
    let rect: CGRect
    let radius: CGFloat

    static let outset: CGFloat = 5

    init(_ frame: TourTargetFrame) {
        rect = frame.rect.insetBy(dx: -Self.outset, dy: -Self.outset)
        radius = min(frame.radius + Self.outset, rect.height / 2, rect.width / 2)
    }
}

nonisolated struct TourScrimShape: Shape {
    var holes: [TourHole]

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        for hole in holes {
            path.addRoundedRect(in: hole.rect, cornerSize: CGSize(width: hole.radius, height: hole.radius))
        }
        return path
    }
}
