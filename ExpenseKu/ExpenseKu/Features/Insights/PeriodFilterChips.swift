//
//  PeriodFilterChips.swift
//  ExpenseKu
//
//  The horizontal row of period presets above the Insights charts. The active chip is
//  filled coral — the reserved "selected state" use — and carries the `.isSelected`
//  trait so the selection is not conveyed by colour alone.
//
//  The chip's padding and capsule stay *inside* the button's label: applied outside,
//  they would grow the chip visually while leaving only the text tappable.
//

import SwiftUI

struct PeriodFilterChips: View {
    @Binding var selection: DateRangeFilter

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(DateRangeFilter.allCases) { filter in
                    let isSelected = selection == filter
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.label)
                            .font(.dsSubhead).fontWeight(.semibold)
                            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(isSelected ? Theme.accent : Theme.card)
                                    .overlay(Capsule().stroke(Theme.hairline, lineWidth: isSelected ? 0 : 1))
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
    }
}
