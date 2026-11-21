//
//  TourPlacement.swift
//  ExpenseKu
//
//  Where the wallet and its bubble float (welcome-tour.md §4.3): beside the target, never
//  over it, with the wallet on the side away from it. Pointing faces right, so a target on
//  the left mirrors it.
//

import CoreGraphics

nonisolated struct TourPlacement: Equatable, Sendable {
    enum Side: Equatable, Sendable { case above, below }

    let origin: CGPoint
    let side: Side
    let walletLeading: Bool
    let tailX: CGFloat?

    var mirrored: Bool { !walletLeading }

    static let gap: CGFloat = 14
    static let tailInset: CGFloat = 28

    /// The tail turns to `pointer` when the bubble points past the lit target, as 3.4 points
    /// at the Plan options button where the Plan guide lives.
    static func place(target: CGRect?, pointer: CGRect? = nil, unit: CGSize, in bounds: CGRect) -> TourPlacement {
        guard let target, !target.isEmpty else {
            return TourPlacement(
                origin: CGPoint(x: bounds.midX - unit.width / 2, y: bounds.maxY - unit.height - 24),
                side: .above, walletLeading: true, tailX: nil
            )
        }

        let roomAbove = target.minY - bounds.minY
        let roomBelow = bounds.maxY - target.maxY
        let needed = unit.height + gap
        let side: Side
        if target.midY < bounds.midY {
            side = roomBelow >= needed || roomBelow >= roomAbove ? .below : .above
        } else {
            side = roomAbove >= needed || roomAbove >= roomBelow ? .above : .below
        }

        let rawY = side == .below ? target.maxY + gap : target.minY - gap - unit.height
        let y = min(max(rawY, bounds.minY), bounds.maxY - unit.height)
        let x = min(max(target.midX - unit.width / 2, bounds.minX), bounds.maxX - unit.width)
        let walletLeading = target.midX >= bounds.midX
        let tail = min(max((pointer ?? target).midX - x, tailInset), unit.width - tailInset)

        return TourPlacement(origin: CGPoint(x: x, y: y), side: side, walletLeading: walletLeading, tailX: tail)
    }
}
