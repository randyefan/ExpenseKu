//
//  PeriodFilterChips.swift
//  ExpenseKu
//
//  The horizontal row of period presets above the Insights charts. The active chip is
//  filled amber — the reserved "selected state" use — and carries the `.isSelected`
//  trait so the selection is not conveyed by colour alone.
//
//  The chip's padding and capsule stay *inside* the button's label: applied outside,
//  they would grow the chip visually while leaving only the text tappable.
//
//  The fill is one shared capsule moved with matchedGeometryEffect, so changing
//  preset slides the selection along the rail rather than blinking it across.
//

import SwiftUI

struct PeriodFilterChips: View {
    @Binding var selection: DateRangeFilter

    @Namespace private var chip
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ChipRail {
                ForEach(DateRangeFilter.allCases) { filter in
                    chipButton(filter)
                        .id(filter)
                }
            }
            .onAppear { proxy.scrollTo(selection, anchor: .center) }
            .onChange(of: selection) { _, newValue in
                withAnimation(reduceMotion ? Motion.reduced : Motion.snap) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chipButton(_ filter: DateRangeFilter) -> some View {
        let isSelected = selection == filter
        return Button {
            withAnimation(reduceMotion ? Motion.reduced : Motion.snap) {
                selection = filter
            }
        } label: {
            Text(filter.label)
                .font(.dsSubhead).fontWeight(.semibold)
                .foregroundStyle(isSelected ? Theme.onAccent : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Theme.accent)
                            .matchedGeometryEffect(id: "period", in: chip)
                    } else {
                        Capsule()
                            .fill(Theme.card)
                            .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.pressableCard)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
