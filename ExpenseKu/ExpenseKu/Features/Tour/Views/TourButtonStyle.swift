//
//  TourButtonStyle.swift
//  ExpenseKu
//

import SwiftUI

struct TourButtonStyle: ButtonStyle {
    enum Kind { case primary, outlined, bubbleOutlined, plain, bubblePlain }

    var kind: Kind
    var fillsWidth = true
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsBody).bold()
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: height)
            .background {
                switch kind {
                case .primary: Capsule().fill(Theme.accent)
                case .outlined: Capsule().stroke(Theme.hairline, lineWidth: 1.5)
                case .bubbleOutlined: Capsule().stroke(Theme.tourBubbleText.opacity(0.3), lineWidth: 1.5)
                case .plain, .bubblePlain: Color.clear
                }
            }
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }

    private var foreground: Color {
        switch kind {
        case .primary: Theme.onAccent
        case .outlined: Theme.text
        case .bubbleOutlined: Theme.tourBubbleText
        case .plain: Theme.textSecondary
        case .bubblePlain: Theme.tourBubbleMuted
        }
    }
}

extension ButtonStyle where Self == TourButtonStyle {
    static func tour(_ kind: TourButtonStyle.Kind, fillsWidth: Bool = true, height: CGFloat = 52) -> TourButtonStyle {
        TourButtonStyle(kind: kind, fillsWidth: fillsWidth, height: height)
    }
}
