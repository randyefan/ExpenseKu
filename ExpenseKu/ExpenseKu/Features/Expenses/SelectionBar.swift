//
//  SelectionBar.swift
//  ExpenseKu
//
//  Select mode's bottom bar (frame Q7), standing where the tab bar was: how many rows
//  are checked, and the one thing to do with them (envelope-assignment.md §4.6).
//

import SwiftUI

struct SelectionBar: View {
    let count: Int
    let onMove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(count) selected")
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
            Spacer(minLength: 8)
            Button("Move to envelope…", systemImage: "tray", action: onMove)
                .font(.dsBody.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Theme.plan.opacity(count == 0 ? 0.4 : 1), in: .capsule)
                .buttonStyle(.plain)
                .disabled(count == 0)
        }
        .padding(.leading, 22)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, Metric.screenPadding)
    }
}
