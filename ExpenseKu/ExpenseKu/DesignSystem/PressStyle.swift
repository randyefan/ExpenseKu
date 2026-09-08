//
//  PressStyle.swift
//  ExpenseKu — DesignSystem
//
//  Press feedback, per the motion doctrine: cards and standalone controls take a
//  small scale, list rows take a background wash instead (scaling a row inside a
//  list drags its neighbours' separators with it).
//

import SwiftUI

/// A card or control that dips slightly under the finger.
struct PressableCardStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .motion(Motion.press, value: configuration.isPressed)
    }
}

/// A row that washes with the accent instead of moving.
struct PressableRowStyle: ButtonStyle {
    var cornerRadius: CGFloat = Metric.rowRadius

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.accent.opacity(configuration.isPressed ? 0.10 : 0))
            }
            .motion(Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableCardStyle {
    static var pressableCard: PressableCardStyle { PressableCardStyle() }
}

extension ButtonStyle where Self == PressableRowStyle {
    static var pressableRow: PressableRowStyle { PressableRowStyle() }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        Button { } label: {
            Text("Card").frame(maxWidth: .infinity).cardStyle()
        }
        .buttonStyle(.pressableCard)

        Button { } label: {
            Text("Row").frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .buttonStyle(.pressableRow)
    }
    .padding()
    .warmBackground()
}
