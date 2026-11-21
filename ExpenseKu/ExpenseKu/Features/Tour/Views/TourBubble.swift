//
//  TourBubble.swift
//  ExpenseKu
//
//  The wallet's speech bubble (welcome-tour.md §4.3, decision 28): eyebrow, line, and a
//  footer with the four chapter segments and Skip, or Next on a spotlight. Its tail points
//  at the target.
//

import SwiftUI

struct TourBubble: View {
    let eyebrow: String
    let line: String
    let fills: [Double]
    var nextTitle: String?
    var tail: TourBubbleTail?
    let onSkip: () -> Void
    var onNext: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.dsCaption).bold()
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(Theme.tourBubbleMuted)
            Text(line)
                .font(.dsBody).bold()
                .foregroundStyle(Theme.tourBubbleText)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
            HStack(spacing: 12) {
                TourProgressSegments(fills: fills)
                if let nextTitle {
                    Button(nextTitle, action: onNext)
                        .buttonStyle(.tour(.primary, fillsWidth: false, height: 44))
                } else {
                    Button(AppLocalization.string(.tourSkip), action: onSkip)
                        .buttonStyle(.tour(.bubblePlain, fillsWidth: false, height: 44))
                        .padding(.trailing, -12)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, nextTitle == nil ? 2 : 10)
        .background {
            TourBubbleShape(tail: tail)
                .fill(Theme.tourBubble)
                .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        }
        .animation(.easeInOut(duration: 0.2), value: line)
        .accessibilityElement(children: .contain)
    }
}

nonisolated struct TourBubbleTail: Equatable, Sendable {
    enum Edge: Equatable, Sendable { case top, bottom }
    let edge: Edge
    let x: CGFloat
}

nonisolated struct TourBubbleShape: Shape {
    var tail: TourBubbleTail?
    var radius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: radius)
        guard let tail else { return path }
        let x = min(max(tail.x, rect.minX + radius + 8), rect.maxX - radius - 8)
        let half: CGFloat = 9
        var triangle = Path()
        switch tail.edge {
        case .top:
            triangle.move(to: CGPoint(x: x - half, y: rect.minY + 1))
            triangle.addLine(to: CGPoint(x: x, y: rect.minY - 9))
            triangle.addLine(to: CGPoint(x: x + half, y: rect.minY + 1))
        case .bottom:
            triangle.move(to: CGPoint(x: x - half, y: rect.maxY - 1))
            triangle.addLine(to: CGPoint(x: x, y: rect.maxY + 9))
            triangle.addLine(to: CGPoint(x: x + half, y: rect.maxY - 1))
        }
        triangle.closeSubpath()
        path.addPath(triangle)
        return path
    }
}
