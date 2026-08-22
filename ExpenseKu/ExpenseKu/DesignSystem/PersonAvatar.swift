//
//  PersonAvatar.swift
//  ExpenseKu — DesignSystem
//
//  A companion's initial in a soft circle.
//

import SwiftUI

struct PersonAvatar: View {
    let name: String
    var size: CGFloat = Metric.iconSize
    private var initial: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }
    var body: some View {
        Circle()
            .fill(Theme.textSecondary.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.jakarta(size * 0.38)).fontWeight(.semibold)
                    .foregroundStyle(Theme.text.opacity(0.7))
            )
    }
}

#Preview {
    HStack(spacing: Metric.cardGap) {
        PersonAvatar(name: "Tarisa")
        PersonAvatar(name: "budi", size: 36)
        PersonAvatar(name: "  ", size: 36)
        PersonAvatar(name: "", size: 36)
    }
    .padding()
    .warmBackground()
}
