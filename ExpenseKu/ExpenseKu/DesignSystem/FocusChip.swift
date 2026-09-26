//
//  FocusChip.swift
//  ExpenseKu — DesignSystem
//
//  An active filter the owner can see and clear in one tap: a washed capsule naming
//  what the list is narrowed to, with its own ✕. Drawn for Flow K's Insights focus and
//  first used by the Plan lens's Funded filter (frame L6).
//
//  The ✕ is its own Button with a 44pt hit area, larger than the 20pt disc it draws.
//

import SwiftUI

struct FocusChip: View {
    let title: String
    let systemImage: String
    var tint: Color = Theme.accentText
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.dsSubhead).fontWeight(.semibold)
                .foregroundStyle(Theme.text)
                .lineLimit(1)

            Button("Clear filter", systemImage: "xmark", action: onClear)
                .labelStyle(.iconOnly)
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 20, height: 20)
                .background(Theme.textSecondary.opacity(0.18), in: .circle)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
                .padding(-12)
                .buttonStyle(.plain)
        }
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.surface)
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        }
    }
}

#Preview {
    FocusChip(title: "In the account", systemImage: "arrow.down.to.line", onClear: {})
        .padding()
        .background(Theme.bg)
}
