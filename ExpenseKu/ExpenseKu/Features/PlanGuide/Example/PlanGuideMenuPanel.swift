//
//  PlanGuideMenuPanel.swift
//  ExpenseKu
//
//  A Plan menu drawn open (plan-guide-visual.md §4.5, decision 31). A SwiftUI Menu cannot
//  be opened from code, so the guide draws its items as the system lays them out.
//

import SwiftUI

struct PlanGuideMenuPanel: View {
    struct Item: Identifiable {
        let title: String
        let systemImage: String?
        var isChecked = false
        var isDestructive = false
        var target: PlanGuideTarget?

        var id: String { title }
    }

    let items: [Item]
    var showsChecks = false
    var isLit = false

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.enumerated(), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
                row(item)
            }
        }
        .background(Theme.surface, in: .rect(cornerRadius: Metric.rowRadius))
        .fixedSize()
        .modifier(PlanGuideLitMenu(isLit: isLit))
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
    }

    @ViewBuilder
    private func row(_ item: Item) -> some View {
        let label = HStack(spacing: 10) {
            if showsChecks {
                Image(systemName: "checkmark")
                    .font(.dsCaption.weight(.semibold))
                    .opacity(item.isChecked ? 1 : 0)
            }
            Text(item.title)
                .font(.dsBody)
            Spacer(minLength: 24)
            if let systemImage = item.systemImage {
                Image(systemName: systemImage)
                    .font(.dsBody)
            }
        }
        .foregroundStyle(item.isDestructive ? Theme.negative : Theme.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minWidth: 220)

        if let target = item.target {
            label.planGuideTarget(target)
        } else {
            label
        }
    }
}

private struct PlanGuideLitMenu: ViewModifier {
    let isLit: Bool

    func body(content: Content) -> some View {
        if isLit {
            content.planGuideTarget(.openMenu)
        } else {
            content
        }
    }
}
